// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

type RequestBody = {
  week_start?: string;
  week_end?: string;
  split_type?: string;
  modifier?: string;
  prompt_text?: string;
  planner_context?: Record<string, unknown>;
};

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ALLOW_WEEKLY_PLAN_FALLBACK =
  (Deno.env.get("ALLOW_WEEKLY_PLAN_FALLBACK")?.trim().toLowerCase() ?? "") ===
  "true";

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json",
    },
  });
}

function summarizeError(err: unknown): string {
  const raw = err instanceof Error ? err.message : String(err ?? "unknown");
  return raw.length <= 600 ? raw : `${raw.slice(0, 600)}...`;
}

function ymdAdd(start: string, offset: number): string {
  const date = new Date(`${start}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + offset);
  return date.toISOString().slice(0, 10);
}

function fallbackWeekPlanText(input: Required<Pick<RequestBody, "week_start" | "week_end" | "split_type" | "modifier">>): string {
  const lines: string[] = [];
  lines.push("WEEK_PLAN_V1");
  lines.push(`WEEK_START: ${input.week_start}`);
  lines.push(`WEEK_END: ${input.week_end}`);
  lines.push("");

  const splitHints: Record<string, string[]> = {
    full_body_3d: ["full_body", "rest", "full_body", "rest", "full_body", "conditioning", "rest"],
    upper_lower_4d: ["upper", "lower", "rest", "upper", "lower", "conditioning", "rest"],
    ppl_5_6d: ["push", "pull", "legs", "rest", "push", "pull", "rest"],
    phul: ["upper", "lower", "rest", "upper", "lower", "conditioning", "rest"],
    arnold: ["push", "pull", "legs", "rest", "push", "pull", "rest"],
    bro_split: ["push", "pull", "legs", "upper", "lower", "rest", "rest"],
    hybrid_run_lift: ["hybrid", "conditioning", "upper", "rest", "lower", "conditioning", "rest"],
    custom_hybrid: ["hybrid", "upper", "conditioning", "rest", "lower", "conditioning", "rest"],
  };
  const sessions = splitHints[input.split_type] ?? splitHints.ppl_5_6d;

  const modifierNotes = input.modifier === "light_week"
    ? "Light week: reduce volume/intensity and prioritize recovery."
    : input.modifier === "vacation_travel"
    ? "Vacation/travel week: minimal equipment and shorter sessions."
    : "Follow long-term plan progression with evidence-based adjustments.";

  const daySets = [
    "STRENGTH_SET: incline_dumbbell_press | set=1 | weight=50 | reps=8 | rir=2 | unit=lb",
    "STRENGTH_SET: incline_dumbbell_press | set=2 | weight=50 | reps=8 | rir=2 | unit=lb",
    "STRENGTH_SET: cable_row | set=1 | weight=100 | reps=10 | rir=2 | unit=lb",
    "STRENGTH_SET: cable_row | set=2 | weight=100 | reps=10 | rir=2 | unit=lb",
    "ALT: incline_dumbbell_press | rank=1 | exercise=machine_chest_press | tier=strong | rationale=similar_pressing_pattern | notes=stable_setup",
    "ALT: incline_dumbbell_press | rank=2 | exercise=push_up | tier=acceptable | rationale=bodyweight_pressing_option | notes=travel_friendly",
    "ALT: cable_row | rank=1 | exercise=chest_supported_row | tier=strong | rationale=similar_horizontal_pull | notes=low_back_friendly",
    "ALT: cable_row | rank=2 | exercise=single_arm_dumbbell_row | tier=acceptable | rationale=equipment_flexible_pull | notes=travel_option",
  ];

  for (let day = 1; day <= 7; day++) {
    const sessionType = sessions[day - 1];
    const date = ymdAdd(input.week_start, day - 1);
    lines.push(`DAY ${day}`);
    lines.push(`SESSION_TYPE: ${sessionType}`);
    lines.push(`DAY_LABEL: Day ${day} (${date})`);
    lines.push(`LIFT_FOCUS: ${sessionType}`);
    lines.push(
      `RUN_TYPE: ${sessionType === "rest" ? "" : (sessionType === "conditioning" ? "easy_run" : "tempo_run")}`,
    );
    lines.push(`RUN_DURATION: ${sessionType === "rest" ? "" : "30-40 min"}`);
    lines.push(`RUN_TARGET_PACE: ${sessionType === "rest" ? "" : "8:30-9:00/mi"}`);
    lines.push(`RUN_HR_GUARDRAILS: ${sessionType === "rest" ? "" : "Zone 2-3"}`);
    lines.push(`RUN_NOTES: ${modifierNotes}`);

    if (sessionType !== "rest") {
      lines.push(...daySets);
    }

    lines.push(`END DAY ${day}`);
    lines.push("");
  }

  return lines.join("\n");
}

async function callConfiguredProvider(input: Required<RequestBody>) {
  const providerUrl = Deno.env.get("WEEKLY_PLAN_PROVIDER_URL")?.trim();
  const providerToken = Deno.env.get("WEEKLY_PLAN_PROVIDER_TOKEN")?.trim();
  if (!providerUrl) {
    return null;
  }

  const response = await fetch(providerUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(providerToken ? { Authorization: `Bearer ${providerToken}` } : {}),
    },
    body: JSON.stringify(input),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Provider call failed (${response.status}): ${text}`);
  }

  const payload = await response.json();
  const planText = typeof payload?.plan_text === "string"
    ? payload.plan_text
    : typeof payload?.text === "string"
    ? payload.text
    : null;

  if (!planText || planText.trim().length === 0) {
    throw new Error("Provider response did not include non-empty plan_text.");
  }

  return planText.trim();
}

