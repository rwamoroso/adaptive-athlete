-- Run this in Supabase SQL Editor for the FitnessData project.

create table if not exists public.workout_days (
  id text primary key,
  workout_date text not null,
  created_at bigint not null,
  notes text null
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
  created_at bigint not null
);

create table if not exists public.prescribed_strength_sets (
  id text primary key,
  workout_day_id text not null,
  exercise_canonical text not null,
  set_index integer not null,
  weight double precision null,
  reps integer null,
  rir integer null,
  unit text not null
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
  source text not null
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
  source text not null
);

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
update public.run_sessions
set run_key = coalesce(run_key, 'legacy_' || id),
    source_priority = coalesce(source_priority, 0)
where run_key is null or source_priority is null;

create table if not exists public.run_segments (
  id text primary key,
  run_session_id text not null,
  idx integer not null,
  duration_s integer null,
  distance_m double precision null,
  speed_mps double precision null
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
  raw_metrics_json text not null
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
  created_at bigint not null
);

create table if not exists public.rule_triggers (
  id text primary key,
  trigger_date text not null,
  rule_code text not null,
  triggered boolean not null,
  details_json text not null,
  created_at bigint not null
);

create table if not exists public.ai_audit (
  id text primary key,
  requested_at bigint not null,
  date_window_start text null,
  date_window_end text null,
  input_snapshot_json text not null,
  response_json text not null,
  schema_valid boolean not null,
  notes text null
);

create table if not exists public.plan_cycles (
  id text primary key,
  cycle_key text not null,
  week_start text not null,
  week_end text not null,
  source text not null,
  created_at bigint not null
);

create table if not exists public.plan_days (
  id text primary key,
  plan_cycle_id text not null,
  day_number integer not null,
  sheet_name text not null,
  estimated_date text null,
  session_type text null,
  created_at bigint not null
);

alter table public.plan_days add column if not exists session_type text;

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
  created_at bigint not null
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
  created_at bigint not null
);

create table if not exists public.plan_exercise_alternatives (
  id text primary key,
  plan_day_id text null,
  prescribed_exercise_canonical text not null,
  alternative_exercise_canonical text not null,
  priority integer not null default 0,
  notes text null,
  created_at bigint not null
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
  created_at bigint not null
);

create table if not exists public.plan_summary_snapshots (
  id text primary key,
  plan_cycle_id text not null,
  tab_name text not null,
  snapshot_json text not null,
  created_at bigint not null
);

create table if not exists public.plan_import_audit (
  id text primary key,
  imported_at bigint not null,
  file_name text not null,
  success boolean not null,
  details_json text not null,
  conflict_report_path text null
);

-- Minimal permissive policy for authenticated users.
-- Tighten this for production.
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

drop policy if exists "auth_all_workout_days" on public.workout_days;
create policy "auth_all_workout_days" on public.workout_days for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_actual_strength_sets" on public.actual_strength_sets;
create policy "auth_all_actual_strength_sets" on public.actual_strength_sets for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_prescribed_strength_sets" on public.prescribed_strength_sets;
create policy "auth_all_prescribed_strength_sets" on public.prescribed_strength_sets for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_sleep_nights" on public.sleep_nights;
create policy "auth_all_sleep_nights" on public.sleep_nights for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_run_sessions" on public.run_sessions;
create policy "auth_all_run_sessions" on public.run_sessions for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_run_segments" on public.run_segments;
create policy "auth_all_run_segments" on public.run_segments for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_run_session_details" on public.run_session_details;
create policy "auth_all_run_session_details" on public.run_session_details for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_run_override_audit" on public.run_override_audit;
create policy "auth_all_run_override_audit" on public.run_override_audit for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_rule_triggers" on public.rule_triggers;
create policy "auth_all_rule_triggers" on public.rule_triggers for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_ai_audit" on public.ai_audit;
create policy "auth_all_ai_audit" on public.ai_audit for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_cycles" on public.plan_cycles;
create policy "auth_all_plan_cycles" on public.plan_cycles for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_days" on public.plan_days;
create policy "auth_all_plan_days" on public.plan_days for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_prescribed_strength_sets" on public.plan_prescribed_strength_sets;
create policy "auth_all_plan_prescribed_strength_sets" on public.plan_prescribed_strength_sets for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_prescribed_runs" on public.plan_prescribed_runs;
create policy "auth_all_plan_prescribed_runs" on public.plan_prescribed_runs for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_exercise_alternatives" on public.plan_exercise_alternatives;
create policy "auth_all_plan_exercise_alternatives" on public.plan_exercise_alternatives for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_exercise_substitutions" on public.exercise_substitutions;
create policy "auth_all_exercise_substitutions" on public.exercise_substitutions for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_summary_snapshots" on public.plan_summary_snapshots;
create policy "auth_all_plan_summary_snapshots" on public.plan_summary_snapshots for all to authenticated using (true) with check (true);

drop policy if exists "auth_all_plan_import_audit" on public.plan_import_audit;
create policy "auth_all_plan_import_audit" on public.plan_import_audit for all to authenticated using (true) with check (true);
