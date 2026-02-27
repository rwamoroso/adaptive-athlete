-- Run this in Supabase SQL Editor for the FitnessData project.

create extension if not exists pgcrypto;

-- Workspace / profile metadata
create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  created_by_user_id uuid not null
);

create table if not exists public.workspace_memberships (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null,
  user_email text not null,
  display_name text null,
  role text not null check (role in ('owner', 'coach', 'athlete')),
  status text not null default 'active' check (status in ('active', 'disabled')),
  created_at timestamptz not null default now(),
  created_by_user_id uuid not null,
  unique (workspace_id, user_id)
);

create table if not exists public.athlete_profiles (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  date_of_birth text null,
  notes text null,
  created_at timestamptz not null default now(),
  created_by_user_id uuid not null
);

create table if not exists public.athlete_profile_assignments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  user_id uuid not null,
  can_view boolean not null default true,
  can_edit boolean not null default true,
  created_at timestamptz not null default now(),
  created_by_user_id uuid not null,
  unique (athlete_profile_id, user_id)
);

create table if not exists public.workspace_invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email text not null,
  role text not null check (role in ('coach', 'athlete')),
  display_name text null,
  token_hash text not null,
  expires_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked', 'expired')),
  assigned_profile_ids uuid[] not null default '{}'::uuid[],
  created_at timestamptz not null default now(),
  created_by_user_id uuid not null,
  accepted_by_user_id uuid null,
  accepted_at timestamptz null
);

