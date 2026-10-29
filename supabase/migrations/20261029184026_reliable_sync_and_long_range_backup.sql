-- Additive upgrade for the existing hosted database. No existing rows are rewritten.
alter table public.actual_strength_sets add column if not exists prescribed_exercise_canonical text;
alter table public.actual_strength_sets add column if not exists substitution_id text;
alter table public.plan_days add column if not exists shift_reason text;
create unique index if not exists athlete_profiles_id_workspace_key
  on public.athlete_profiles(id, workspace_id);

create table if not exists public.plan_long_range_weeks (
  id text primary key,
  week_label text not null,
  week_number bigint null,
  week_start text not null,
  week_end text not null,
  run_focus text null,
  strength_focus text null,
  strength_progression_expectation text null,
  primary_progression_target text null,
  recovery_emphasis text null,
  deload boolean not null default false,
  notes text null,
  source text not null,
  last_plan_cycle_id text null,
  created_at bigint not null,
  updated_at bigint not null,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  athlete_profile_id uuid not null,
  foreign key (athlete_profile_id, workspace_id) references public.athlete_profiles(id, workspace_id) on delete cascade
);
create index if not exists plan_long_range_weeks_scope_week on public.plan_long_range_weeks(workspace_id, athlete_profile_id, week_start);

create table if not exists public.plan_long_range_week_performance (
  id text primary key,
  plan_long_range_week_id text null,
  week_label text null,
  week_number bigint null,
  week_start text not null,
  week_end text not null,
  evaluated_plan_cycle_id text null,
  evaluation_source text not null,
  planned_day_count bigint not null,
  completed_plan_days bigint not null,
  planned_run_days bigint not null,
  actual_run_days bigint not null,
  planned_run_sessions bigint not null,
  actual_run_sessions bigint not null,
  planned_strength_exercises bigint not null,
  actual_strength_exercises bigint not null,
  planned_strength_sets bigint not null,
  actual_strength_sets bigint not null,
  strength_progression_expectation text null,
  strength_progression_evaluation text null,
  actual_run_distance_m double precision null,
  actual_run_duration_s bigint null,
  metrics_json text null,
  captured_at bigint not null,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  athlete_profile_id uuid not null,
  foreign key (athlete_profile_id, workspace_id) references public.athlete_profiles(id, workspace_id) on delete cascade
);
create index if not exists plan_long_range_week_performance_scope_week on public.plan_long_range_week_performance(workspace_id, athlete_profile_id, week_start);

create table if not exists public.sync_tombstones (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  athlete_profile_id uuid not null,
  table_name text not null,
  row_key text not null,
  deleted_at timestamptz not null default now(),
  primary key(workspace_id, athlete_profile_id, table_name, row_key),
  foreign key(athlete_profile_id, workspace_id) references public.athlete_profiles(id, workspace_id) on delete cascade
);
alter table public.plan_long_range_weeks enable row level security;
grant select, insert, update, delete on public.plan_long_range_weeks to authenticated;
revoke all on public.plan_long_range_weeks from anon;
drop policy if exists scoped_select on public.plan_long_range_weeks;
create policy scoped_select on public.plan_long_range_weeks for select to authenticated using (public.can_view_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_insert on public.plan_long_range_weeks;
create policy scoped_insert on public.plan_long_range_weeks for insert to authenticated with check (public.can_edit_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_update on public.plan_long_range_weeks;
create policy scoped_update on public.plan_long_range_weeks for update to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id)) with check (public.can_edit_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_delete on public.plan_long_range_weeks;
create policy scoped_delete on public.plan_long_range_weeks for delete to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id));
alter table public.plan_long_range_week_performance enable row level security;
grant select, insert, update, delete on public.plan_long_range_week_performance to authenticated;
revoke all on public.plan_long_range_week_performance from anon;
drop policy if exists scoped_select on public.plan_long_range_week_performance;
create policy scoped_select on public.plan_long_range_week_performance for select to authenticated using (public.can_view_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_insert on public.plan_long_range_week_performance;
create policy scoped_insert on public.plan_long_range_week_performance for insert to authenticated with check (public.can_edit_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_update on public.plan_long_range_week_performance;
create policy scoped_update on public.plan_long_range_week_performance for update to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id)) with check (public.can_edit_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_delete on public.plan_long_range_week_performance;
create policy scoped_delete on public.plan_long_range_week_performance for delete to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id));
alter table public.sync_tombstones enable row level security;
grant select, insert, update, delete on public.sync_tombstones to authenticated;
revoke all on public.sync_tombstones from anon;
drop policy if exists scoped_select on public.sync_tombstones;
create policy scoped_select on public.sync_tombstones for select to authenticated using (public.can_view_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_insert on public.sync_tombstones;
create policy scoped_insert on public.sync_tombstones for insert to authenticated with check (public.can_edit_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_update on public.sync_tombstones;
create policy scoped_update on public.sync_tombstones for update to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id)) with check (public.can_edit_profile(workspace_id, athlete_profile_id));
drop policy if exists scoped_delete on public.sync_tombstones;
create policy scoped_delete on public.sync_tombstones for delete to authenticated using (public.can_edit_profile(workspace_id, athlete_profile_id));

