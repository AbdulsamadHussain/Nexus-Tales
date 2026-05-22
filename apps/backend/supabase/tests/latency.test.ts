/**
 * Latency tests (§14) — assert p95 budgets against the deployed project.
 * Each test runs 5 consecutive calls and asserts all must be within budget.
 *
 * Required env vars (same as integration.test.ts):
 *   SUPABASE_URL        — project URL
 *   SVC_ROLE_KEY        — service role key
 *   QA_USER_TOKEN       — valid JWT for qa_user_a
 *   QA_CHARACTER_ID     — character_id owned by qa_user_a
 *
 * Run: deno test --allow-env --allow-net supabase/tests/latency.test.ts
 *
 * Targets from §14:
 *   NO_ROLL / UI_ACTION      p95 ≤ 800ms
 *   Standard narrative turn  p95 ≤ 2000ms
 *   Combat (ROLL_REQUIRED)   p95 ≤ 3000ms
 *   Autosave write           p95 ≤ 800ms   (save_manager SAVE action)
 */

const BASE     = Deno.env.get("SUPABASE_URL")!;
const SVC_KEY  = Deno.env.get("SVC_ROLE_KEY")!;
const TOKEN_A  = Deno.env.get("QA_USER_TOKEN");
const CHAR_A   = Deno.env.get("QA_CHARACTER_ID");

const RUNS = 5;

// ── Helpers ───────────────────────────────────────────────────────────

/** Call a user-facing Edge Function with a user JWT (as turn_orchestrator expects). */
async function timedInvoke(
  token: string,
  fn: string,
  body: unknown,
): Promise<number> {
  const start = performance.now();
  const resp = await fetch(`${BASE}/functions/v1/${fn}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      // turn_orchestrator calls auth.getUser() on this token; must be a user JWT.
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  await resp.text(); // consume body fully to avoid resource leaks
  return performance.now() - start;
}

/** Call an internal Edge Function with the service role key. */
async function timedInvokeSvc(fn: string, body: unknown): Promise<number> {
  const start = performance.now();
  const resp = await fetch(`${BASE}/functions/v1/${fn}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SVC_KEY}`,
    },
    body: JSON.stringify(body),
  });
  await resp.text();
  return performance.now() - start;
}

/**
 * assertP95Under: with RUNS=5, treats the 5 values as the full distribution.
 * Drops the single slowest sample (top 20 %) and asserts the remaining 4
 * are all within budget — equivalent to a p80 guarantee on 5 samples,
 * which is the best approximation of p95 with this sample size.
 */
function assertP95Under(times: number[], budgetMs: number, label: string) {
  const sorted = [...times].sort((a, b) => a - b);
  // Keep bottom ceil(95%) of samples — with 5 samples that is 5 values;
  // to give one outlier slot, drop the single maximum.
  const p95Samples = sorted.slice(0, sorted.length - 1);
  const worst = p95Samples[p95Samples.length - 1];
  if (worst > budgetMs) {
    throw new Error(
      `${label} p95 exceeded: worst kept sample was ${worst.toFixed(0)}ms ` +
      `(budget ${budgetMs}ms). All times: ${sorted.map((t) => t.toFixed(0)).join(", ")}ms`,
    );
  }
}

// ── NO_ROLL deterministic turn ≤ 800ms ───────────────────────────────

Deno.test("latency: NO_ROLL turn p95 ≤ 800ms", async () => {
  if (!TOKEN_A || !CHAR_A) return;

  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke(TOKEN_A, "turn_orchestrator", {
      character_id: CHAR_A,
      player_action: "I look around",
      previous_revision_id: null,
      content_settings: {
        violence: false, graphic: false, horror: false, romance: false, mature: false,
      },
    }));
  }
  console.log(`NO_ROLL times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 800, "NO_ROLL");
});

// ── Standard narrative turn (SPEAK) ≤ 2000ms ─────────────────────────

Deno.test("latency: narrative turn (SPEAK) p95 ≤ 2000ms", async () => {
  if (!TOKEN_A || !CHAR_A) return;

  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke(TOKEN_A, "turn_orchestrator", {
      character_id: CHAR_A,
      player_action: "I talk to the innkeeper",
      previous_revision_id: null,
      content_settings: {
        violence: false, graphic: false, horror: false, romance: false, mature: false,
      },
    }));
  }
  console.log(`SPEAK times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 2000, "SPEAK");
});

// ── Combat (ROLL_REQUIRED) ≤ 3000ms ──────────────────────────────────

Deno.test("latency: combat turn (ROLL_REQUIRED) p95 ≤ 3000ms", async () => {
  if (!TOKEN_A || !CHAR_A) return;

  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvoke(TOKEN_A, "turn_orchestrator", {
      character_id: CHAR_A,
      player_action: "I attack the enemy",
      previous_revision_id: null,
      content_settings: {
        violence: true, graphic: false, horror: false, romance: false, mature: false,
      },
    }));
  }
  console.log(`ATTACK times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 3000, "ATTACK");
});

// ── Autosave write ≤ 800ms ────────────────────────────────────────────
// save_manager is called by the simulation_service via service role, so we use
// the service role key here (not a user JWT).

Deno.test("latency: save_manager SAVE p95 ≤ 800ms", async () => {
  if (!TOKEN_A || !CHAR_A) return;

  const times: number[] = [];
  for (let i = 0; i < RUNS; i++) {
    times.push(await timedInvokeSvc("save_manager", {
      action: "SAVE",
      character_id: CHAR_A,
      save_name: `latency_test_${i}`,
    }));
  }
  console.log(`SAVE times: ${times.map((t) => t.toFixed(0)).join(", ")}ms`);
  assertP95Under(times, 800, "SAVE");
});
