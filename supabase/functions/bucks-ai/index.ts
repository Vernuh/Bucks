// BUCKS AI — Supabase Edge Function (Deno).
//
//   Flutter AiService -> this function -> Gemini API
//
// Security model:
//  * GEMINI_API_KEY is an Edge Function secret. It never reaches the app.
//  * The caller must be a signed-in Supabase user (JWT verified below).
//  * Financial data is read HERE with the caller's own token, so Row Level
//    Security applies, and every query also filters on the verified user id.
//    The client cannot choose whose data is read or inject its own figures.
//  * No service-role key is used anywhere.
//  * Only a compact summary is sent to Gemini: no email, no notes, no ids.
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildGeminiRequest,
  buildSummary,
  extractReply,
  lastMonthStartIso,
  RateLimiter,
  validateRequest,
} from "./logic.ts";

const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";
const GEMINI_TIMEOUT_MS = 25_000;
const MAX_ROWS = 1000;
const MAX_ALL_ROWS = 10_000;

// 20 questions per user per 10 minutes (per function instance).
const limiter = new RateLimiter(20, 10 * 60_000);

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // --- 1. who is calling? ---------------------------------------------------
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) return json({ error: "unauthenticated" }, 401);

  const url = Deno.env.get("SUPABASE_URL");
  // The public key only; fall back to the apikey header the client already sends.
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY") ?? req.headers.get("apikey");
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (!url || !publicKey || !geminiKey) {
    console.error("bucks-ai: missing configuration (SUPABASE_URL / public key / GEMINI_API_KEY)");
    return json({ error: "not_configured" }, 500);
  }

  const db = createClient(url, publicKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: auth, error: authError } = await db.auth.getUser(token);
  if (authError || !auth?.user) return json({ error: "unauthenticated" }, 401);
  const userId = auth.user.id;

  if (!limiter.allow(userId, Date.now())) return json({ error: "rate_limited" }, 429);

  // --- 2. validate the request ---------------------------------------------
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_request" }, 400);
  }
  const parsed = validateRequest(body);
  if (!parsed.ok) return json({ error: parsed.error }, 400);
  const { message, history, utcOffsetMinutes } = parsed.value;

  // --- 3. read ONLY this user's data (RLS + explicit filter) ---------------
  const nowMs = Date.now();
  const since = lastMonthStartIso(nowMs, utcOffsetMinutes);
  const [profile, stats, recent, all, budgets, goals, achievements] = await Promise.all([
    db.from("profiles").select("username").eq("id", userId).maybeSingle(),
    db.from("user_stats").select("bucks_coins, xp, current_streak").eq("user_id", userId).maybeSingle(),
    db.from("transactions").select("type, category, amount, date").eq("user_id", userId)
      .gte("date", since).order("date", { ascending: false }).limit(MAX_ROWS),
    db.from("transactions").select("type, amount").eq("user_id", userId).limit(MAX_ALL_ROWS),
    db.from("budgets").select("category, limit_amount").eq("user_id", userId),
    db.from("savings_goals").select("name, target_amount, saved_amount, deadline").eq("user_id", userId),
    db.from("user_achievements").select("achievement_id", { count: "exact", head: true })
      .eq("user_id", userId).eq("unlocked", true),
  ]);
  const failed = [profile, stats, recent, all, budgets, goals, achievements].find((r) => r.error);
  if (failed) {
    console.error("bucks-ai: data query failed:", failed.error?.code);
    return json({ error: "data_unavailable" }, 500);
  }

  const summary = buildSummary({
    nowMs,
    offsetMin: utcOffsetMinutes,
    username: profile.data?.username ?? null,
    stats: stats.data ?? null,
    recentRows: recent.data ?? [],
    recentRowsTruncated: (recent.data?.length ?? 0) >= MAX_ROWS,
    allRows: all.data ?? [],
    allRowsTruncated: (all.data?.length ?? 0) >= MAX_ALL_ROWS,
    budgets: budgets.data ?? [],
    goals: goals.data ?? [],
    achievementsUnlocked: achievements.count ?? 0,
  });

  // --- 4. ask Gemini --------------------------------------------------------
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(GEMINI_MODEL)}:generateContent`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": geminiKey },
        body: JSON.stringify(buildGeminiRequest(summary, message, history)),
        signal: controller.signal,
      },
    );
    if (!res.ok) {
      // Log the status only: never the body, key, or user data.
      console.error("bucks-ai: Gemini HTTP", res.status);
      return json({ error: res.status === 429 ? "ai_rate_limited" : "ai_unavailable" }, res.status === 429 ? 429 : 502);
    }
    const reply = extractReply(await res.json());
    if (!reply.ok) {
      console.error("bucks-ai: no usable reply:", reply.reason);
      return json({ error: reply.reason === "blocked" ? "ai_blocked" : "ai_empty" }, 502);
    }
    return json({ reply: reply.text });
  } catch (e) {
    console.error("bucks-ai: Gemini call failed:", (e as Error)?.name);
    return json({ error: (e as Error)?.name === "AbortError" ? "ai_timeout" : "ai_unavailable" }, 502);
  } finally {
    clearTimeout(timer);
  }
});
