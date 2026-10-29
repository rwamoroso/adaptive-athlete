import { fileURLToPath } from 'node:url';
const { PGlite } = await import(process.argv[2] ?? '@electric-sql/pglite');
import fs from 'node:fs';
import assert from 'node:assert/strict';
const root=fileURLToPath(new URL('..',import.meta.url));
const db = new PGlite();
await db.exec(`create role authenticated; create role anon; create role service_role bypassrls;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create function auth.jwt() returns jsonb language sql stable as $$select '{}'::jsonb$$;
grant usage on schema auth, public to authenticated, anon;
grant execute on all functions in schema auth to authenticated, anon;`);
await db.exec(fs.readFileSync(root+'/supabase/schema.sql','utf8').replace(/create extension if not exists pgcrypto;/i,''));
await db.exec(fs.readFileSync(root+'/supabase/migrations/'+fs.readdirSync(root+'/supabase/migrations').find(name=>name.endsWith('_reliable_sync_and_long_range_backup.sql')),'utf8'));
await db.exec(`insert into public.workspaces(id,name,created_by_user_id) values
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Review A','11111111-1111-1111-1111-111111111111'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','Review B','22222222-2222-2222-2222-222222222222');
insert into public.workspace_memberships(workspace_id,user_id,user_email,role,status,created_by_user_id) values
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','a@example.invalid','owner','active','11111111-1111-1111-1111-111111111111'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','22222222-2222-2222-2222-222222222222','b@example.invalid','owner','active','22222222-2222-2222-2222-222222222222');
insert into public.athlete_profiles(id,workspace_id,name,created_by_user_id) values
('aaaaaaaa-1111-1111-1111-111111111111','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Athlete A','11111111-1111-1111-1111-111111111111'),
('bbbbbbbb-2222-2222-2222-222222222222','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','Athlete B','22222222-2222-2222-2222-222222222222');
grant select,insert,update,delete on all tables in schema public to authenticated;
set role authenticated;
set request.jwt.claim.sub='11111111-1111-1111-1111-111111111111';`);
const workspace='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',profile='aaaaaaaa-1111-1111-1111-111111111111';
const apply=async (expected,next,restore=false,ws=workspace,p=profile,table='workout_days',key='review-day')=>
 (await db.query('select public.sync_apply_change($1,$2,$3,$4,$5,$6,$7) as result',[table,key,ws,p,expected,next,restore])).rows[0].result;
const row={id:'review-day',workout_date:'2026-10-29',created_at:1,notes:'first',workspace_id:workspace,athlete_profile_id:profile};
const inserted=await apply(null,row);assert.equal(inserted.applied,true);
const edited=await apply(inserted.row,{...row,notes:'new'});assert.equal(edited.applied,true);
const conflict=await apply(inserted.row,{...row,notes:'stale edit'});assert.equal(conflict.applied,false);assert.equal(conflict.row.notes,'new');
assert.equal((await apply(edited.row,null)).applied,true);
assert.equal((await apply(null,row)).applied,false);
assert.equal((await apply(null,row,true)).applied,true);
let denied=false;try{await apply(null,{...row,workspace_id:'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',athlete_profile_id:'bbbbbbbb-2222-2222-2222-222222222222'},false,'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','bbbbbbbb-2222-2222-2222-222222222222');}catch(e){denied=e.code==='42501'}assert.equal(denied,true);
let mismatch=false;try{await apply(null,{...row,athlete_profile_id:'bbbbbbbb-2222-2222-2222-222222222222'})}catch(e){mismatch=e.code==='22023'}assert.equal(mismatch,true);
await db.query(`insert into public.plan_long_range_weeks(id,week_label,week_start,week_end,deload,source,created_at,updated_at,workspace_id,athlete_profile_id) values('week','Week 1','2026-10-26','2026-11-01',false,'review',1,1,$1,$2)`,[workspace,profile]);
await db.exec(`set request.jwt.claim.sub='22222222-2222-2222-2222-222222222222'`);
assert.equal((await db.query('select * from public.plan_long_range_weeks')).rows.length,0);
await db.exec('reset role; set role anon');
let anonDenied=false;try{await apply(null,row)}catch(e){anonDenied=e.code==='42501'}assert.equal(anonDenied,true);
console.log('PASS: insert, update, stale-write rejection, deletion, tombstone, explicit restore, denied profile write, identity validation, cross-profile RLS, anonymous denial');
await db.exec('reset role');
await db.exec(fs.readFileSync(root+'/supabase/tests/reliable_sync.sql','utf8'));
console.log('PASS: rollback-only hosted verification SQL');
await db.close();
