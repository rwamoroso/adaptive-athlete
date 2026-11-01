-- Security, planner governance, and cursor-based sync introduced in 1.2.
-- The hosted project was checked before this migration: no legacy unscoped
-- rows or invalid cross-workspace invite assignments remained.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function public.ensure_email_user_binding(
  p_user_id uuid,
  p_email text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_email text;
  v_claim_email text;
  v_existing_user_id uuid;
begin
  if auth.uid() is null or p_user_id is distinct from auth.uid() then
    raise exception 'User identity must match the authenticated user'
      using errcode = '42501';
  end if;

  v_email := pg_catalog.lower(pg_catalog.btrim(coalesce(p_email, '')));
  v_claim_email := pg_catalog.lower(
    pg_catalog.btrim(coalesce(auth.jwt()->>'email', ''))
  );
  if v_email = '' or v_claim_email = '' or v_email is distinct from v_claim_email then
    raise exception 'Email must match the authenticated user claim'
      using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_email));

  insert into public.user_email_bindings(email, user_id, updated_at)
  values (v_email, p_user_id, pg_catalog.now())
  on conflict (email)
  do update set updated_at = pg_catalog.now()
  returning user_id into v_existing_user_id;

  if v_existing_user_id is distinct from p_user_id then
    raise exception 'Email is already bound to another user'
      using errcode = '23505';
  end if;
end;
$function$;

notify pgrst, 'reload schema';

-- Validate every requested assignment before creating an invite so an array
-- cannot smuggle a profile from another workspace into the accept flow.
create or replace function public.create_workspace_invite(
  p_workspace_id uuid,
  p_email text,
  p_role text,
  p_display_name text default null,
  p_assigned_profile_ids uuid[] default '{}'::uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_token text;
  v_token_hash text;
  v_expires_at timestamptz;
  v_invite_id uuid;
begin
  if v_user_id is null or not public.is_workspace_owner(p_workspace_id) then
    raise exception 'Only workspace owners can create invites'
      using errcode = '42501';
  end if;
  v_email := pg_catalog.lower(
    pg_catalog.btrim(coalesce(p_email, ''))
  );
  if v_email = '' then
    raise exception 'Invite email is required' using errcode = '22023';
  end if;
  if p_role not in ('coach', 'athlete') then
    raise exception 'Invite role must be coach or athlete' using errcode = '22023';
  end if;
  if exists (
    select 1
    from pg_catalog.unnest(coalesce(p_assigned_profile_ids, '{}'::uuid[])) p(id)
    where not exists (
      select 1 from public.athlete_profiles ap
      where ap.id = p.id and ap.workspace_id = p_workspace_id
    )
  ) then
    raise exception 'Every assigned profile must belong to the invite workspace'
      using errcode = '22023';
  end if;

  update public.workspace_invites
  set status = 'revoked'
  where workspace_id = p_workspace_id
    and pg_catalog.lower(email) = v_email
    and status = 'pending';

  v_token := pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '')
    || pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '');
  v_token_hash := pg_catalog.md5(v_token);
  v_expires_at := pg_catalog.now() + interval '7 days';

  insert into public.workspace_invites(
    workspace_id, email, role, display_name, token_hash, expires_at, status,
    assigned_profile_ids, created_by_user_id
  ) values (
    p_workspace_id, v_email, p_role, p_display_name, v_token_hash,
    v_expires_at, 'pending',
    coalesce(p_assigned_profile_ids, '{}'::uuid[]), v_user_id
  ) returning id into v_invite_id;

  return pg_catalog.jsonb_build_object(
    'invite_id', v_invite_id,
    'workspace_id', p_workspace_id,
    'email', v_email,
    'role', p_role,
    'token', v_token,
    'expires_at', v_expires_at,
    'deep_link', 'adaptiveathlete://join?token=' || v_token
  );
end;
$function$;

revoke all on function public.create_workspace_invite(uuid, text, text, text, uuid[])
  from public, anon;
