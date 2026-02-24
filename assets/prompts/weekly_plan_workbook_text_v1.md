# Adaptive Athlete Weekly Plan Prompt (Workbook-Compatible Text, v1)

You are generating a 7-day weekly training plan for Adaptive Athlete.

Goal:
- Produce a structured weekly plan that can be copied into the app workflow.
- Include prescribed run details and prescribed strength sets.
- For every strength exercise, include a ranked list of adequate alternatives that preserve plan intent.

Priorities:
1. Preserve movement pattern.
2. Preserve primary muscle emphasis.
3. Preserve rep/RIR intent.
4. Respect available equipment.
5. Respect contraindications / pain triggers.
6. Prefer safe, sustainable progression.

Definitions:
- "Adequate alternative" means the substitute still matches the intended movement pattern and muscle focus, and supports the prescribed rep/RIR intent.
- If no strong alternative exists, provide weaker alternatives but mark them clearly and explain the compromise.

Use these inputs (provided by the user/app context):
- Athlete context
- Available equipment
- Contraindications / pain triggers
- Recovery status / sleep context
- Weekly goals (performance + health)
- Start date for Day 1

Output format (Workbook-Compatible Text, v1):

WEEK_PLAN_V1
WEEK_START: YYYY-MM-DD
WEEK_END: YYYY-MM-DD

DAY 1
SESSION_TYPE: push|pull|legs|rest|unknown
DAY_LABEL: <short label>
LIFT_FOCUS: <text>
RUN_TYPE: <text or blank>
RUN_DURATION: <text or blank>
RUN_TARGET_PACE: <text or blank>
RUN_HR_GUARDRAILS: <text or blank>
RUN_NOTES: <text or blank>
STRENGTH_SET: <exercise_canonical> | set=<n> | weight=<number or blank> | reps=<number or blank> | rir=<number or blank> | unit=lb|kg|bw|unknown
STRENGTH_SET: ...
ALT: <prescribed_exercise_canonical> | rank=<1..N> | exercise=<alternative_exercise_canonical> | tier=strong|acceptable|weak | rationale=<short reason> | notes=<optional>
ALT: ...
END DAY 1

DAY 2
...
END DAY 2

Repeat through DAY 7.

Rules for alternatives (required):
- Provide a ranked list for every prescribed strength exercise.
- Default to 3 alternatives per exercise when feasible.
- Include `tier`:
  - strong = preserves movement pattern + primary muscle emphasis + rep intent
  - acceptable = minor compromise but still suitable
  - weak = larger compromise; only if necessary
- If an exercise has no safe alternative, still include one ALT row with:
  - tier=weak
  - rationale explaining why no strong/acceptable option is available

Canonical naming:
- Use normalized/canonical exercise names consistently (snake_case style if applicable).
- Do not rename the same exercise differently across set rows and ALT rows.

Quality constraints:
- Keep output deterministic and parse-friendly.
- Do not include prose outside the specified line format.
- Do not omit any day (1-7).
- Do not omit ALT rows for strength exercises.

