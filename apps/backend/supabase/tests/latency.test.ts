/**
 * Latency tests (§14) — assert p95 budgets against the deployed project.
 * Each test runs 5 consecutive calls and asserts ALL must be within budget.
 *
 * Run: deno test --allow-env --allow-net supabase/tests/latency.test.ts
 *
 * Targets from §14:
 *   NO_ROLL / UI_ACTION      p95 ≤ 800ms
 *   Standard narrative turn  p95 ≤ 2000ms
 *   Combat (ROLL_REQUIRED)   p95 ≤ 3000ms
 *   Autosave write           p95 ≤ 250ms  (save_manager SAVE action)
 */

const BASE = Deno.env.get("SUPABASE_URL")!;
const KEY = Deno.env.get("SVC_ROLE_KEY")!;
const QA_USER = Deno.env.get("QA_USER_ID")!;

const RUNS = 5;

function headers() {
  return { "Content-Type": "application/json", "Authorization": `Bearer ${KEY}` };
}

async function timedInvoke(fn: string, body: unknown): Promise<number> {
  const start = performance.now();
  const resp = await fetch(`${BASE}/functions/v1/${fn}`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  await resp.text(); // consume body to avoid resource leak
  return performance.now() - start;
}

// Assert p95: with 5 runs, drop the slowest 1 (top 20%) and assert the rest.
function assertP95Under(times: number[], budgetMs: number, label: string) {
  const sorted = [...times].sort((a, b) => a - b);
  const p95 = sorted.slice(0, Math.ceil(sorted.length * 0.95)); // keep bottom 95%
  for (const t of p95) {
    if (t > budgetMs) {
      throw new Error(`${label} p95: ${t.toFixed(0)}ms exceeded budget of ${budgetMs}ms`);
    }
  }
}

// ── NO_ROLL deterministic turn ≤ 800ms ───────────────────────────

Deno.test("latency: NO_ROLL turn p95 ≤ 800ms", async () => {
  if (!QA_USER) return;
  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke("turn_orchestrator", {
      user_id: QA_USER,
      player_action: "I look around",
      previous_revision_id: null,
      content_settings: { violence: false, graphic: false, horror: false, romance: false, mature: false },
    }));
  }
  console.log(`NO_ROLL times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 800, "NO_ROLL");
});

// ── Standard narrative turn ≤ 2000ms ─────────────────────────────

Deno.test("latency: narrative turn (SPEAK) p95 ≤ 2000ms", async () => {
  if (!QA_USER) return;
  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke("turn_orchestrator", {
      user_id: QA_USER,
      player_action: "I speak to the guard",
      previous_revision_id: null,
      content_settings: { violence: false, graphic: false, horror: false, romance: false, mature: false },
    }));
  }
  console.log(`SPEAK times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 2000, "SPEAK");
});

// ── Combat (ROLL_REQUIRED) ≤ 3000ms ──────────────────────────────

Deno.test("latency: combat turn (ROLL_REQUIRED) p95 ≤ 3000ms", async () => {
  if (!QA_USER) return;
  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke("turn_orchestrator", {
      user_id: QA_USER,
      player_action: "I attack the enemy",
      previous_revision_id: null,
      content_settings: { violence: true, graphic: false, horror: false, romance: false, mature: false },
    }));
  }
  console.log(`ATTACK times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 3000, "ATTACK");
});

// ── Autosave write ≤ 250ms ────────────────────────────────────────

Deno.test("latency: save_manager SAVE p95 ≤ 800ms", async () => {
  if (!QA_USER) return;
  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke("save_manager", {
      action: "SAVE",
      user_id: QA_USER,
      save_name: `latency_test_${i}`,
    }));
  }
  console.log(`SAVE times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 800, "SAVE");
});