grant execute on function public.create_workspace_invite(uuid, text, text, text, uuid[])
  to authenticated;

notify pgrst, 'reload schema';

-- Paid planner calls are authorized and reserved atomically before contacting
-- the provider. Only request metadata is retained; prompts and plans are not.
create table public.planner_generation_reservations (
  user_id uuid not null,
  request_id uuid not null,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  athlete_profile_id uuid not null,
  status text not null default 'reserved'
    check (status in ('reserved', 'completed', 'failed')),
  error_code text null check (error_code is null or pg_catalog.length(error_code) <= 80),
  created_at timestamptz not null default pg_catalog.now(),
  completed_at timestamptz null,
  primary key (user_id, request_id),
  foreign key (athlete_profile_id, workspace_id)
    references public.athlete_profiles(id, workspace_id) on delete cascade
);

create index planner_generation_reservations_user_created
  on public.planner_generation_reservations(user_id, created_at desc);
create index planner_generation_reservations_scope_created
  on public.planner_generation_reservations(
    workspace_id, athlete_profile_id, created_at desc
  );

alter table public.planner_generation_reservations enable row level security;
revoke all on public.planner_generation_reservations from public, anon, authenticated;

create or replace function public.reserve_planner_generation(
  p_request_id uuid,
  p_workspace uuid,
  p_profile uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_existing_status text;
  v_hour_count integer;
  v_day_count integer;
  v_retry_seconds integer := 0;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_request_id is null or p_workspace is null or p_profile is null then
    raise exception 'Planner request scope is required' using errcode = '22023';
  end if;
  if not public.can_edit_profile(p_workspace, p_profile)
     or not exists (
       select 1 from public.athlete_profiles ap
       where ap.id = p_profile and ap.workspace_id = p_workspace
     ) then
    raise exception 'Profile edit permission required' using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('planner/' || v_user::text, 0)
  );

  select r.status into v_existing_status
  from public.planner_generation_reservations r
  where r.user_id = v_user and r.request_id = p_request_id;
  if v_existing_status is not null then
    return pg_catalog.jsonb_build_object(
      'allowed', false,
      'idempotent', true,
      'status', v_existing_status,
      'retry_after_seconds', 0
    );
  end if;

  select
    pg_catalog.count(*) filter (
      where r.created_at >= pg_catalog.now() - interval '1 hour'
    ),
    pg_catalog.count(*) filter (
      where r.created_at >= pg_catalog.now() - interval '1 day'
    )
  into v_hour_count, v_day_count
  from public.planner_generation_reservations r
  where r.user_id = v_user
    and r.created_at >= pg_catalog.now() - interval '1 day';

  if v_hour_count >= 5 then
    select greatest(
      1,
      pg_catalog.ceil(extract(epoch from (
        pg_catalog.min(r.created_at) + interval '1 hour' - pg_catalog.now()
      )))::integer
    ) into v_retry_seconds
    from public.planner_generation_reservations r
    where r.user_id = v_user
      and r.created_at >= pg_catalog.now() - interval '1 hour';
  elsif v_day_count >= 20 then
    select greatest(
      1,
      pg_catalog.ceil(extract(epoch from (
        pg_catalog.min(r.created_at) + interval '1 day' - pg_catalog.now()
      )))::integer
    ) into v_retry_seconds
    from public.planner_generation_reservations r
    where r.user_id = v_user
      and r.created_at >= pg_catalog.now() - interval '1 day';
  end if;

  if v_hour_count >= 5 or v_day_count >= 20 then
    return pg_catalog.jsonb_build_object(
      'allowed', false,
      'idempotent', false,
      'status', 'rate_limited',
      'remaining_hour', greatest(0, 5 - v_hour_count),
      'remaining_day', greatest(0, 20 - v_day_count),
      'retry_after_seconds', v_retry_seconds
    );
  end if;

  insert into public.planner_generation_reservations(
    user_id, request_id, workspace_id, athlete_profile_id
  ) values (v_user, p_request_id, p_workspace, p_profile);

  return pg_catalog.jsonb_build_object(
    'allowed', true,
    'idempotent', false,
    'status', 'reserved',
    'remaining_hour', 4 - v_hour_count,
    'remaining_day', 19 - v_day_count,
    'retry_after_seconds', 0
  );
