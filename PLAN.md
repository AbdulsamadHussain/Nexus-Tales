# Nexus Tales Prototype-to-V1 Implementation Plan

## Summary
Build this as a contract-first modular monolith with one schema authority, one canonical write path, transaction-scoped revision commits, and revision-bound post-commit workers. Flutter client, Node + TypeScript backend, PostgreSQL as the authoritative store, `pg-boss` for background jobs, and Supabase Auth and Storage for v1 infrastructure.

## Core Decisions
- Use one shared `contracts` package as the only schema authority for canonical types, enums, API payloads, worker payloads, and persistence-facing shapes: `SafetyDecision`, `RouteCategory`, `ActionPacket`, `SimulationResult`, `CanonicalEvent`, `RevisionRecord`, `SaveSnapshot`, `SummaryJob`, `ImageJob`, turn request/response payloads, and worker envelopes.
- Generate backend validation, JSON Schema, and OpenAPI from those Zod 4 schemas. Flutter and workers consume the same package directly. CI fails if canonical schemas are duplicated outside `contracts` or generated artifacts drift.
- Use normalized PostgreSQL tables for `users`, `campaigns`, `runs`, `save_slots`, `turn_requests`, `revisions`, `checkpoints`, `event_logs`, `job_records`, `clarification_state`, and `migration_records`. Use `jsonb` for canonical snapshots, policy decision records, narrator input packets, summary packets, worker payloads, and migration/debug bundles.
- `POST /v1/turns` requires `client_turn_id`. A replay is valid only if player identity, `run_id`, `save_slot_id`, `client_turn_id`, and request-body hash all match. Same key with different payload is rejected as an idempotency conflict.
- Serialize authoritative turns with a transaction-scoped PostgreSQL advisory lock keyed by `run_id + save_slot_id`. Only one authoritative turn or rollback commit may succeed at a time for that game thread.
- A single turn transaction commits, atomically, the validated action packet, simulation result, canonical events, revision row, save snapshot metadata, autosave eligibility marker, and transactional outbox rows. Nothing is visible downstream until commit is durable.
- All workers are post-commit and revision-scoped. Every job payload includes `revision_id`, `campaign_id`, `save_slot_id`, `schema_version`, and `job_type`. Uniqueness keys are `summary:{revision_id}`, `narration:{revision_id}`, and `image:{scene_anchor_id}:{revision_id}`.
- Keep Supabase boundaries strict: Auth for identity only, Storage for media only. Canonical game state and revision history live only in PostgreSQL and are written only by the Node backend.
- Keep Flutter state split explicit in Riverpod: authoritative remote state, local presentation state, and draft/input state. Flutter never invents canonical outcomes.

## Phase Plan
### Phase 0: Foundation, Contracts, and Repo Skeleton
- Set up the monorepo, Fastify backend shell, Flutter shell, shared `contracts` package, Drizzle migration workflow, local PostgreSQL, `pg-boss`, CI, environment handling, and health endpoints.
- Lock the contracts package before Phase 1. Wire backend request validation, worker validation, Flutter type consumption, JSON Schema export, OpenAPI generation, and CI enforcement against duplicate canonical schemas.
- Define the initial database schema now, including `turn_requests`, outbox tables, `clarification_state`, and the advisory-lock keying helper.
- Exit gate: Flutter can call a mocked `POST /v1/turns` using shared contracts and receive a contract-valid authoritative stub response; OpenAPI is generated from the same source; CI rejects contract drift and duplicate schemas.
- Failure counter: if tooling setup slows delivery, collapse to one backend app, one Flutter app, and one shared contracts package first. Do not proceed with multiple schema authorities.

### Phase 1: Input Intake, Safety, Routing, and Clarification State
- Implement sanitization, Safety/Policy Gateway, deterministic routing, and parser assistance behind a feature flag.
- Persist clarification state in PostgreSQL in `clarification_state`, keyed by `run_id`, `save_slot_id`, and scene fingerprint, with ambiguity count, last target fingerprint, and last route category so reconnects and app restarts do not reset the three-attempt rule.
- Resolve idempotency before authoritative execution: under the run-scoped lock, return the original authoritative response for a valid replay or reject same-key/different-payload conflicts.
- Keep parser output advisory only and route parser failures back through the same deterministic classifier.
- Exit gate: every input ends in `ALLOW`, `ALLOW_WITH_CONSTRAINTS`, `TRANSFORM`, `REJECT`, deterministic route success, or server-tracked clarification/no-op behavior, with zero state mutation before turn acceptance.
- Failure counter: if parser quality is weak, disable parser assistance and ship deterministic routing plus clarification prompts only.