-- Domain tables
create table if not exists public.workout_days (
  id text primary key,
  workout_date text not null,
  created_at bigint not null,
  notes text null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.actual_strength_sets (
  id text primary key,
  workout_day_id text not null,
  plan_day_id text null,
  performed_at bigint null,
  exercise_canonical text not null,
  set_index integer not null,
  weight double precision null,
  reps integer null,
  rir integer null,
  unit text not null,
  source text not null,
  raw_set_string text null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.prescribed_strength_sets (
  id text primary key,
  workout_day_id text not null,
  exercise_canonical text not null,
  set_index integer not null,
  weight double precision null,
  reps integer null,
  rir integer null,
  unit text not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.sleep_nights (
  id text primary key,
  sleep_date text not null,
  start_time bigint null,
  end_time bigint null,
  total_sleep_min integer null,
  rem_min integer null,
  deep_min integer null,
  light_min integer null,
  awake_min integer null,
  source text not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.run_sessions (
  id text primary key,
  run_key text not null,
  workout_day_id text null,
  plan_day_id text null,
  start_time bigint null,
  end_time bigint null,
  duration_s integer null,
  distance_m double precision null,
  avg_hr double precision null,
  max_hr double precision null,
  treadmill boolean null,
  title text null,
  activity_type text null,
  calories integer null,
  moving_time_s integer null,
  elapsed_time_s integer null,
  source_priority integer not null default 0,
  import_file_name text null,
  raw_metrics_json text null,
  source text not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.run_segments (
  id text primary key,
  run_session_id text not null,
  idx integer not null,
  duration_s integer null,
  distance_m double precision null,
  speed_mps double precision null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.run_session_details (
  run_session_id text primary key,
  favorite boolean null,
  aerobic_te double precision null,
  avg_run_cadence double precision null,
  max_run_cadence double precision null,
  avg_pace_s double precision null,
  best_pace_s double precision null,
  total_ascent double precision null,
  total_descent double precision null,
  avg_stride_length_m double precision null,
  training_stress_score double precision null,
  steps integer null,
  min_temp double precision null,
  max_temp double precision null,
  decompression text null,
  best_lap_time_s double precision null,
  number_of_laps integer null,
  min_elevation double precision null,
  max_elevation double precision null,
  raw_metrics_json text not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.run_override_audit (
  id text primary key,
  run_key text not null,
  workout_day_id text null,
  old_source text not null,
  new_source text not null,
  old_snapshot_json text not null,
  new_snapshot_json text not null,
  reason text not null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.rule_triggers (
  id text primary key,
  trigger_date text not null,
  rule_code text not null,
  triggered boolean not null,
  details_json text not null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.ai_audit (
  id text primary key,
  requested_at bigint not null,
  date_window_start text null,
  date_window_end text null,
  input_snapshot_json text not null,
  response_json text not null,
  schema_valid boolean not null,
  notes text null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_cycles (
  id text primary key,
  cycle_key text not null,
  week_start text not null,
  week_end text not null,
  source text not null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_days (
  id text primary key,
  plan_cycle_id text not null,
  day_number integer not null,
  sheet_name text not null,
  estimated_date text null,
  session_type text null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_prescribed_strength_sets (
  id text primary key,
  plan_day_id text not null,
  exercise_canonical text not null,
  set_index integer not null,
  weight double precision null,
  reps integer null,
  rir integer null,
  unit text not null,
  raw_set_string text null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_prescribed_runs (
  id text primary key,
  plan_day_id text not null,
  day_label text null,
  lift_focus text null,
  run_type text null,
  duration_text text null,
  target_pace text null,
  effort_hr_guardrails text null,
  notes text null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_exercise_alternatives (
  id text primary key,
  plan_day_id text null,
  prescribed_exercise_canonical text not null,
  alternative_exercise_canonical text not null,
  priority integer not null default 0,
  notes text null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.exercise_substitutions (
  id text primary key,
  workout_day_id text not null,
  plan_day_id text null,
  prescribed_exercise_canonical text not null,
  substitute_exercise_canonical text not null,
  reason_code text not null,
  reason_notes text null,
  selected_at bigint not null,
  selected_by text null,
  match_score double precision null,
  match_explanation_json text null,
  warning_acknowledged boolean not null default false,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_summary_snapshots (
  id text primary key,
  plan_cycle_id text not null,
  tab_name text not null,
  snapshot_json text not null,
  created_at bigint not null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

create table if not exists public.plan_import_audit (
  id text primary key,
  imported_at bigint not null,
  file_name text not null,
  success boolean not null,
  details_json text not null,
  conflict_report_path text null,
  workspace_id uuid null,
  athlete_profile_id uuid null
);

-- Backward-compatible alters for existing projects
alter table public.run_sessions add column if not exists run_key text;
alter table public.run_sessions add column if not exists plan_day_id text;
alter table public.run_sessions add column if not exists max_hr double precision;
alter table public.run_sessions add column if not exists title text;
alter table public.run_sessions add column if not exists activity_type text;
alter table public.run_sessions add column if not exists calories integer;
alter table public.run_sessions add column if not exists moving_time_s integer;
alter table public.run_sessions add column if not exists elapsed_time_s integer;
alter table public.run_sessions add column if not exists source_priority integer default 0;
alter table public.run_sessions add column if not exists import_file_name text;
alter table public.run_sessions add column if not exists raw_metrics_json text;
alter table public.actual_strength_sets add column if not exists plan_day_id text;
alter table public.plan_days add column if not exists session_type text;

alter table public.workout_days add column if not exists workspace_id uuid;
alter table public.workout_days add column if not exists athlete_profile_id uuid;
alter table public.actual_strength_sets add column if not exists workspace_id uuid;
alter table public.actual_strength_sets add column if not exists athlete_profile_id uuid;
alter table public.prescribed_strength_sets add column if not exists workspace_id uuid;
alter table public.prescribed_strength_sets add column if not exists athlete_profile_id uuid;
alter table public.sleep_nights add column if not exists workspace_id uuid;
alter table public.sleep_nights add column if not exists athlete_profile_id uuid;
alter table public.run_sessions add column if not exists workspace_id uuid;
alter table public.run_sessions add column if not exists athlete_profile_id uuid;
alter table public.run_segments add column if not exists workspace_id uuid;
alter table public.run_segments add column if not exists athlete_profile_id uuid;
alter table public.run_session_details add column if not exists workspace_id uuid;
alter table public.run_session_details add column if not exists athlete_profile_id uuid;
alter table public.run_override_audit add column if not exists workspace_id uuid;
alter table public.run_override_audit add column if not exists athlete_profile_id uuid;
alter table public.rule_triggers add column if not exists workspace_id uuid;
alter table public.rule_triggers add column if not exists athlete_profile_id uuid;
alter table public.ai_audit add column if not exists workspace_id uuid;
alter table public.ai_audit add column if not exists athlete_profile_id uuid;
alter table public.plan_cycles add column if not exists workspace_id uuid;
alter table public.plan_cycles add column if not exists athlete_profile_id uuid;
alter table public.plan_days add column if not exists workspace_id uuid;
alter table public.plan_days add column if not exists athlete_profile_id uuid;
alter table public.plan_prescribed_strength_sets add column if not exists workspace_id uuid;
alter table public.plan_prescribed_strength_sets add column if not exists athlete_profile_id uuid;
alter table public.plan_prescribed_runs add column if not exists workspace_id uuid;
alter table public.plan_prescribed_runs add column if not exists athlete_profile_id uuid;
alter table public.plan_exercise_alternatives add column if not exists workspace_id uuid;
alter table public.plan_exercise_alternatives add column if not exists athlete_profile_id uuid;
alter table public.exercise_substitutions add column if not exists workspace_id uuid;
alter table public.exercise_substitutions add column if not exists athlete_profile_id uuid;
alter table public.plan_summary_snapshots add column if not exists workspace_id uuid;
alter table public.plan_summary_snapshots add column if not exists athlete_profile_id uuid;
alter table public.plan_import_audit add column if not exists workspace_id uuid;
alter table public.plan_import_audit add column if not exists athlete_profile_id uuid;

update public.run_sessions
set run_key = coalesce(run_key, 'legacy_' || id),
    source_priority = coalesce(source_priority, 0)
where run_key is null or source_priority is null;

-- Indexes
create index if not exists idx_workspace_memberships_user_workspace
  on public.workspace_memberships(user_id, workspace_id);
create index if not exists idx_workspace_memberships_workspace_role
  on public.workspace_memberships(workspace_id, role);
create index if not exists idx_athlete_profiles_workspace
  on public.athlete_profiles(workspace_id);
create index if not exists idx_profile_assignments_user_workspace
  on public.athlete_profile_assignments(user_id, workspace_id);
create index if not exists idx_workspace_invites_workspace_status
  on public.workspace_invites(workspace_id, status);
create index if not exists idx_workspace_invites_email_status
  on public.workspace_invites(lower(email), status);

do $$
declare
  t text;
  domain_tables text[] := array[
    'workout_days',
    'actual_strength_sets',
    'prescribed_strength_sets',
    'sleep_nights',
    'run_sessions',
    'run_segments',
    'run_session_details',
    'run_override_audit',
    'rule_triggers',
    'ai_audit',
    'plan_cycles',
    'plan_days',
    'plan_prescribed_strength_sets',
    'plan_prescribed_runs',
    'plan_exercise_alternatives',
    'exercise_substitutions',
    'plan_summary_snapshots',
    'plan_import_audit'
  ];
begin
  foreach t in array domain_tables loop
    execute format(
      'create index if not exists idx_%1$s_workspace_profile on public.%1$s(workspace_id, athlete_profile_id)',
      t
    );
  end loop;
end $$;

-- RLS enablement
alter table public.workspaces enable row level security;
alter table public.workspace_memberships enable row level security;
alter table public.athlete_profiles enable row level security;
alter table public.athlete_profile_assignments enable row level security;
alter table public.workspace_invites enable row level security;

alter table public.workout_days enable row level security;
alter table public.actual_strength_sets enable row level security;
alter table public.prescribed_strength_sets enable row level security;
alter table public.sleep_nights enable row level security;
alter table public.run_sessions enable row level security;
alter table public.run_segments enable row level security;
alter table public.run_session_details enable row level security;
alter table public.run_override_audit enable row level security;
alter table public.rule_triggers enable row level security;
alter table public.ai_audit enable row level security;
alter table public.plan_cycles enable row level security;
alter table public.plan_days enable row level security;
alter table public.plan_prescribed_strength_sets enable row level security;
alter table public.plan_prescribed_runs enable row level security;
alter table public.plan_exercise_alternatives enable row level security;
alter table public.exercise_substitutions enable row level security;
alter table public.plan_summary_snapshots enable row level security;
alter table public.plan_import_audit enable row level security;

-- Authorization helper functions
create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function public.is_workspace_member(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_memberships wm
    where wm.workspace_id = p_workspace_id
      and wm.user_id = auth.uid()
      and wm.status = 'active'
  );
$$;

create or replace function public.workspace_role(p_workspace_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select wm.role
  from public.workspace_memberships wm
  where wm.workspace_id = p_workspace_id
    and wm.user_id = auth.uid()
    and wm.status = 'active'
  order by wm.created_at asc
  limit 1;
$$;

create or replace function public.is_workspace_owner(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.workspace_role(p_workspace_id), '') = 'owner';
$$;

create or replace function public.can_view_profile(
  p_workspace_id uuid,
  p_profile_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_workspace_id is not null
    and p_profile_id is not null
    and (
      public.is_workspace_owner(p_workspace_id)
      or exists (
        select 1
        from public.athlete_profile_assignments apa
        join public.workspace_memberships wm
          on wm.workspace_id = apa.workspace_id
         and wm.user_id = apa.user_id
         and wm.status = 'active'
        where apa.workspace_id = p_workspace_id
          and apa.athlete_profile_id = p_profile_id
          and apa.user_id = auth.uid()
          and apa.can_view = true
      )
    );
$$;

create or replace function public.can_edit_profile(
  p_workspace_id uuid,
  p_profile_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_workspace_id is not null
    and p_profile_id is not null
    and (
      public.is_workspace_owner(p_workspace_id)
      or exists (
        select 1
        from public.athlete_profile_assignments apa
        join public.workspace_memberships wm
          on wm.workspace_id = apa.workspace_id
         and wm.user_id = apa.user_id
         and wm.status = 'active'
        where apa.workspace_id = p_workspace_id
          and apa.athlete_profile_id = p_profile_id
          and apa.user_id = auth.uid()
          and apa.can_edit = true
      )
    );
$$;

-- Workspace metadata policies
drop policy if exists workspace_select_member on public.workspaces;
create policy workspace_select_member
  on public.workspaces
  for select
  to authenticated
  using (public.is_workspace_member(id));

drop policy if exists workspace_insert_creator on public.workspaces;
create policy workspace_insert_creator
  on public.workspaces
  for insert
  to authenticated
  with check (created_by_user_id = auth.uid());

drop policy if exists workspace_update_owner on public.workspaces;
create policy workspace_update_owner
  on public.workspaces
  for update
  to authenticated
  using (public.is_workspace_owner(id))
  with check (public.is_workspace_owner(id));

drop policy if exists workspace_delete_owner on public.workspaces;
create policy workspace_delete_owner
  on public.workspaces
  for delete
  to authenticated
  using (public.is_workspace_owner(id));

drop policy if exists workspace_membership_select_member on public.workspace_memberships;
create policy workspace_membership_select_member
  on public.workspace_memberships
  for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

drop policy if exists workspace_membership_insert_owner on public.workspace_memberships;
create policy workspace_membership_insert_owner
  on public.workspace_memberships
  for insert
  to authenticated
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_membership_update_owner on public.workspace_memberships;
create policy workspace_membership_update_owner
  on public.workspace_memberships
  for update
  to authenticated
  using (public.is_workspace_owner(workspace_id))
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_membership_delete_owner on public.workspace_memberships;
create policy workspace_membership_delete_owner
  on public.workspace_memberships
  for delete
  to authenticated
  using (public.is_workspace_owner(workspace_id));

drop policy if exists athlete_profile_select_member on public.athlete_profiles;
create policy athlete_profile_select_member
  on public.athlete_profiles
  for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

drop policy if exists athlete_profile_insert_owner_or_coach on public.athlete_profiles;
create policy athlete_profile_insert_owner_or_coach
  on public.athlete_profiles
  for insert
  to authenticated
  with check (coalesce(public.workspace_role(workspace_id), '') in ('owner', 'coach'));

drop policy if exists athlete_profile_update_owner_or_coach on public.athlete_profiles;
create policy athlete_profile_update_owner_or_coach
  on public.athlete_profiles
  for update
  to authenticated
  using (coalesce(public.workspace_role(workspace_id), '') in ('owner', 'coach'))
  with check (coalesce(public.workspace_role(workspace_id), '') in ('owner', 'coach'));

drop policy if exists athlete_profile_delete_owner on public.athlete_profiles;
create policy athlete_profile_delete_owner
  on public.athlete_profiles
  for delete
  to authenticated
  using (public.is_workspace_owner(workspace_id));

drop policy if exists profile_assignment_select_member on public.athlete_profile_assignments;
create policy profile_assignment_select_member
  on public.athlete_profile_assignments
  for select
  to authenticated
  using (public.is_workspace_member(workspace_id));

drop policy if exists profile_assignment_insert_owner on public.athlete_profile_assignments;
create policy profile_assignment_insert_owner
  on public.athlete_profile_assignments
  for insert
  to authenticated
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists profile_assignment_update_owner on public.athlete_profile_assignments;
create policy profile_assignment_update_owner
  on public.athlete_profile_assignments
  for update
  to authenticated
  using (public.is_workspace_owner(workspace_id))
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists profile_assignment_delete_owner on public.athlete_profile_assignments;
create policy profile_assignment_delete_owner
  on public.athlete_profile_assignments
  for delete
  to authenticated
  using (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_invites_owner_select on public.workspace_invites;
create policy workspace_invites_owner_select
  on public.workspace_invites
  for select
  to authenticated
  using (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_invites_owner_insert on public.workspace_invites;
create policy workspace_invites_owner_insert
  on public.workspace_invites
  for insert
  to authenticated
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_invites_owner_update on public.workspace_invites;
create policy workspace_invites_owner_update
  on public.workspace_invites
  for update
  to authenticated
  using (public.is_workspace_owner(workspace_id))
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_invites_owner_delete on public.workspace_invites;
create policy workspace_invites_owner_delete
  on public.workspace_invites
  for delete
  to authenticated
  using (public.is_workspace_owner(workspace_id));

-- Domain table policies

do $$
declare
  t text;
  domain_tables text[] := array[
    'workout_days',
    'actual_strength_sets',
    'prescribed_strength_sets',
    'sleep_nights',
    'run_sessions',
    'run_segments',
    'run_session_details',
    'run_override_audit',
    'rule_triggers',
    'ai_audit',
    'plan_cycles',
    'plan_days',
    'plan_prescribed_strength_sets',
    'plan_prescribed_runs',
    'plan_exercise_alternatives',
    'exercise_substitutions',
    'plan_summary_snapshots',
    'plan_import_audit'
  ];
begin
  foreach t in array domain_tables loop
    execute format('drop policy if exists "auth_all_%1$s" on public.%1$s', t);
    execute format('drop policy if exists "profile_select_%1$s" on public.%1$s', t);
    execute format('drop policy if exists "profile_insert_%1$s" on public.%1$s', t);
    execute format('drop policy if exists "profile_update_%1$s" on public.%1$s', t);
    execute format('drop policy if exists "profile_delete_%1$s" on public.%1$s', t);

    execute format(
      'create policy "profile_select_%1$s" on public.%1$s for select to authenticated using (public.can_view_profile(workspace_id, athlete_profile_id))',
      t
    );
    execute format(
      'create policy "profile_insert_%1$s" on public.%1$s for insert to authenticated with check (public.can_edit_profile(workspace_id, athlete_profile_id))',
      t
    );
    execute format(
      'create policy "profile_update_%1$s" on public.%1$s for update to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id)) with check (public.can_edit_profile(workspace_id, athlete_profile_id))',
      t
    );
    execute format(
      'create policy "profile_delete_%1$s" on public.%1$s for delete to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id))',
      t
    );
  end loop;
end $$;

-- RPCs
create or replace function public.bootstrap_workspace_for_current_user()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user_email text;
  v_workspace_id uuid;
  v_profile_id uuid;
  v_role text;
  v_needs_legacy_claim boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_user_email := coalesce(lower(auth.jwt()->>'email'), '');

  if not exists (
    select 1
    from public.workspace_memberships wm
    where wm.user_id = v_user_id
      and wm.status = 'active'
  ) then
    insert into public.workspaces(name, created_by_user_id)
    values ('My Workspace', v_user_id)
    returning id into v_workspace_id;

    insert into public.workspace_memberships(
      workspace_id,
      user_id,
      user_email,
      role,
      status,
      created_by_user_id
    ) values (
      v_workspace_id,
      v_user_id,
      v_user_email,
      'owner',
      'active',
      v_user_id
    );

    insert into public.athlete_profiles(
      workspace_id,
      name,
      created_by_user_id
    ) values (
      v_workspace_id,
      'Default Athlete',
      v_user_id
    ) returning id into v_profile_id;

    insert into public.athlete_profile_assignments(
      workspace_id,
      athlete_profile_id,
      user_id,
      can_view,
      can_edit,
      created_by_user_id
    ) values (
      v_workspace_id,
      v_profile_id,
      v_user_id,
      true,
      true,
      v_user_id
    );
  end if;

  select wm.workspace_id, wm.role
  into v_workspace_id, v_role
  from public.workspace_memberships wm
  where wm.user_id = v_user_id
    and wm.status = 'active'
  order by wm.created_at asc
  limit 1;

  if v_workspace_id is null then
    raise exception 'No active workspace membership found.';
  end if;

  select apa.athlete_profile_id
  into v_profile_id
  from public.athlete_profile_assignments apa
  where apa.workspace_id = v_workspace_id
    and apa.user_id = v_user_id
    and apa.can_view = true
  order by apa.created_at asc
  limit 1;

  if v_profile_id is null then
    insert into public.athlete_profiles(
      workspace_id,
      name,
      created_by_user_id
    ) values (
      v_workspace_id,
      'Default Athlete',
      v_user_id
    ) returning id into v_profile_id;

    insert into public.athlete_profile_assignments(
      workspace_id,
      athlete_profile_id,
      user_id,
      can_view,
      can_edit,
      created_by_user_id
    ) values (
      v_workspace_id,
      v_profile_id,
      v_user_id,
      true,
      true,
      v_user_id
    );
  end if;

  v_needs_legacy_claim := exists (
    select 1
    from public.workout_days
    where workspace_id is null
       or athlete_profile_id is null
    limit 1
  );

  return jsonb_build_object(
    'active_workspace_id', v_workspace_id,
    'active_profile_id', v_profile_id,
    'active_role', coalesce(v_role, 'athlete'),
    'needs_legacy_claim', v_needs_legacy_claim,
    'workspaces', coalesce((
      select jsonb_agg(to_jsonb(x))
      from (
        select w.id, w.name, w.created_at, w.created_by_user_id
        from public.workspaces w
        join public.workspace_memberships wm
          on wm.workspace_id = w.id
         and wm.user_id = v_user_id
         and wm.status = 'active'
      ) x
    ), '[]'::jsonb),
    'memberships', coalesce((
      select jsonb_agg(to_jsonb(x))
      from (
        select wm.id, wm.workspace_id, wm.user_id, wm.user_email, wm.display_name,
               wm.role, wm.status, wm.created_at, wm.created_by_user_id
        from public.workspace_memberships wm
        where wm.workspace_id in (
          select workspace_id
          from public.workspace_memberships
          where user_id = v_user_id
            and status = 'active'
        )
      ) x
    ), '[]'::jsonb),
    'profiles', coalesce((
      select jsonb_agg(to_jsonb(x))
      from (
        select ap.id, ap.workspace_id, ap.name, ap.date_of_birth, ap.notes,
               ap.created_at, ap.created_by_user_id
        from public.athlete_profiles ap
        where ap.workspace_id in (
          select workspace_id
          from public.workspace_memberships
          where user_id = v_user_id
            and status = 'active'
        )
      ) x
    ), '[]'::jsonb),
    'assignments', coalesce((
      select jsonb_agg(to_jsonb(x))
      from (
        select apa.id, apa.workspace_id, apa.athlete_profile_id, apa.user_id,
               apa.can_view, apa.can_edit, apa.created_at, apa.created_by_user_id
        from public.athlete_profile_assignments apa
        where apa.workspace_id in (
          select workspace_id
          from public.workspace_memberships
          where user_id = v_user_id
            and status = 'active'
        )
      ) x
    ), '[]'::jsonb),
    'invites', case
      when coalesce(v_role, '') = 'owner' then coalesce((
        select jsonb_agg(to_jsonb(x))
        from (
          select wi.id, wi.workspace_id, wi.email, wi.role, wi.display_name,
                 wi.expires_at, wi.status, wi.assigned_profile_ids,
                 wi.created_at, wi.created_by_user_id
          from public.workspace_invites wi
          where wi.workspace_id = v_workspace_id
            and wi.status = 'pending'
          order by wi.created_at desc
        ) x
      ), '[]'::jsonb)
      else '[]'::jsonb
    end
  );
end;
$$;

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
set search_path = public
as $$
declare
  v_user_id uuid;
  v_email text;
  v_token text;
  v_token_hash text;
  v_expires_at timestamptz;
  v_invite_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_workspace_owner(p_workspace_id) then
    raise exception 'Only workspace owners can create invites';
  end if;

  v_email := lower(trim(coalesce(p_email, '')));
  if v_email = '' then
    raise exception 'Invite email is required';
  end if;

  if p_role not in ('coach', 'athlete') then
    raise exception 'Invite role must be coach or athlete';
  end if;

  update public.workspace_invites
  set status = 'revoked'
  where workspace_id = p_workspace_id
    and lower(email) = v_email
    and status = 'pending';

  v_token := encode(gen_random_bytes(24), 'hex');
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');
  v_expires_at := now() + interval '7 days';

  insert into public.workspace_invites(
    workspace_id,
    email,
    role,
    display_name,
    token_hash,
    expires_at,
    status,
    assigned_profile_ids,
    created_by_user_id
  ) values (
    p_workspace_id,
    v_email,
    p_role,
    p_display_name,
    v_token_hash,
    v_expires_at,
    'pending',
    coalesce(p_assigned_profile_ids, '{}'::uuid[]),
    v_user_id
  ) returning id into v_invite_id;

  return jsonb_build_object(
    'invite_id', v_invite_id,
    'workspace_id', p_workspace_id,
    'email', v_email,
    'role', p_role,
    'token', v_token,
    'expires_at', v_expires_at,
    'deep_link', 'adaptiveathlete://join?token=' || v_token
  );
end;
$$;

create or replace function public.accept_workspace_invite(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user_email text;
  v_token_hash text;
  v_invite public.workspace_invites%rowtype;
  v_profile_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_user_email := lower(trim(coalesce(auth.jwt()->>'email', '')));
  if v_user_email = '' then
    raise exception 'Authenticated user does not have an email claim';
  end if;

  if coalesce(trim(p_token), '') = '' then
    raise exception 'Invite token is required';
  end if;

  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  select *
  into v_invite
  from public.workspace_invites wi
  where wi.token_hash = v_token_hash
    and wi.status = 'pending'
  order by wi.created_at desc
  limit 1;

  if v_invite.id is null then
    raise exception 'Invite token is invalid or already used';
  end if;

  if v_invite.expires_at < now() then
    update public.workspace_invites
    set status = 'expired'
    where id = v_invite.id;
    raise exception 'Invite token is expired';
  end if;

  if lower(v_invite.email) <> v_user_email then
    raise exception 'Invite email does not match signed-in user email';
  end if;

  insert into public.workspace_memberships(
    workspace_id,
    user_id,
    user_email,
    role,
    status,
    created_by_user_id
  ) values (
    v_invite.workspace_id,
    v_user_id,
    v_user_email,
    v_invite.role,
    'active',
    v_invite.created_by_user_id
  )
  on conflict (workspace_id, user_id)
  do update set
    user_email = excluded.user_email,
    status = 'active';

  if coalesce(array_length(v_invite.assigned_profile_ids, 1), 0) > 0 then
    foreach v_profile_id in array v_invite.assigned_profile_ids loop
      insert into public.athlete_profile_assignments(
        workspace_id,
        athlete_profile_id,
        user_id,
        can_view,
        can_edit,
        created_by_user_id
      ) values (
        v_invite.workspace_id,
        v_profile_id,
        v_user_id,
        true,
        true,
        v_invite.created_by_user_id
      )
      on conflict (athlete_profile_id, user_id)
      do update set
        can_view = true,
        can_edit = true;
    end loop;
  else
    select ap.id
    into v_profile_id
    from public.athlete_profiles ap
    where ap.workspace_id = v_invite.workspace_id
    order by ap.created_at asc
    limit 1;

    if v_profile_id is not null then
      insert into public.athlete_profile_assignments(
        workspace_id,
        athlete_profile_id,
        user_id,
        can_view,
        can_edit,
        created_by_user_id
      ) values (
        v_invite.workspace_id,
        v_profile_id,
        v_user_id,
        true,
        true,
        v_invite.created_by_user_id
      )
      on conflict (athlete_profile_id, user_id)
      do update set
        can_view = true,
        can_edit = true;
    end if;
  end if;

  update public.workspace_invites
  set status = 'accepted',
      accepted_by_user_id = v_user_id,
      accepted_at = now()
  where id = v_invite.id;

  return jsonb_build_object(
    'workspace_id', v_invite.workspace_id,
    'role', v_invite.role,
    'invite_id', v_invite.id
  );
end;
$$;

create or replace function public.claim_legacy_rows_into_profile(
  p_workspace_id uuid,
  p_athlete_profile_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
  v_results jsonb := '{}'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_workspace_owner(p_workspace_id) then
    raise exception 'Only workspace owner can claim legacy rows';
  end if;

  update public.workout_days
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('workout_days', v_count);

  update public.actual_strength_sets
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('actual_strength_sets', v_count);

  update public.prescribed_strength_sets
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('prescribed_strength_sets', v_count);

  update public.sleep_nights
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('sleep_nights', v_count);

  update public.run_sessions
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('run_sessions', v_count);

  update public.run_segments
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('run_segments', v_count);

  update public.run_session_details
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('run_session_details', v_count);

  update public.run_override_audit
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('run_override_audit', v_count);

  update public.rule_triggers
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('rule_triggers', v_count);

  update public.ai_audit
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('ai_audit', v_count);

  update public.plan_cycles
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_cycles', v_count);

  update public.plan_days
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_days', v_count);

  update public.plan_prescribed_strength_sets
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_prescribed_strength_sets', v_count);

  update public.plan_prescribed_runs
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_prescribed_runs', v_count);

  update public.plan_exercise_alternatives
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_exercise_alternatives', v_count);

  update public.exercise_substitutions
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('exercise_substitutions', v_count);

  update public.plan_summary_snapshots
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_summary_snapshots', v_count);

  update public.plan_import_audit
  set workspace_id = p_workspace_id,
      athlete_profile_id = p_athlete_profile_id
  where workspace_id is null or athlete_profile_id is null;
  get diagnostics v_count = row_count;
  v_results := v_results || jsonb_build_object('plan_import_audit', v_count);

  return jsonb_build_object(
    'workspace_id', p_workspace_id,
    'athlete_profile_id', p_athlete_profile_id,
    'updated', v_results
  );
end;
$$;