end;
$function$;

create or replace function public.complete_planner_generation(
  p_request_id uuid,
  p_status text,
  p_error_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_updated integer;
  v_error text;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_status not in ('completed', 'failed') then
    raise exception 'Invalid completion status' using errcode = '22023';
  end if;
  v_error := case when p_error_code is null then null else
    pg_catalog.left(
      pg_catalog.regexp_replace(
        pg_catalog.lower(p_error_code), '[^a-z0-9_]+', '_', 'g'
      ),
      80
    )
  end;
  update public.planner_generation_reservations r
  set status = p_status,
      error_code = case when p_status = 'failed' then v_error else null end,
      completed_at = pg_catalog.now()
  where r.user_id = v_user and r.request_id = p_request_id;
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'Planner reservation not found' using errcode = 'P0002';
  end if;
  return pg_catalog.jsonb_build_object('updated', true, 'status', p_status);
end;
$function$;

revoke all on function public.reserve_planner_generation(uuid, uuid, uuid)
  from public, anon;
revoke all on function public.complete_planner_generation(uuid, text, text)
  from public, anon;
grant execute on function public.reserve_planner_generation(uuid, uuid, uuid)
  to authenticated;
grant execute on function public.complete_planner_generation(uuid, text, text)
  to authenticated;

-- A metadata-only journal supports one-request incremental pulls without
-- duplicating workout or health content in another table.
create table public.sync_change_log (
  change_version bigint generated always as identity primary key,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  athlete_profile_id uuid not null,
  table_name text not null,
  row_key text not null,
  operation text not null check (operation in ('upsert', 'delete')),
  changed_at timestamptz not null default pg_catalog.now(),
  foreign key (athlete_profile_id, workspace_id)
    references public.athlete_profiles(id, workspace_id) on delete cascade
);

create index sync_change_log_scope_version
  on public.sync_change_log(
    workspace_id, athlete_profile_id, change_version
  );
create index sync_change_log_changed_at
  on public.sync_change_log(changed_at);

alter table public.sync_change_log enable row level security;
revoke all on public.sync_change_log from public, anon;
grant select on public.sync_change_log to authenticated;
create policy sync_change_log_select_assigned
  on public.sync_change_log
  for select
  to authenticated
  using (public.can_view_profile(workspace_id, athlete_profile_id));

create or replace function private.record_sync_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_row jsonb;
  v_workspace uuid;
  v_profile uuid;
  v_key text;
  v_key_column text;
begin
  v_row := case when tg_op = 'DELETE'
    then pg_catalog.to_jsonb(old)
    else pg_catalog.to_jsonb(new)
  end;
  v_workspace := (v_row->>'workspace_id')::uuid;
  v_profile := (v_row->>'athlete_profile_id')::uuid;
  v_key_column := case when tg_table_name = 'run_session_details'
    then 'run_session_id' else 'id' end;
  v_key := v_row->>v_key_column;

  if v_workspace is null or v_profile is null or v_key is null then
    raise exception 'Synced rows require a workspace, profile, and identity'
      using errcode = '23502';
  end if;

  -- Cascading workspace/profile deletion needs no journal entry.
  if not exists (
    select 1 from public.athlete_profiles ap
    where ap.id = v_profile and ap.workspace_id = v_workspace
  ) then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  insert into public.sync_change_log(
    workspace_id, athlete_profile_id, table_name, row_key, operation
  ) values (
    v_workspace,
    v_profile,
    tg_table_name,
    v_key,
    case when tg_op = 'DELETE' then 'delete' else 'upsert' end
  );
  return case when tg_op = 'DELETE' then old else new end;
end;
$function$;

revoke all on function private.record_sync_change() from public, anon, authenticated;

do $block$
declare
  t text;
begin
  foreach t in array array[
    'workout_days','plan_cycles','plan_days','exercise_substitutions',
    'actual_strength_sets','prescribed_strength_sets','sleep_nights',
    'run_sessions','run_segments','run_session_details','run_override_audit',
    'rule_triggers','ai_audit','plan_prescribed_strength_sets','plan_prescribed_runs',
    'plan_exercise_alternatives','plan_summary_snapshots','plan_import_audit',
    'athlete_planning_profiles','weekly_plan_build_requests',
    'plan_long_range_weeks','plan_long_range_week_performance'
  ] loop
    execute pg_catalog.format(
      'drop trigger if exists sync_change_journal on public.%I', t
    );
    execute pg_catalog.format(
      'create trigger sync_change_journal after insert or update or delete on public.%I for each row execute function private.record_sync_change()',
      t
    );
    execute pg_catalog.format(
      'revoke insert, update, delete on public.%I from authenticated', t
    );
    execute pg_catalog.format(
      'grant select on public.%I to authenticated', t
    );
  end loop;
end;
$block$;

-- Ordinary Data API writes are revoked above. This narrowly scoped function
-- remains the single mutation path; its body validates auth, profile scope,
-- table allowlist, row identity, and the expected cloud snapshot.
alter function public.sync_apply_change(
  text, text, uuid, uuid, jsonb, jsonb, boolean
) security definer;
alter function public.sync_apply_change(
  text, text, uuid, uuid, jsonb, jsonb, boolean
) set search_path = '';
revoke all on function public.sync_apply_change(
  text, text, uuid, uuid, jsonb, jsonb, boolean
) from public, anon;
grant execute on function public.sync_apply_change(
  text, text, uuid, uuid, jsonb, jsonb, boolean
) to authenticated;
revoke insert, update, delete on public.sync_tombstones from authenticated;
grant select on public.sync_tombstones to authenticated;

create or replace function public.sync_change_cursor(
  p_workspace uuid,
  p_profile uuid
)
returns bigint
language plpgsql
stable
security invoker
set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.can_view_profile(p_workspace, p_profile) then
    raise exception 'Profile view permission required' using errcode = '42501';
  end if;
  return coalesce((
    select pg_catalog.max(c.change_version)
    from public.sync_change_log c
    where c.workspace_id = p_workspace
      and c.athlete_profile_id = p_profile
  ), 0);
end;
$function$;

create or replace function public.sync_changes_since(
  p_workspace uuid,
  p_profile uuid,
  p_after bigint,
  p_limit integer default 500
)
returns table (
  change_version bigint,
  table_name text,
  row_key text,
  operation text,
  row_data jsonb,
  changed_at timestamptz
)
language plpgsql
stable
security invoker
set search_path = ''
as $function$
declare
  v_change record;
  v_row jsonb;
  v_key_column text;
begin
  if auth.uid() is null or not public.can_view_profile(p_workspace, p_profile) then
    raise exception 'Profile view permission required' using errcode = '42501';
  end if;
  if p_after < 0 or p_limit < 1 or p_limit > 1000 then
    raise exception 'Invalid sync cursor or page size' using errcode = '22023';
  end if;

  for v_change in
    select c.change_version, c.table_name, c.row_key,
           c.operation, c.changed_at
    from public.sync_change_log c
    where c.workspace_id = p_workspace
      and c.athlete_profile_id = p_profile
      and c.change_version > p_after
    order by c.change_version
    limit p_limit
  loop
    v_row := null;
    if v_change.operation <> 'delete' then
      v_key_column := case when v_change.table_name = 'run_session_details'
        then 'run_session_id' else 'id' end;
      execute pg_catalog.format(
        'select pg_catalog.to_jsonb(t) from public.%I t where t.%I = $1 and t.workspace_id = $2 and t.athlete_profile_id = $3',
        v_change.table_name,
        v_key_column
      ) into v_row using v_change.row_key, p_workspace, p_profile;
    end if;
    change_version := v_change.change_version;
    table_name := v_change.table_name;
    row_key := v_change.row_key;
    operation := case when v_row is null then 'delete' else 'upsert' end;
    row_data := v_row;
    changed_at := v_change.changed_at;
    return next;
  end loop;
end;
$function$;

revoke all on function public.sync_change_cursor(uuid, uuid) from public, anon;
revoke all on function public.sync_changes_since(uuid, uuid, bigint, integer)
  from public, anon;
grant execute on function public.sync_change_cursor(uuid, uuid) to authenticated;
grant execute on function public.sync_changes_since(uuid, uuid, bigint, integer)
  to authenticated;

notify pgrst, 'reload schema';

-- The helpers are still callable by RLS expressions, but anonymous/direct
-- access to all definer functions is removed.
alter function public.current_user_id() set search_path = '';
alter function public.is_workspace_member(uuid) set search_path = '';
alter function public.workspace_role(uuid) set search_path = '';
alter function public.is_workspace_owner(uuid) set search_path = '';
alter function public.can_view_profile(uuid, uuid) set search_path = '';
alter function public.can_edit_profile(uuid, uuid) set search_path = '';
alter function public.bootstrap_workspace_for_current_user() set search_path = '';
alter function public.create_workspace_invite(uuid, text, text, text, uuid[]) set search_path = '';
alter function public.accept_workspace_invite(text) set search_path = '';

revoke all on function public.current_user_id() from public, anon;
revoke all on function public.is_workspace_member(uuid) from public, anon;
revoke all on function public.workspace_role(uuid) from public, anon;
revoke all on function public.is_workspace_owner(uuid) from public, anon;
revoke all on function public.can_view_profile(uuid, uuid) from public, anon;
revoke all on function public.can_edit_profile(uuid, uuid) from public, anon;
revoke all on function public.ensure_email_user_binding(uuid, text) from public, anon, authenticated;
revoke all on function public.bootstrap_workspace_for_current_user() from public, anon;
revoke all on function public.create_workspace_invite(uuid, text, text, text, uuid[]) from public, anon;
revoke all on function public.accept_workspace_invite(text) from public, anon;
revoke all on function public.claim_legacy_rows_into_profile(uuid, uuid) from public, anon, authenticated;
do $block$
begin
  if pg_catalog.to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke all on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end;
$block$;

grant execute on function public.current_user_id() to authenticated;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.workspace_role(uuid) to authenticated;
grant execute on function public.is_workspace_owner(uuid) to authenticated;
grant execute on function public.can_view_profile(uuid, uuid) to authenticated;
grant execute on function public.can_edit_profile(uuid, uuid) to authenticated;
grant execute on function public.bootstrap_workspace_for_current_user() to authenticated;
grant execute on function public.create_workspace_invite(uuid, text, text, text, uuid[]) to authenticated;
grant execute on function public.accept_workspace_invite(text) to authenticated;

-- Profile metadata is health-adjacent. Owners can see their workspace, while
-- all other members can see or edit only profiles explicitly assigned to them.
drop policy if exists athlete_profile_select_member on public.athlete_profiles;
create policy athlete_profile_select_assigned
  on public.athlete_profiles
  for select
  to authenticated
  using (public.can_view_profile(workspace_id, id));

drop policy if exists athlete_profile_insert_owner_or_coach on public.athlete_profiles;
create policy athlete_profile_insert_owner
  on public.athlete_profiles
  for insert
  to authenticated
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists athlete_profile_update_owner_or_coach on public.athlete_profiles;
create policy athlete_profile_update_assigned
  on public.athlete_profiles
  for update
  to authenticated
  using (public.can_edit_profile(workspace_id, id))
  with check (public.can_edit_profile(workspace_id, id));

drop policy if exists profile_assignment_select_member on public.athlete_profile_assignments;
create policy profile_assignment_select_owner_or_self
  on public.athlete_profile_assignments
  for select
  to authenticated
  using (public.is_workspace_owner(workspace_id) or user_id = auth.uid());

-- Existing data is fully scoped, so make that invariant permanent and disable
-- the old first-owner-wins global legacy claim path.
do $block$
declare
  t text;
begin
  foreach t in array array[
    'workout_days','plan_cycles','plan_days','exercise_substitutions',
    'actual_strength_sets','prescribed_strength_sets','sleep_nights',
    'run_sessions','run_segments','run_session_details','run_override_audit',
    'rule_triggers','ai_audit','plan_prescribed_strength_sets','plan_prescribed_runs',
    'plan_exercise_alternatives','plan_summary_snapshots','plan_import_audit',
    'athlete_planning_profiles','weekly_plan_build_requests',
    'plan_long_range_weeks','plan_long_range_week_performance'
  ] loop
    execute pg_catalog.format(
      'alter table public.%I alter column workspace_id set not null', t
    );
    execute pg_catalog.format(
      'alter table public.%I alter column athlete_profile_id set not null', t
    );
  end loop;
end;
$block$;

alter table public.athlete_profile_assignments
  drop constraint if exists athlete_profile_assignments_profile_workspace_fkey;
alter table public.athlete_profile_assignments
  add constraint athlete_profile_assignments_profile_workspace_fkey
  foreign key (athlete_profile_id, workspace_id)
  references public.athlete_profiles(id, workspace_id)
  on delete cascade
  not valid;
alter table public.athlete_profile_assignments
  validate constraint athlete_profile_assignments_profile_workspace_fkey;

create index if not exists idx_profile_assignments_profile_workspace
  on public.athlete_profile_assignments(athlete_profile_id, workspace_id);

-- Bootstrap still creates the first owner/profile, but returns only data the
-- caller owns or is explicitly assigned to. Legacy claiming is permanently off.
create or replace function public.bootstrap_workspace_for_current_user()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_user_email text;
  v_workspace_id uuid;
  v_profile_id uuid;
  v_role text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  v_user_email := pg_catalog.lower(
    coalesce(auth.jwt()->>'email', '')
  );
  if v_user_email = '' then
    raise exception 'Authenticated user does not have an email claim'
      using errcode = '42501';
  end if;
  perform public.ensure_email_user_binding(v_user_id, v_user_email);
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_user_id::text));

  if not exists (
    select 1 from public.workspace_memberships wm
    where wm.user_id = v_user_id and wm.status = 'active'
  ) then
    insert into public.workspaces(name, created_by_user_id)
    values ('My Workspace', v_user_id)
    returning id into v_workspace_id;

    insert into public.workspace_memberships(
      workspace_id, user_id, user_email, role, status, created_by_user_id
    ) values (
      v_workspace_id, v_user_id, v_user_email, 'owner', 'active', v_user_id
    );

    insert into public.athlete_profiles(workspace_id, name, created_by_user_id)
    values (v_workspace_id, 'Default Athlete', v_user_id)
    returning id into v_profile_id;

    insert into public.athlete_profile_assignments(
      workspace_id, athlete_profile_id, user_id, can_view, can_edit,
      created_by_user_id
    ) values (
      v_workspace_id, v_profile_id, v_user_id, true, true, v_user_id
    );
  end if;

  select wm.workspace_id, wm.role
    into v_workspace_id, v_role
  from public.workspace_memberships wm
  where wm.user_id = v_user_id and wm.status = 'active'
  order by
    exists (
      select 1 from public.plan_cycles pc
      join public.athlete_profile_assignments apa
        on apa.workspace_id = pc.workspace_id
       and apa.athlete_profile_id = pc.athlete_profile_id
       and apa.user_id = v_user_id
       and apa.can_view
      where pc.workspace_id = wm.workspace_id
    ) desc,
    exists (
      select 1 from public.workout_days wd
      join public.athlete_profile_assignments apa
        on apa.workspace_id = wd.workspace_id
       and apa.athlete_profile_id = wd.athlete_profile_id
       and apa.user_id = v_user_id
       and apa.can_view
      where wd.workspace_id = wm.workspace_id
    ) desc,
    wm.created_at asc
  limit 1;

  if v_workspace_id is null then
    raise exception 'No active workspace membership found' using errcode = '42501';
  end if;

  select apa.athlete_profile_id into v_profile_id
  from public.athlete_profile_assignments apa
  where apa.workspace_id = v_workspace_id
    and apa.user_id = v_user_id
    and apa.can_view
  order by
    exists (
      select 1 from public.plan_cycles pc
      where pc.workspace_id = apa.workspace_id
        and pc.athlete_profile_id = apa.athlete_profile_id
    ) desc,
    exists (
      select 1 from public.workout_days wd
      where wd.workspace_id = apa.workspace_id
        and wd.athlete_profile_id = apa.athlete_profile_id
    ) desc,
    apa.created_at asc
  limit 1;

  if v_profile_id is null and v_role = 'owner' then
    insert into public.athlete_profiles(workspace_id, name, created_by_user_id)
    values (v_workspace_id, 'Default Athlete', v_user_id)
    returning id into v_profile_id;
    insert into public.athlete_profile_assignments(
      workspace_id, athlete_profile_id, user_id, can_view, can_edit,
      created_by_user_id
    ) values (
      v_workspace_id, v_profile_id, v_user_id, true, true, v_user_id
    );
  elsif v_profile_id is null then
    raise exception 'No athlete profile is assigned to this account'
      using errcode = '42501';
  end if;

  return pg_catalog.jsonb_build_object(
    'active_workspace_id', v_workspace_id,
    'active_profile_id', v_profile_id,
    'active_role', v_role,
    'needs_legacy_claim', false,
    'workspaces', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x)) from (
        select w.id, w.name, w.created_at, w.created_by_user_id
        from public.workspaces w
        join public.workspace_memberships wm on wm.workspace_id = w.id
        where wm.user_id = v_user_id and wm.status = 'active'
      ) x
    ), '[]'::jsonb),
    'memberships', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x)) from (
        select wm.id, wm.workspace_id, wm.user_id, wm.user_email,
               wm.display_name, wm.role, wm.status, wm.created_at,
               wm.created_by_user_id
        from public.workspace_memberships wm
        where wm.workspace_id = v_workspace_id
          and (v_role = 'owner' or wm.user_id = v_user_id)
      ) x
    ), '[]'::jsonb),
    'profiles', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x)) from (
        select ap.id, ap.workspace_id, ap.name, ap.date_of_birth, ap.notes,
               ap.created_at, ap.created_by_user_id
        from public.athlete_profiles ap
        where ap.workspace_id = v_workspace_id
          and (
            v_role = 'owner'
            or exists (
              select 1 from public.athlete_profile_assignments apa
              where apa.workspace_id = ap.workspace_id
                and apa.athlete_profile_id = ap.id
                and apa.user_id = v_user_id
                and apa.can_view
            )
          )
      ) x
    ), '[]'::jsonb),
    'assignments', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x)) from (
        select apa.id, apa.workspace_id, apa.athlete_profile_id, apa.user_id,
               apa.can_view, apa.can_edit, apa.created_at,
               apa.created_by_user_id
        from public.athlete_profile_assignments apa
        where apa.workspace_id = v_workspace_id
          and (v_role = 'owner' or apa.user_id = v_user_id)
      ) x
    ), '[]'::jsonb),
    'invites', case when v_role = 'owner' then coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x)) from (
        select wi.id, wi.workspace_id, wi.email, wi.role, wi.display_name,
               wi.expires_at, wi.status, wi.assigned_profile_ids,
               wi.created_at, wi.created_by_user_id
        from public.workspace_invites wi
        where wi.workspace_id = v_workspace_id and wi.status = 'pending'
        order by wi.created_at desc
      ) x
    ), '[]'::jsonb) else '[]'::jsonb end
  );
end;
$function$;

notify pgrst, 'reload schema';