### Phase 2: Deterministic Simulation and Authoritative Turn Commit
- Implement the simulation service as the sole authority for legality checks, roll math, success tiers, resource validation, consequence application, canonical event creation, and revision assembly.
- Execute accepted turns under the advisory lock and inside one database transaction that commits accepted turn metadata, simulation result, event rows, revision row, snapshot metadata, autosave marker, and outbox rows together. No worker, reader, or analytics consumer may observe any part of the turn before the full transaction including outbox rows is durable.
- Keep authoritative response and narration separate: truth returns first with revision/result/events/autosave/job references; prose and images arrive later via stream or follow-up fetch.
- Exit gate: fixed prior state, fixed input, fixed seed, fixed ruleset version, and fixed schema version always produce the same simulation result and same committed revision; duplicate submissions return the original result instead of creating a new revision.
- Failure counter: if rules scope expands too quickly, cut v1 to one curated campaign and a smaller ruleset. Do not weaken determinism, transactionality, or idempotency.

### Phase 3: Revisions, Saves, Rollback, and Migration
- Persist every committed turn as one authoritative revision with canonical snapshot references, event links, autosave eligibility, and rollback-safe metadata.
- Implement manual saves, autosave ring, protected chapter-start checkpoints, rollback by revision/checkpoint, schema-versioned snapshots, sequential migrations, and migration debug bundles.
- Make manual save guaranteed in v1. Autosave degradation must never remove manual save capability. Manual save slot limits and autosave ring size are deployment-configurable, not hardcoded.
- Keep migration copy-on-success only. Original saves stay untouched until migration and validation succeed. Debug export format must be human-readable JSON, or JSON plus schema descriptor when internal storage is encoded or compressed.
- Model rollback as a backend-controlled canonical-state operation only. Flutter presents revision history, confirmation, and restored state returned by the backend.
- Exit gate: save/load/rollback are deterministic, failed migrations never expose partial live state, and migration debug artifacts are supportable by format.
- Failure counter: if migration safety is not ready, ship manual saves plus protected checkpoints first and gate cross-version loading until the migration suite passes.

### Phase 4: Post-Commit Workers, Memory, Narration, and Images
- Implement transactional outbox consumption and `pg-boss` workers for summaries, narration, and images. Every job is revision-scoped, idempotent, post-commit, and non-authoritative.
- Apply summary trigger rules exactly as defined in the architecture doc: one summary job per revision using `summary:{revision_id}`, hard/soft triggers, debounce before enqueue, and suppression windows. Retries must never create a second summary artifact for the same revision.
- Make narration strictly secondary to truth. If premium narration fails or times out, return deterministic template narration from the simulation result. Allow at most one optional async retry with a cheaper or shorter prompt.
- Keep image generation asynchronous and anchored only to eligible scene/revision anchors. Store media artifacts in Supabase Storage with backend-owned metadata references.
- Exit gate: worker outages or retries may delay prose, recaps, or media, but can never invalidate a revision, mutate canonical state, or create duplicate artifacts for the same revision.
- Failure counter: if latency or cost is too high, default to template narration, deterministic event-log recaps, and placeholder or cached art.

