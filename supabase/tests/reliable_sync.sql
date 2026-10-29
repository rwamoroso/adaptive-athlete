-- Run as the database owner. All fixtures and writes are rolled back.
begin;
select set_config('test.sync_workspace',gen_random_uuid()::text,true),
       set_config('test.sync_profile',gen_random_uuid()::text,true),
       set_config('test.sync_owner',gen_random_uuid()::text,true),
       set_config('test.sync_outsider',gen_random_uuid()::text,true);
insert into public.workspaces(id,name,created_by_user_id)
values(current_setting('test.sync_workspace')::uuid,'Sync verification',current_setting('test.sync_owner')::uuid);
insert into public.workspace_memberships(workspace_id,user_id,user_email,role,status,created_by_user_id)
values(current_setting('test.sync_workspace')::uuid,current_setting('test.sync_owner')::uuid,
       'sync-check@example.invalid','owner','active',current_setting('test.sync_owner')::uuid);
insert into public.athlete_profiles(id,workspace_id,name,created_by_user_id)
values(current_setting('test.sync_profile')::uuid,current_setting('test.sync_workspace')::uuid,
       'Sync verification athlete',current_setting('test.sync_owner')::uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.sync_owner'),true);
do $test$
declare
  w uuid := current_setting('test.sync_workspace')::uuid;
  p uuid := current_setting('test.sync_profile')::uuid;
  record_key text := gen_random_uuid()::text;
  initial_row jsonb;
  first_result jsonb;
  changed_result jsonb;
  result jsonb;
  denied boolean := false;
begin
  initial_row := jsonb_build_object('id',record_key,'workout_date','2099-01-01',
    'created_at',1,'notes','initial','workspace_id',w,'athlete_profile_id',p);
  first_result := public.sync_apply_change('workout_days',record_key,w,p,null,initial_row);
  if first_result->>'applied' <> 'true' then raise exception 'Insert failed'; end if;
  changed_result := public.sync_apply_change('workout_days',record_key,w,p,first_result->'row',initial_row || '{"notes":"edited"}');
  if changed_result->>'applied' <> 'true' then raise exception 'Update failed'; end if;
  result := public.sync_apply_change('workout_days',record_key,w,p,first_result->'row',initial_row);
  if result->>'applied' <> 'false' or result->'row'->>'notes' <> 'edited' then raise exception 'Stale edit was not rejected'; end if;
  result := public.sync_apply_change('workout_days',record_key,w,p,changed_result->'row',null);
  if result->>'applied' <> 'true' then raise exception 'Deletion failed'; end if;
  result := public.sync_apply_change('workout_days',record_key,w,p,null,initial_row);
  if result->>'applied' <> 'false' then raise exception 'Deleted record was resurrected'; end if;
  result := public.sync_apply_change('workout_days',record_key,w,p,null,initial_row,true);
  if result->>'applied' <> 'true' then raise exception 'Explicit restore failed'; end if;
  begin
    perform public.sync_apply_change('workout_days',record_key,w,p,null,initial_row || '{"workspace_id":"00000000-0000-0000-0000-000000000000"}');
  exception when invalid_parameter_value then denied := true;
  end;
  if not denied then raise exception 'Identity mismatch was accepted'; end if;
  insert into public.plan_long_range_weeks(id,week_label,week_start,week_end,deload,source,created_at,updated_at,workspace_id,athlete_profile_id)
  values(record_key,'Verification week','2099-01-01','2099-01-07',false,'verification',1,1,w,p);
  perform set_config('request.jwt.claim.sub',current_setting('test.sync_outsider'),true);
  if exists(select 1 from public.plan_long_range_weeks where id=record_key) then raise exception 'Cross-profile read allowed'; end if;
  denied := false;
  begin
    perform public.sync_apply_change('workout_days',record_key,w,p,null,initial_row);
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'Cross-profile write allowed'; end if;
end;
$test$;
reset role;
do $test$
begin
  if has_function_privilege('anon','public.sync_apply_change(text,text,uuid,uuid,jsonb,jsonb,boolean)','execute') then
    raise exception 'Anonymous RPC access allowed';
  end if;
end;
$test$;
rollback;
select 'PASS: hosted sync checks; all verification fixtures rolled back' as verification;
