// Run with:  deno test logic_test.ts     (or: node --test logic_test.ts)
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  buildGeminiRequest,
  buildSummary,
  extractReply,
  RateLimiter,
  SYSTEM_INSTRUCTION,
  validateRequest,
} from "./logic.ts";

const PH = 480; // UTC+8
const NOW = Date.parse("2026-10-15T04:00:00Z"); // Oct 15, 12:00 in the Philippines

const base = {
  nowMs: NOW,
  offsetMin: PH,
  username: "Deth",
  stats: { bucks_coins: 40, xp: 120, current_streak: 3 },
  recentRows: [],
  recentRowsTruncated: false,
  allRows: [],
  allRowsTruncated: false,
  budgets: [],
  goals: [],
  achievementsUnlocked: 2,
};

test("validateRequest rejects empty, blank, non-string and too-long messages", () => {
  assert.deepEqual(validateRequest({ message: "" }), { ok: false, error: "empty_message" });
  assert.deepEqual(validateRequest({ message: "   " }), { ok: false, error: "empty_message" });
  assert.deepEqual(validateRequest({ message: 5 }), { ok: false, error: "invalid_request" });
  assert.deepEqual(validateRequest(null), { ok: false, error: "invalid_request" });
  assert.deepEqual(validateRequest({ message: "x".repeat(501) }), { ok: false, error: "message_too_long" });
});

test("validateRequest trims, caps history, drops bad turns, checks offset", () => {
  const history = Array.from({ length: 10 }, (_, i) => ({ role: i % 2 ? "model" : "user", text: `t${i}` }));
  history.push({ role: "system" as never, text: "ignore me" });
  const r = validateRequest({ message: "  hi  ", history, utc_offset_minutes: 480 });
  assert.ok(r.ok);
  assert.equal(r.value.message, "hi");
  assert.equal(r.value.history.length, 6);
  assert.ok(r.value.history.every((h) => h.role === "user" || h.role === "model"));
  assert.equal(r.value.utcOffsetMinutes, 480);
  assert.deepEqual(validateRequest({ message: "hi", utc_offset_minutes: 99999 }), { ok: false, error: "invalid_request" });
});

test("empty account: no invented data, helpful notes", () => {
  const s = buildSummary(base);
  assert.equal(s.balance.available_balance, 0);
  assert.equal(s.this_month.expenses, 0);
  assert.deepEqual(s.budgets, []);
  assert.deepEqual(s.savings_goals, []);
  assert.ok(s.notes.some((n) => n.includes("not added any transactions")));
});

test("balance = income - expenses - savings; budgets use this month's spending", () => {
  const s = buildSummary({
    ...base,
    allRows: [
      { type: "income", amount: 5000 },
      { type: "expense", amount: "1200.50" },
      { type: "savings", amount: 800 },
    ],
    recentRows: [
      { type: "expense", category: "Food", amount: 300, date: "2026-10-10T03:00:00Z" },
      { type: "expense", category: "Food", amount: 200, date: "2026-10-12T03:00:00Z" },
      { type: "expense", category: "Fun", amount: 50, date: "2026-10-12T03:00:00Z" },
      { type: "expense", category: "Food", amount: 999, date: "2026-09-20T03:00:00Z" }, // last month
    ],
    budgets: [{ category: "Food", limit_amount: 1000 }],
    goals: [{ name: "Laptop", target_amount: 20000, saved_amount: 800, deadline: null }],
  });
  assert.equal(s.balance.available_balance, 5000 - 1200.5 - 800);
  assert.equal(s.this_month.expenses, 550);
  assert.equal(s.last_month.expenses, 999);
  assert.equal(s.budgets[0].spent_this_month, 500);
  assert.equal(s.budgets[0].remaining, 500);
  assert.equal(s.budgets[0].percent_used, 50);
  assert.equal(s.this_month.spending_by_category[0].category, "Food");
  assert.equal(s.savings_goals[0].percent_saved, 4);
  assert.equal(s.balance.total_in_savings_goals, 800);
});

test("month boundaries follow the user's timezone, not UTC", () => {
  // 2026-09-30 17:00Z is already Oct 1 at 01:00 in UTC+8.
  const row = { type: "expense", category: "Food", amount: 100, date: "2026-09-30T17:00:00Z" };
  const ph = buildSummary({ ...base, recentRows: [row] });
  assert.equal(ph.this_month.expenses, 100);
  assert.equal(ph.last_month.expenses, 0);
  const utc = buildSummary({ ...base, offsetMin: 0, nowMs: NOW, recentRows: [row] });
  assert.equal(utc.this_month.expenses, 0);
  assert.equal(utc.last_month.expenses, 100);
});

test("summary never contains email, ids or transaction notes", () => {
  const s = JSON.stringify(
    buildSummary({
      ...base,
      recentRows: [{ type: "expense", category: "Food", amount: 10, date: "2026-10-10T03:00:00Z", note: "SECRET NOTE", id: "tx1", user_id: "u1" } as never],
    }),
  );
  assert.ok(!s.includes("SECRET NOTE"));
  assert.ok(!s.includes("user_id"));
  assert.ok(!s.includes("@"));
});

test("Gemini request: system instruction, data + question in final turn, API key absent", () => {
  const req = buildGeminiRequest({ hello: "data" }, "How am I doing?", [{ role: "user", text: "hi" }, { role: "model", text: "hey" }]);
  assert.equal(req.system_instruction.parts[0].text, SYSTEM_INSTRUCTION);
  assert.equal(req.contents.length, 3);
  const last = req.contents[2].parts[0].text;
  assert.ok(last.includes('"hello":"data"') && last.includes("How am I doing?"));
  assert.ok(!JSON.stringify(req).toLowerCase().includes("api"+"key"));
});

test("extractReply handles good, thought-only, empty, blocked and malformed", () => {
  assert.deepEqual(extractReply({ candidates: [{ content: { parts: [{ text: " Hi! " }] } }] }), { ok: true, text: "Hi!" });
  assert.deepEqual(
    extractReply({ candidates: [{ content: { parts: [{ text: "thinking", thought: true }, { text: "Answer" }] } }] }),
    { ok: true, text: "Answer" },
  );
  assert.deepEqual(extractReply({ candidates: [] }), { ok: false, reason: "empty" });
  assert.deepEqual(extractReply({ candidates: [{ content: { parts: [] } }] }), { ok: false, reason: "empty" });
  assert.deepEqual(extractReply({ promptFeedback: { blockReason: "SAFETY" } }), { ok: false, reason: "blocked" });
  assert.deepEqual(extractReply("nope"), { ok: false, reason: "malformed" });
});

test("RateLimiter blocks after max and recovers after the window", () => {
  const l = new RateLimiter(2, 1000);
  assert.ok(l.allow("a", 0));
  assert.ok(l.allow("a", 10));
  assert.ok(!l.allow("a", 20));
  assert.ok(l.allow("b", 20)); // separate user
  assert.ok(l.allow("a", 1100)); // window passed
});