-- SECURITY INVOKER preserves the caller's table grants and RLS policies.
-- The expected cloud snapshot is compared while holding the row lock.
create or replace function public.sync_apply_change(
  p_table text, p_key text, p_workspace uuid, p_profile uuid,
  p_expected jsonb, p_next jsonb, p_restore boolean default false
) returns jsonb
language plpgsql security invoker set search_path = ''
as $function$
declare
  v_key text;
  v_current jsonb;
  v_result jsonb;
  v_assignments text;
begin
  if auth.uid() is null or not public.can_edit_profile(p_workspace, p_profile)
      or not exists(select 1 from public.athlete_profiles where id=p_profile and workspace_id=p_workspace) then
    raise exception 'Profile edit permission required' using errcode='42501';
  end if;
  if not p_table = any(array[
    'workout_days','plan_cycles','plan_days','exercise_substitutions',
    'actual_strength_sets','prescribed_strength_sets','sleep_nights',
    'run_sessions','run_segments','run_session_details','run_override_audit',
    'rule_triggers','ai_audit','plan_prescribed_strength_sets','plan_prescribed_runs',
    'plan_exercise_alternatives','plan_summary_snapshots','plan_import_audit',
    'athlete_planning_profiles','weekly_plan_build_requests',
    'plan_long_range_weeks','plan_long_range_week_performance'
  ]) then
    raise exception 'Unsupported sync collection' using errcode='22023';
  end if;
  v_key := case when p_table='run_session_details' then 'run_session_id' else 'id' end;
  if p_next is not null and (
      p_next->>v_key is distinct from p_key
      or p_next->>'workspace_id' is distinct from p_workspace::text
      or p_next->>'athlete_profile_id' is distinct from p_profile::text) then
    raise exception 'Record identity and profile must match' using errcode='22023';
  end if;
  -- Serialize insert/delete pairs as well as updates for this identity.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    p_workspace::text || '/' || p_profile::text || '/' || p_table || '/' || p_key, 0));
  execute format('select to_jsonb(t) from public.%I t where %I=$1 and workspace_id=$2 and athlete_profile_id=$3 for update',p_table,v_key)
    into v_current using p_key,p_workspace,p_profile;
  if v_current is distinct from p_expected then
    return jsonb_build_object('applied',false,'row',v_current);
  end if;
  if p_next is not null and v_current is null and not p_restore and exists(
    select 1 from public.sync_tombstones where workspace_id=p_workspace
      and athlete_profile_id=p_profile and table_name=p_table and row_key=p_key
  ) then
    return jsonb_build_object('applied',false,'row',null);
  end if;
  if p_next is null then
    execute format('delete from public.%I where %I=$1 and workspace_id=$2 and athlete_profile_id=$3',p_table,v_key)
      using p_key,p_workspace,p_profile;
    insert into public.sync_tombstones(workspace_id,athlete_profile_id,table_name,row_key)
      values(p_workspace,p_profile,p_table,p_key)
      on conflict(workspace_id,athlete_profile_id,table_name,row_key) do update set deleted_at=now();
  elsif v_current is null then
    execute format('insert into public.%I select * from jsonb_populate_record(null::public.%I,$1) returning to_jsonb(%I.*)',p_table,p_table,p_table)
      into v_result using p_next;
    delete from public.sync_tombstones where workspace_id=p_workspace
      and athlete_profile_id=p_profile and table_name=p_table and row_key=p_key;
  else
    select string_agg(format('%I=r.%I',attname,attname),',')
      into v_assignments
      from pg_catalog.pg_attribute where attrelid=format('public.%I',p_table)::regclass
        and attnum>0 and not attisdropped and attname<>v_key;
    execute format('update public.%I t set %s from jsonb_populate_record(null::public.%I,$1) r where t.%I=$2 and t.workspace_id=$3 and t.athlete_profile_id=$4 returning to_jsonb(t)',p_table,v_assignments,p_table,v_key)
      into v_result using v_current || p_next,p_key,p_workspace,p_profile;
  end if;
  return jsonb_build_object('applied',true,'row',v_result);
exception when unique_violation then
  -- A concurrent insert or a natural-key collision never overwrites another row.
  execute format('select to_jsonb(t) from public.%I t where %I=$1 and workspace_id=$2 and athlete_profile_id=$3',p_table,v_key)
    into v_current using p_key,p_workspace,p_profile;
  return jsonb_build_object('applied',false,'row',v_current);
end;
$function$;
revoke all on function public.sync_apply_change(text,text,uuid,uuid,jsonb,jsonb,boolean) from public, anon;
grant execute on function public.sync_apply_change(text,text,uuid,uuid,jsonb,jsonb,boolean) to authenticated;
notify pgrst, 'reload schema';