### Phase 5: Flutter Client, Riverpod State Split, and Delivery UX
- Implement the chat-first shell, action input, clarification flows, authoritative turn result rendering, save/load/rollback views, settings, and the core side panels for sheet, inventory, quests, codex, factions, and relationships.
- Enforce three Riverpod state categories. Authoritative remote state includes current revision, canonical state, save slots, quests, inventory, codex, faction standings, and relationship scores. Local presentation state is ephemeral UI only. Draft/input state contains typed action, selected quick action, pending clarification answer, and unsaved settings edits.
- Use `autoDispose` aggressively for non-critical panels and keep only a small cross-navigation provider set alive. Treat local cache as convenience only, never as truth.
- Implement rollback UI explicitly: show revision/checkpoint history, allow selection, require confirmation, call rollback, and replace client-visible authoritative state with the restored backend response.
- Exit gate: a player can complete the full loop from input to authoritative result to save/load/rollback in Flutter without any client-side invention of canonical state.
- Failure counter: if cross-platform scope slips, ship mobile and web first with the full authoritative loop intact and defer desktop polish or secondary panel richness.

### Phase 6: Observability, QA, Security, and Release Readiness
- Add structured logs, traces, route and parser metrics, idempotency replay/conflict metrics, ambiguity-loop metrics, advisory-lock contention metrics, worker queue health, autosave failure streaks, migration outcomes, latency budgets, and policy audit logs.
- Build contract tests from the shared schemas/OpenAPI, deterministic simulation tests, transaction/outbox tests, rollback and migration tests, duplicate submission tests, same-key/different-payload conflict tests, multi-device lock-contention tests, and end-to-end gameplay regression suites.
- Add release gates around canonical integrity, replay safety, rollback fidelity, worker idempotency, and latency targets. Fail closed on canonical integrity, fail open only on presentation quality.
- Exit gate: p95 targets are met or intentionally degraded via profiles, no known path creates duplicate revisions or worker artifacts from one turn, idempotency conflicts are rejected cleanly, and recovery paths are proven under fault injection.
- Failure counter: if latency or cost targets are missed, cut presentation load first by reducing narration tier usage, increasing async fallback usage, and shrinking optional media before touching authoritative correctness.

## Test Plan
- Verify the `contracts` package is the only schema authority and CI rejects duplicate canonical definitions or drifted generated artifacts.
- Verify `POST /v1/turns` rejects missing `client_turn_id`, deduplicates valid replays without creating a second revision, and rejects same-key/different-payload requests as idempotency conflicts.
- Verify same-key/different-payload rejections emit a measurable conflict event that is visible in observability tooling.
- Verify advisory-lock serialization prevents conflicting commits on the same `run_id + save_slot_id`, including multi-device and retry races.
- Verify no worker, reader, or analytics consumer can observe any part of a turn before the full revision commit plus outbox rows are durable.
- Verify clarification state survives reconnect, crash, resume, and device switching, and resets only on the documented scene/target/input/route changes.
- Verify summary, narration, and image jobs honor deterministic uniqueness keys and retries never create duplicate revision-scoped artifacts.
- Verify authoritative response delivery still works when narration streaming, summary generation, or image generation fails.
- Verify rollback restores canonical state exactly and Flutter renders the restored state without local reconstruction.
- Verify migration failure preserves the original save, quarantines the failed copy, and emits a human-readable JSON debug bundle with schema descriptor when required.
- Verify manual save remains available during autosave degradation and autosave failure escalation warns the player after three consecutive failed committed revisions.

## Assumptions and Defaults
- The repo is effectively greenfield and the architecture document is the authoritative baseline.
- The v1 stack is Fastify, TypeScript, Zod 4, Drizzle, PostgreSQL, `pg-boss`, Flutter, and Riverpod.
- Per-run turn serialization uses transaction-scoped PostgreSQL advisory locks keyed by `run_id` and `save_slot_id`.
- Clarification state is stored in PostgreSQL in a dedicated table scoped to run/save-slot/session and scene fingerprint.
- Ruleset version is a versioned constant in the `contracts` package and is included in every `SimulationResult` and `RevisionRecord` payload.
- Simulation determinism requires fixed prior state, fixed input, fixed seed, and fixed ruleset version.
- Manual save is guaranteed in v1. Save slot limits and autosave ring size are deployment-configurable.
- Migration debug exports are human-readable JSON, or JSON plus schema descriptor when the stored format is encoded/compressed.
- v1 is single-player, curated-campaign-first, excludes multiplayer and user-authored campaigns, and keeps parser assistance feature-flagged, template narration always available, images off the critical path, and rollback plus migration first-class from the start.
