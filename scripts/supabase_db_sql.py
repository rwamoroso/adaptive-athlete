#!/usr/bin/env python3
"""Run SQL against Supabase Postgres using a local gitignored env file.

Usage examples:
  scripts/supabase_db_sql.py --file supabase/schema.sql
  scripts/supabase_db_sql.py --query "select now();"
  scripts/supabase_db_sql.py --verify-sync
"""

from __future__ import annotations

import argparse
import os
import pathlib
import sys


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
ENV_PATH = REPO_ROOT / "scripts" / "supabase_db.env"


def load_env_file(path: pathlib.Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


def get_conn_str() -> str:
    load_env_file(ENV_PATH)
    conn_str = os.environ.get("SUPABASE_DB_URL", "").strip()
    if not conn_str:
        print(
            "Missing SUPABASE_DB_URL. Create scripts/supabase_db.env from "
            "scripts/supabase_db.env.example or export SUPABASE_DB_URL.",
            file=sys.stderr,
        )
        sys.exit(2)
    if "sslmode=" not in conn_str:
        separator = "&" if "?" in conn_str else "?"
        conn_str = f"{conn_str}{separator}sslmode=require"
    return conn_str


def import_psycopg():
    try:
        import psycopg  # type: ignore
    except ModuleNotFoundError:
        print(
            "Missing dependency 'psycopg'. Install with:\n"
            "  python3 -m pip install --user 'psycopg[binary]'",
            file=sys.stderr,
        )
        sys.exit(2)
    return psycopg


def run_sql(conn, sql: str) -> None:
    with conn.cursor() as cur:
        cur.execute(sql, prepare=False)


def verify_sync(conn) -> None:
    checks = [
        ("plan_exercise_alternatives",),
        ("exercise_substitutions",),
        ("plan_import_audit",),
    ]
    with conn.cursor() as cur:
        cur.execute(
            """
            select
              to_regclass('public.plan_exercise_alternatives')::text,
              to_regclass('public.exercise_substitutions')::text
            """
        )
        tables = cur.fetchone()
        print("tables:", tables)

        cur.execute(
            """
            select tablename, policyname, cmd
            from pg_policies
            where schemaname = 'public'
              and tablename in ('plan_exercise_alternatives', 'exercise_substitutions', 'plan_import_audit')
            order by tablename, policyname
            """
        )
        rows = cur.fetchall()
        print("policies:")
        for row in rows:
            print(f"  {row[0]} | {row[1]} | {row[2]}")

        cur.execute(
            """
            select
              (select count(*) from public.plan_exercise_alternatives),
              (select count(*) from public.exercise_substitutions)
            """
        )
        counts = cur.fetchone()
        print("row_counts:", counts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", help="SQL file to execute")
    parser.add_argument("--query", help="Ad hoc SQL query to execute")
    parser.add_argument(
        "--verify-sync",
        action="store_true",
        help="Verify substitute tables/policies and print row counts",
    )
    args = parser.parse_args()

    if not any([args.file, args.query, args.verify_sync]):
        parser.error("Provide --file, --query, or --verify-sync")

    psycopg = import_psycopg()
    conn_str = get_conn_str()
    conn = psycopg.connect(conn_str, autocommit=True)
    try:
        if args.file:
            sql = pathlib.Path(args.file).read_text()
            run_sql(conn, sql)
            print(f"Executed {args.file}")
        if args.query:
            with conn.cursor() as cur:
                cur.execute(args.query, prepare=False)
                if cur.description:
                    rows = cur.fetchall()
                    for row in rows:
                        print(row)
                else:
                    print("Query executed")
        if args.verify_sync:
            verify_sync(conn)
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
