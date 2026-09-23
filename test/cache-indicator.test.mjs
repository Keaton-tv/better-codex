import assert from "node:assert/strict";
import test from "node:test";
import { readRolloutTail, statusLabel, weeklyUsageLabel, installPresets } from "../cache-indicator.mjs";

const at = Date.parse("2026-09-23T10:00:00.000Z");
const line = (type, payload, timestamp = new Date(at).toISOString()) =>
  JSON.stringify({ type, payload, timestamp });
const context = model => line("turn_context", { model });
const usage = (input, cached, total) => line("event_msg", {
  type: "token_count",
  info: {
    total_token_usage: { input_tokens: total },
    last_token_usage: { input_tokens: input, cached_input_tokens: cached, cache_write_input_tokens: 0 }
  }
});

test("reports an observed cache read as an estimate and expires after 30 minutes", () => {
  const rollout = [context("gpt-6-sol"), usage(10_000, 8_000, 10_000)].join("\n");
  assert.equal(readRolloutTail(rollout, at + 60_000).state, "likely");
  assert.equal(statusLabel(readRolloutTail(rollout, at + 60_000)).text, "Cache ~29m");
  assert.equal(readRolloutTail(rollout, at + 30 * 60_000).state, "expired");
});

test("does not claim warmth after a cache miss, model change, or compaction", () => {
  const hit = [context("gpt-6-sol"), usage(10_000, 8_000, 10_000)];
  assert.equal(readRolloutTail([...hit, usage(11_000, 0, 21_000)].join("\n"), at).state, "unknown");
  assert.equal(readRolloutTail([...hit, context("gpt-6-astra")].join("\n"), at).state, "unknown");
  assert.equal(readRolloutTail([...hit, line("compacted", {})].join("\n"), at).state, "unknown");
});

test("duplicate cumulative usage does not refresh the observation", () => {
  const rollout = [context("gpt-6-luna"), usage(10_000, 8_000, 10_000),
    usage(10_000, 8_000, 10_000)].join("\n");
  assert.equal(readRolloutTail(rollout, at + 29 * 60_000).remainingMs, 60_000);
});

test("shows the remaining weekly Codex limit and ignores other windows", () => {
  const response = { rateLimitsByLimitId: { codex: {
    primary: { usedPercent: 32, windowDurationMins: 10080, resetsAt: null },
    secondary: { usedPercent: 90, windowDurationMins: 300, resetsAt: null }
  } } };
  assert.equal(weeklyUsageLabel(response).text, "68% left");
  assert.equal(weeklyUsageLabel({ rateLimits: { primary: { usedPercent: 99, windowDurationMins: 300 } } }), null);
  assert.equal(weeklyUsageLabel({ rateLimits: { secondary: { usedPercent: 200, windowDurationMins: 10080 } } }).text, "0% left");
});

test("loads saved slider stops and applies edits immediately", () => {
  const previousStorage = globalThis.localStorage;
  const previousStatsig = globalThis.__STATSIG__;
  const previousControl = globalThis.__betterCodexPresetControl;
  const events = [];
  const client = {
    getDynamicConfig: () => ({ value: {}, get: () => null }),
    $emt: event => events.push(event.name),
  };
  const saved = { presets: [
    { model: "gpt-6-astra", reasoning_effort: "high" },
    { model: "gpt-6-sol", reasoning_effort: "medium" },
    { model: "gpt-6-luna", reasoning_effort: "low" },
  ] };
  try {
    globalThis.localStorage = { getItem: () => JSON.stringify(saved) };
    globalThis.__STATSIG__ = { firstInstance: client };
    delete globalThis.__betterCodexPresetControl;
    assert.equal(installPresets(), true);
    assert.deepEqual(client.getDynamicConfig("423260384").get("presets"), [saved.presets]);
    const next = saved.presets.map((p, i) => i === 0 ? { ...p, reasoning_effort: "low" } : p);
    globalThis.__betterCodexPresetControl.set(next);
    assert.deepEqual(client.getDynamicConfig("423260384").get("presets"), [next]);
    assert.deepEqual(events, ["values_updated", "values_updated"]);
  } finally {
    globalThis.localStorage = previousStorage;
    globalThis.__STATSIG__ = previousStatsig;
    globalThis.__betterCodexPresetControl = previousControl;
  }
});
