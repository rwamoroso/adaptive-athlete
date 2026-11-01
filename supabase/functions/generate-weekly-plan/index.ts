// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

type RequestBody = {
  request_id?: string;
  week_start?: string;
  week_end?: string;
  split_type?: string;
  modifier?: string;
  prompt_text?: string;
  planner_context?: Record<string, unknown>;
};

type StructuredStrengthSet = {
  exercise: string;
  set: number;
  weight: string;
  reps: number;
  rir: number;
  unit: "lb" | "kg" | "bw";
};

type StructuredAlternative = {
  prescribed_exercise: string;
  rank: number;
  exercise: string;
  tier: "strong" | "acceptable";
  rationale: string;
  notes: string;
};

type StructuredDay = {
  day_number: number;
  session_type:
    | "push"
    | "pull"
    | "legs"
    | "upper"
    | "lower"
    | "full_body"
    | "hybrid"
    | "conditioning"
    | "rest"
    | "unknown";
  day_label: string;
  lift_focus: string;
  run_type: string;
  run_duration: string;
  run_target_pace: string;
  run_hr_guardrails: string;
  run_notes: string;
  strength_sets: StructuredStrengthSet[];
  alternatives: StructuredAlternative[];
};

type StructuredTenWeekRow = {
  week: string;
  run_focus: string;
  strength_focus: string;
  strength_progression_expectation: string;
  primary_progression_target: string;
  recovery_emphasis: string;
  deload: boolean;
  notes: string;
};

type StructuredPlan = {
  week_start: string;
  week_end: string;
  days: StructuredDay[];
  ten_week_rows: StructuredTenWeekRow[];
  explanation: {
    why_this_week: string;
    adaptation_or_growth: string;
    logic_overview: string;
  };
};

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const ALLOW_WEEKLY_PLAN_FALLBACK =
  (Deno.env.get("ALLOW_WEEKLY_PLAN_FALLBACK")?.trim().toLowerCase() ?? "") ===
    "true";
const MAX_BODY_BYTES = 120_000;
const MAX_PROMPT_CHARS = 60_000;
const SPLIT_TYPES = new Set([
  "run_only",
  "full_body_3d",
  "upper_lower_4d",
  "ppl_5_6d",
  "phul",
  "arnold",
  "bro_split",
  "hybrid_run_lift",
  "custom_hybrid",
]);
const MODIFIERS = new Set([
  "follow_long_term",
  "light_week",
  "vacation_travel",
]);
const STRENGTH_SESSION_TYPES = new Set([
  "push",
  "pull",
  "legs",
  "upper",
  "lower",
  "full_body",
  "hybrid",
]);
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

function safeLogError(code: string, requestId: string, error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(code, {
    request_id: requestId,
    detail: message.slice(0, 500),
  });
}

