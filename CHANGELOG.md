# Changelog

## Unreleased

- Import Apple Health workouts and use reliable incremental cloud sync.
- Make recovery and workout history flows safer during database operations.
- Validate ten-week plans across daylight-saving changes and correct weekly
  plan date propagation and generation.

## 1.1.0 — 2026-10-29

- Preserve unsynced edits and review concurrent device/cloud changes in Settings.
- Reject stale cloud writes atomically; sync deletions without resurrecting them.
- Back up and restore ten-week plans and weekly performance across devices.
- Require successful backup before switching athlete profiles.
- Keep bikes, stair sessions, and other cardio out of running mileage and pace.
- Persist device preferences and the account's last successful cloud-sync time.
- Avoid redundant database initialization and callbacks after leaving sign-in.
- Check planner responses before applying; provide actionable validation and retry controls.
- Report on-device saves and cloud-sync completion separately.
- Show the installed build and release notes; improve compact iPhone metric tiles.