function defaultUserPrompt(input: Required<RequestBody>): string {
  return [
    "Build a single week plan using WEEK_PLAN_V1 format.",
    `WEEK_START: ${input.week_start}`,
    `WEEK_END: ${input.week_end}`,
    `SPLIT_TYPE: ${input.split_type}`,
    `MODIFIER: ${input.modifier}`,
    "",
    "Return only the WEEK_PLAN_V1 payload text. No markdown fences.",
  ].join("\n");
}

function extractOpenAiContent(payload: any): string | null {
  const direct = payload?.choices?.[0]?.message?.content;
  if (typeof direct === "string" && direct.trim().length > 0) {
    return direct.trim();
  }
  if (Array.isArray(direct)) {
    const joined = direct
      .map((part) => (typeof part?.text === "string" ? part.text : ""))
      .join("")
      .trim();
    if (joined.length > 0) {
      return joined;
    }
  }
  return null;
}

async function callOpenAiDirect(input: Required<RequestBody>) {
  const apiKey = Deno.env.get("OPENAI_API_KEY")?.trim();
  if (!apiKey) {
    return null;
  }

  const model = Deno.env.get("OPENAI_MODEL")?.trim() || "gpt-4o-mini";
  const userPrompt = input.prompt_text.trim().length > 0
    ? input.prompt_text
    : defaultUserPrompt(input);

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      messages: [
        {
          role: "system",
          content:
            "You are a weekly training planner. Return only valid plain text in WEEK_PLAN_V1 format. Do not include markdown code fences.",
        },
        { role: "user", content: userPrompt },
      ],
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI call failed (${response.status}): ${text}`);
  }

  const payload = await response.json();
  const content = extractOpenAiContent(payload);
  if (!content) {
    throw new Error("OpenAI response did not include non-empty text.");
  }
  return content;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  try {
    const body = (await req.json()) as RequestBody;
    const weekStart = body.week_start?.trim();
    const weekEnd = body.week_end?.trim();
    const splitType = body.split_type?.trim() ?? "ppl_5_6d";
    const modifier = body.modifier?.trim() ?? "follow_long_term";
    const promptText = body.prompt_text?.trim() ?? "";

    if (!weekStart || !weekEnd) {
      return jsonResponse(400, {
        error: "week_start and week_end are required",
      });
    }

    const normalizedInput = {
      week_start: weekStart,
      week_end: weekEnd,
      split_type: splitType,
      modifier,
      prompt_text: promptText,
      planner_context: body.planner_context ?? {},
    };

    let planText: string | null = null;
    let openAiError: string | null = null;
    let providerError: string | null = null;
    let generatedBy = "fallback";
    try {
      planText = await callOpenAiDirect(normalizedInput);
      if (planText) {
        generatedBy = "openai_direct";
      }
    } catch (openAiErr) {
      openAiError = summarizeError(openAiErr);
      console.error("openai_direct_failed", openAiErr);
    }

    if (!planText) {
      try {
        planText = await callConfiguredProvider(normalizedInput);
        if (planText) {
          generatedBy = "configured_provider";
        }
      } catch (providerErr) {
        providerError = summarizeError(providerErr);
        console.error("configured_provider_failed", providerErr);
        // fall through to deterministic fallback
      }
    }

    if (!planText) {
      if (!ALLOW_WEEKLY_PLAN_FALLBACK) {
        return jsonResponse(502, {
          error: "No AI provider available",
          message:
            "OpenAI/provider generation failed. Check OPENAI_API_KEY or WEEKLY_PLAN_PROVIDER_URL/WEEKLY_PLAN_PROVIDER_TOKEN.",
          generated_by: "none",
          openai_error: openAiError,
          provider_error: providerError,
        });
      }
      planText = fallbackWeekPlanText({
        week_start: weekStart,
        week_end: weekEnd,
        split_type: splitType,
        modifier,
      });
      generatedBy = "fallback";
    }

    return jsonResponse(200, {
      plan_text: planText,
      week_start: weekStart,
      week_end: weekEnd,
      split_type: splitType,
      modifier,
      generated_by: generatedBy,
    });
  } catch (err) {
    console.error("generate_weekly_plan_error", err);
    return jsonResponse(500, {
      error: err instanceof Error ? err.message : "Unknown error",
    });
  }
});
