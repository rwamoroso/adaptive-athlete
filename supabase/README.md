# Supabase development workflow

`schema.sql` is the legacy bootstrap script for the existing hosted project. Do
not copy it into a timestamped migration by hand: the hosted database may
contain migration history or dashboard changes that are not represented here.

## Establish the migration baseline

1. Install the current Supabase CLI and a Docker-compatible runtime.
2. Authenticate and link this repository to the intended development project.
3. Run `supabase db pull` to generate the baseline under
   `supabase/migrations/` and record the remote schema accurately.
4. Review every generated statement, then run `supabase db reset` against the
   local stack to prove the baseline can recreate the database.
5. Run `supabase migration list` and commit the generated baseline together
   with any schema documentation updates.

After the baseline exists, create changes with
`supabase migration new <descriptive-name>`, verify them locally with
`supabase db reset`, and run database advisors before pushing.

## Security review required during baselining

The current bootstrap contains `security definer` functions in the exposed
`public` schema. During the baseline migration, review each function and:

- prefer `security invoker` when elevated privileges are unnecessary;
- move private authorization helpers to an unexposed schema where practical;
- use an empty `search_path` and fully qualified object names for any function
  that must remain `security definer`;
- explicitly control execute grants for RPC functions;
- retain and test both allowed and denied RLS cases for every role.

Do not apply these changes directly to production before testing the generated
migrations against a local or staging database.

## Applied reliability upgrade

`migrations/20261029184026_reliable_sync_and_long_range_backup.sql` is the focused,
additive upgrade applied to the hosted project. It adds long-range plan/performance
storage, scoped deletion tombstones, two previously local-only strength fields,
and the `sync_apply_change` RPC. The legacy bootstrap includes this upgrade too.
The migration directory is not yet a complete baseline for rebuilding older tables;
follow the baseline procedure above before using `supabase db reset` on a new stack.

`migrations/20261029225153_security_planner_incremental_sync.sql` is the
follow-up security and incremental-sync upgrade. It removes direct domain-table
mutation grants, makes the compare-and-set RPC the authenticated write boundary,
adds a metadata-only change cursor, restricts profile/bootstrap visibility,
hardens invite and email-binding RPCs, and adds per-user planner reservations and
rate limits. The matching planner Edge Function uses authenticated structured
generation and stores no prompt or generated-plan body in the quota table.

The RPC is `security invoker` with an empty search path. It accepts an allowlist of
collections, verifies record/profile identity and edit permissions, locks the record,
and checks the expected cloud snapshot before changing it. New tables enable RLS
with separate read and edit policies and explicit authenticated grants. Anonymous
callers cannot execute the RPC. No service-role key belongs in the app.

### Verify without changing saved records

`tests/reliable_sync.sql` runs against the hosted or local database as its owner.
It checks conditional writes, stale edits, deletion/restore, profile isolation,
and anonymous denial. Its fixtures are always enclosed in a rollback transaction.

For an isolated PostgreSQL check without Docker:

```sh
npm install --prefix /tmp/adaptive-db-check @electric-sql/pglite
node scripts/verify_sync_database.mjs /tmp/adaptive-db-check/node_modules/@electric-sql/pglite/dist/index.js
```

This uses an in-memory PostgreSQL instance, creates local auth test helpers, runs
the bootstrap and every checked-in migration, and exercises the permission,
incremental cursor, quota, and merge checks.
It never reads database credentials or connects to the hosted project.