function addDays(ymd: string, days: number): string {
  const date = new Date(`${ymd}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function isValidYmd(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value;
}

function safeField(value: unknown, maxLength = 240): string {
  return String(value ?? "")
    .replace(/[\r\n|=]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxLength);
}

function structuredPlanSchema(propagateLongTerm: boolean) {
  const text = { type: "string" };
  const strengthSet = {
    type: "object",
    additionalProperties: false,
    properties: {
      exercise: text,
      set: { type: "integer", minimum: 1, maximum: 12 },
      weight: text,
      reps: { type: "integer", minimum: 0, maximum: 100 },
      rir: { type: "integer", minimum: 0, maximum: 10 },
      unit: { type: "string", enum: ["lb", "kg", "bw"] },
    },
    required: ["exercise", "set", "weight", "reps", "rir", "unit"],
  };
  const alternative = {
    type: "object",
    additionalProperties: false,
    properties: {
      prescribed_exercise: text,
      rank: { type: "integer", minimum: 1, maximum: 5 },
      exercise: text,
      tier: { type: "string", enum: ["strong", "acceptable"] },
      rationale: text,
      notes: text,
    },
    required: [
      "prescribed_exercise",
      "rank",
      "exercise",
      "tier",
      "rationale",
      "notes",
    ],
  };
  const day = {
    type: "object",
    additionalProperties: false,
    properties: {
      day_number: { type: "integer", minimum: 1, maximum: 7 },
      session_type: {
        type: "string",
        enum: [
          "push",
          "pull",
          "legs",
          "upper",
          "lower",
          "full_body",
          "hybrid",
          "conditioning",
          "rest",
          "unknown",
        ],
      },
      day_label: text,
      lift_focus: text,
      run_type: text,
      run_duration: text,
      run_target_pace: text,
      run_hr_guardrails: text,
      run_notes: text,
      strength_sets: { type: "array", items: strengthSet, maxItems: 60 },
      alternatives: { type: "array", items: alternative, maxItems: 40 },
    },
    required: [
      "day_number",
      "session_type",
      "day_label",
      "lift_focus",
      "run_type",
      "run_duration",
      "run_target_pace",
      "run_hr_guardrails",
      "run_notes",
      "strength_sets",
      "alternatives",
    ],
  };
  const tenWeekRow = {
    type: "object",
    additionalProperties: false,
    properties: {
      week: text,
      run_focus: text,
      strength_focus: text,
      strength_progression_expectation: text,
      primary_progression_target: text,
      recovery_emphasis: text,
      deload: { type: "boolean" },
      notes: text,
    },
    required: [
      "week",
      "run_focus",
      "strength_focus",
      "strength_progression_expectation",
      "primary_progression_target",
      "recovery_emphasis",
      "deload",
      "notes",
    ],
  };
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      week_start: text,
      week_end: text,
      days: { type: "array", items: day, minItems: 7, maxItems: 7 },
      ten_week_rows: {
        type: "array",
        items: tenWeekRow,
        minItems: propagateLongTerm ? 10 : 0,
        maxItems: propagateLongTerm ? 10 : 0,
      },
      explanation: {
        type: "object",
        additionalProperties: false,
        properties: {
          why_this_week: text,
          adaptation_or_growth: text,
          logic_overview: text,
        },
        required: [
          "why_this_week",
          "adaptation_or_growth",
          "logic_overview",
        ],
      },
    },
    required: [
      "week_start",
      "week_end",
      "days",
      "ten_week_rows",
      "explanation",
    ],
  };
}

function extractResponseText(payload: any): string | null {
  if (typeof payload?.output_text === "string" && payload.output_text.trim()) {
    return payload.output_text.trim();
  }
  if (!Array.isArray(payload?.output)) return null;
  const chunks: string[] = [];
  for (const item of payload.output) {
    if (!Array.isArray(item?.content)) continue;
    for (const content of item.content) {
      if (content?.type === "output_text" && typeof content.text === "string") {
        chunks.push(content.text);
      }
      if (content?.type === "refusal") {
        throw new Error("model_refused_request");
      }
    }
  }
  const joined = chunks.join("").trim();
  return joined || null;
}

function renderPlanText(
  plan: StructuredPlan,
  input: Required<Pick<RequestBody, "week_start" | "week_end" | "split_type">>,
  propagateLongTerm: boolean,
): string {
  if (!Array.isArray(plan.days) || plan.days.length !== 7) {
    throw new Error("structured_plan_must_have_seven_days");
  }
  const byDay = new Map<number, StructuredDay>();
  for (const day of plan.days) {
    if (!Number.isInteger(day.day_number) || day.day_number < 1 ||
      day.day_number > 7 || byDay.has(day.day_number)) {
      throw new Error("structured_plan_has_invalid_day_numbers");
    }
    byDay.set(day.day_number, day);
  }

  const lines: string[] = [];
  if (propagateLongTerm) {
    if (!Array.isArray(plan.ten_week_rows) || plan.ten_week_rows.length !== 10) {
      throw new Error("structured_plan_must_have_ten_long_range_rows");
    }
    lines.push("TEN_WEEK_PLAN_UPDATE_V1");
    plan.ten_week_rows.forEach((row, index) => {
      const start = addDays(input.week_start, index * 7);
      const end = addDays(start, 6);
      const requiredText = [
        row.run_focus,
        row.strength_focus,
        row.strength_progression_expectation,
        row.primary_progression_target,
        row.recovery_emphasis,
      ].map((value) => safeField(value));
      if (requiredText.some((value) => !value)) {
        throw new Error("structured_plan_has_empty_long_range_fields");
      }
      lines.push(
        `TEN_WEEK_ROW: week=${safeField(row.week) || `Week ${index + 1}`} | ` +
          `week_start=${start} | week_end=${end} | ` +
          `run_focus=${requiredText[0]} | strength_focus=${requiredText[1]} | ` +
          `strength_progression_expectation=${requiredText[2]} | ` +
          `primary_progression_target=${requiredText[3]} | ` +
          `recovery_emphasis=${requiredText[4]} | ` +
          `deload=${row.deload ? "yes" : "no"} | notes=${safeField(row.notes)}`,
      );
    });
    lines.push("END_TEN_WEEK_PLAN_UPDATE_V1", "");
  }

  lines.push(
    "WEEK_PLAN_V1",
    `WEEK_START: ${input.week_start}`,
    `WEEK_END: ${input.week_end}`,
    "",
  );

  for (let dayNumber = 1; dayNumber <= 7; dayNumber++) {
    const day = byDay.get(dayNumber)!;
    const sets = input.split_type === "run_only" ? [] : day.strength_sets;
    const alternatives = input.split_type === "run_only" ? [] : day.alternatives;
    const exercises = new Set<string>();
    const setKeys = new Set<string>();
    for (const set of sets) {
      const exercise = safeField(set.exercise);
      const unit = set.unit;
      if (!exercise || !["lb", "kg", "bw"].includes(unit)) {
        throw new Error("structured_plan_has_invalid_strength_set");
      }
      const weight = unit === "bw" ? "bw" : String(Number(set.weight));
      if (unit !== "bw" && (!Number.isFinite(Number(set.weight)) ||
        Number(set.weight) < 0)) {
        throw new Error("structured_plan_has_invalid_strength_weight");
      }
      const normalizedExercise = exercise.toLowerCase();
      const setKey = `${normalizedExercise}:${set.set}`;
      if (!setKeys.add(setKey)) {
        throw new Error("structured_plan_has_duplicate_strength_set");
      }
      exercises.add(normalizedExercise);
      set.exercise = exercise;
      set.weight = weight;
    }
    if (STRENGTH_SESSION_TYPES.has(day.session_type) && exercises.size < 4) {
      throw new Error("structured_plan_strength_day_needs_four_exercises");
    }

    const altExercises = new Set<string>();
    const altRanks = new Set<string>();
    for (const alt of alternatives) {
      const prescribed = safeField(alt.prescribed_exercise).toLowerCase();
      const alternative = safeField(alt.exercise).toLowerCase();
      if (!prescribed || !alternative || !exercises.has(prescribed)) {
        throw new Error("structured_plan_alternative_has_unknown_exercise");
      }
      const pairKey = `${prescribed}:${alternative}`;
      const rankKey = `${prescribed}:${alt.rank}`;
      if (!altExercises.add(pairKey) || !altRanks.add(rankKey)) {
        throw new Error("structured_plan_has_duplicate_alternative");
      }
    }
    for (const exercise of exercises) {
      if (![...altExercises].some((key) => key.startsWith(`${exercise}:`))) {
        throw new Error("structured_plan_exercise_needs_alternative");
      }
    }

    lines.push(
      `DAY ${dayNumber}`,
      `SESSION_TYPE: ${day.session_type}`,
      `DAY_LABEL: ${safeField(day.day_label)}`,
      `LIFT_FOCUS: ${safeField(day.lift_focus)}`,
      `RUN_TYPE: ${safeField(day.run_type)}`,
      `RUN_DURATION: ${safeField(day.run_duration)}`,
      `RUN_TARGET_PACE: ${safeField(day.run_target_pace)}`,
      `RUN_HR_GUARDRAILS: ${safeField(day.run_hr_guardrails)}`,
      `RUN_NOTES: ${safeField(day.run_notes, 500)}`,
    );
    for (const set of sets) {
      lines.push(
        `STRENGTH_SET: ${safeField(set.exercise)} | set=${set.set} | ` +
          `weight=${set.weight} | reps=${set.reps} | rir=${set.rir} | unit=${set.unit}`,
      );
    }
    for (const alt of alternatives) {
      lines.push(
        `ALT: ${safeField(alt.prescribed_exercise)} | rank=${alt.rank} | ` +
          `exercise=${safeField(alt.exercise)} | tier=${alt.tier} | ` +
          `rationale=${safeField(alt.rationale)} | notes=${safeField(alt.notes)}`,
      );
    }
    lines.push(`END DAY ${dayNumber}`, "");
  }

  lines.push(
    "PLAN_EXPLANATION_V1",
    `WHY_THIS_WEEK: ${safeField(plan.explanation.why_this_week, 800)}`,
    `ADAPTATION_OR_GROWTH: ${safeField(plan.explanation.adaptation_or_growth, 800)}`,
    `LOGIC_OVERVIEW: ${safeField(plan.explanation.logic_overview, 800)}`,
    "END_PLAN_EXPLANATION_V1",
  );
  return lines.join("\n");
}

function fallbackWeekPlanText(
  input: Required<Pick<RequestBody, "week_start" | "week_end" | "split_type" | "modifier">>,
): string {
  const sessionsBySplit: Record<string, string[]> = {
    run_only: ["conditioning", "conditioning", "rest", "conditioning", "rest", "conditioning", "rest"],
    full_body_3d: ["full_body", "rest", "full_body", "rest", "full_body", "conditioning", "rest"],
    upper_lower_4d: ["upper", "lower", "rest", "upper", "lower", "conditioning", "rest"],
    ppl_5_6d: ["push", "pull", "legs", "rest", "push", "pull", "rest"],
    phul: ["upper", "lower", "rest", "upper", "lower", "conditioning", "rest"],
    arnold: ["push", "pull", "legs", "rest", "push", "pull", "rest"],
    bro_split: ["push", "pull", "legs", "upper", "lower", "rest", "rest"],
    hybrid_run_lift: ["hybrid", "conditioning", "upper", "rest", "lower", "conditioning", "rest"],
    custom_hybrid: ["hybrid", "upper", "conditioning", "rest", "lower", "conditioning", "rest"],
  };
  const sessions = sessionsBySplit[input.split_type] ?? sessionsBySplit.ppl_5_6d;
  const exercises = [
    ["incline_dumbbell_press", "machine_chest_press"],
    ["cable_row", "chest_supported_row"],
    ["goblet_squat", "leg_press"],
    ["romanian_deadlift", "cable_pull_through"],
  ];
  const lines = [
    "WEEK_PLAN_V1",
    `WEEK_START: ${input.week_start}`,
    `WEEK_END: ${input.week_end}`,
    "",
  ];
  sessions.forEach((session, index) => {
    const active = session !== "rest";
    lines.push(
      `DAY ${index + 1}`,
      `SESSION_TYPE: ${session}`,
      `DAY_LABEL: Day ${index + 1} (${addDays(input.week_start, index)})`,
      `LIFT_FOCUS: ${input.split_type === "run_only" ? "" : session}`,
      `RUN_TYPE: ${active ? "easy_run" : ""}`,
      `RUN_DURATION: ${active ? "30 min" : ""}`,
      "RUN_TARGET_PACE:",
      `RUN_HR_GUARDRAILS: ${active ? "Comfortable conversational effort" : ""}`,
      `RUN_NOTES: ${input.modifier === "light_week" ? "Keep effort light." : "Adjust effort to readiness."}`,
    );
    if (active && input.split_type !== "run_only" &&
      STRENGTH_SESSION_TYPES.has(session)) {
      exercises.forEach(([exercise, alternative]) => {
        lines.push(
          `STRENGTH_SET: ${exercise} | set=1 | weight=0 | reps=8 | rir=3 | unit=lb`,
          `STRENGTH_SET: ${exercise} | set=2 | weight=0 | reps=8 | rir=3 | unit=lb`,
          `ALT: ${exercise} | rank=1 | exercise=${alternative} | tier=strong | rationale=Similar movement pattern | notes=Choose the pain-free option`,
        );
      });
    }
    lines.push(`END DAY ${index + 1}`, "");
  });
  lines.push(
    "PLAN_EXPLANATION_V1",
    "WHY_THIS_WEEK: A conservative plan matched to the requested schedule.",
    "ADAPTATION_OR_GROWTH: Builds consistent training tolerance.",
    "LOGIC_OVERVIEW: Alternate training and recovery while keeping effort adjustable.",
    "END_PLAN_EXPLANATION_V1",
  );
  return lines.join("\n");
}

async function callOpenAiStructured(
  input: Required<RequestBody>,
  propagateLongTerm: boolean,
): Promise<{ plan: StructuredPlan; responseId: string | null }> {
  const apiKey = Deno.env.get("OPENAI_API_KEY")?.trim();
  if (!apiKey) throw new Error("openai_not_configured");
  const model = Deno.env.get("OPENAI_MODEL")?.trim() || "gpt-4o-mini";
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      store: false,
      max_output_tokens: 12_000,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text:
                "You are a conservative training-plan assistant. Follow the supplied athlete context and safety constraints. Produce the requested structured object. Do not make medical claims. Use empty strings where a cardio or strength field does not apply. Every strength day needs at least four unique exercises, every strength set needs an explicit load, and every prescribed exercise needs at least one same-day alternative. The dates and day numbers must match the request.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: input.prompt_text.trim() ||
                `Build the week ${input.week_start} through ${input.week_end} using split ${input.split_type} and modifier ${input.modifier}. Context: ${JSON.stringify(input.planner_context)}`,
            },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "adaptive_athlete_week_plan_v2",
          strict: true,
          schema: structuredPlanSchema(propagateLongTerm),
        },
      },
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`openai_http_${response.status}:${body.slice(0, 300)}`);
  }
  const payload = await response.json();
  if (payload?.status === "incomplete") {
    throw new Error(`openai_incomplete:${payload?.incomplete_details?.reason ?? "unknown"}`);
  }
  const outputText = extractResponseText(payload);
  if (!outputText) throw new Error("openai_empty_output");
  let plan: StructuredPlan;
  try {
    plan = JSON.parse(outputText) as StructuredPlan;
  } catch {
    throw new Error("openai_invalid_structured_json");
  }
  return {
    plan,
    responseId: typeof payload?.id === "string" ? payload.id : null,
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const authHeader = req.headers.get("Authorization")?.trim() ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return jsonResponse(401, { error: "authentication_required" });
  }
  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) {
    return jsonResponse(413, { error: "request_too_large" });
  }

  let body: RequestBody;
  try {
    const rawBody = await req.text();
    if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
      return jsonResponse(413, { error: "request_too_large" });
    }
    body = JSON.parse(rawBody) as RequestBody;
  } catch {
    return jsonResponse(400, { error: "invalid_json" });
  }

  // Older installed clients did not send an idempotency key. Keep those
  // versions working while all new clients provide a stable UUID per attempt.
  const requestId = body.request_id?.trim() || crypto.randomUUID();
  const weekStart = body.week_start?.trim() ?? "";
  const weekEnd = body.week_end?.trim() ?? "";
  const splitType = body.split_type?.trim() ?? "";
  const modifier = body.modifier?.trim() ?? "";
  const promptText = body.prompt_text?.trim() ?? "";
  const plannerContext = body.planner_context ?? {};
  const profile = (plannerContext.profile ?? {}) as Record<string, unknown>;
  const workspaceId = String(profile.workspace_id ?? "").trim();
  const profileId = String(profile.athlete_profile_id ?? "").trim();
  const propagateLongTerm = plannerContext.propagate_long_term_changes === true;

  if (!UUID_PATTERN.test(requestId) || !UUID_PATTERN.test(workspaceId) ||
    !UUID_PATTERN.test(profileId)) {
    return jsonResponse(400, { error: "invalid_request_scope" });
  }
  if (!isValidYmd(weekStart) || !isValidYmd(weekEnd) ||
    addDays(weekStart, 6) !== weekEnd) {
    return jsonResponse(400, { error: "invalid_week_range" });
  }
  if (!SPLIT_TYPES.has(splitType) || !MODIFIERS.has(modifier)) {
    return jsonResponse(400, { error: "invalid_planner_option" });
  }
  if (promptText.length > MAX_PROMPT_CHARS) {
    return jsonResponse(413, { error: "prompt_too_large" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")?.trim();
  if (!supabaseUrl || !supabaseAnonKey) {
    return jsonResponse(503, { error: "service_not_configured" });
  }
  const token = authHeader.replace(/^Bearer\s+/i, "");
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await supabase.auth.getUser(token);
  if (userError || !userData.user) {
    return jsonResponse(401, { error: "invalid_session" });
  }

  const { data: reservationData, error: reservationError } = await supabase.rpc(
    "reserve_planner_generation",
    {
      p_request_id: requestId,
      p_workspace: workspaceId,
      p_profile: profileId,
    },
  );
  if (reservationError) {
    safeLogError("planner_reservation_failed", requestId, reservationError);
    const unauthorized = reservationError.code === "42501";
    return jsonResponse(unauthorized ? 403 : 503, {
      error: unauthorized ? "profile_access_denied" : "quota_service_unavailable",
    });
  }
  const reservation = reservationData as Record<string, unknown>;
  if (reservation?.allowed !== true) {
    if (reservation?.idempotent === true) {
      return jsonResponse(409, {
        error: "duplicate_request",
        status: String(reservation.status ?? "reserved"),
      });
    }
    return jsonResponse(429, {
      error: "planner_quota_exceeded",
      retry_after_seconds: Number(reservation?.retry_after_seconds ?? 3600),
    });
  }

  const complete = async (status: "completed" | "failed", code?: string) => {
    const { error } = await supabase.rpc("complete_planner_generation", {
      p_request_id: requestId,
      p_status: status,
      p_error_code: code ?? null,
    });
    if (error) safeLogError("planner_completion_failed", requestId, error);
  };

  const normalizedInput: Required<RequestBody> = {
    request_id: requestId,
    week_start: weekStart,
    week_end: weekEnd,
    split_type: splitType,
    modifier,
    prompt_text: promptText,
    planner_context: plannerContext,
  };

  try {
    let planText: string;
    let generatedBy: "openai_structured" | "fallback" = "openai_structured";
    let providerResponseId: string | null = null;
    try {
      const generated = await callOpenAiStructured(
        normalizedInput,
        propagateLongTerm,
      );
      planText = renderPlanText(
        generated.plan,
        normalizedInput,
        propagateLongTerm,
      );
      providerResponseId = generated.responseId;
    } catch (error) {
      safeLogError("planner_provider_failed", requestId, error);
      if (!ALLOW_WEEKLY_PLAN_FALLBACK || propagateLongTerm) {
        await complete("failed", "provider_generation_failed");
        return jsonResponse(502, { error: "planner_generation_failed" });
      }
      planText = fallbackWeekPlanText(normalizedInput);
      generatedBy = "fallback";
    }

    await complete("completed");
    return jsonResponse(200, {
      plan_text: planText,
      week_start: weekStart,
      week_end: weekEnd,
      split_type: splitType,
      modifier,
      generated_by: generatedBy,
      contract_version: "adaptive_athlete_week_plan_v2",
      request_id: requestId,
      provider_response_id: providerResponseId,
    });
  } catch (error) {
    safeLogError("generate_weekly_plan_error", requestId, error);
    await complete("failed", "internal_error");
    return jsonResponse(500, { error: "internal_error" });
  }
});
