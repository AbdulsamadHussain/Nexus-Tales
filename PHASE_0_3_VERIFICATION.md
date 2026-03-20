# Phase 0-3 Completeness Verification Checklist

## Phase 0: Foundation ✅ COMPLETE

### Foundational Infrastructure
- [x] Monorepo with workspace structure (apps/, packages/)
- [x] Fastify backend with TypeScript
- [x] Flutter client with Material UI
- [x] Shared contracts package as schema authority
- [x] Drizzle ORM configured for PostgreSQL
- [x] Database migrations in place
- [x] Environment configuration (env.ts)

### Contract Authority
- [x] Zod 4 schemas defined for all canonical types
- [x] JSON Schema artifacts generated (`packages/contracts/generated/json-schemas.json`)
- [x] OpenAPI specs generated (`packages/contracts/generated/openapi.json`)
- [x] CI check enforces contract authority (`check:contract-authority`)
- [x] Build script validates artifact freshness (`check:generated-contracts`)

### Database Schema
- [x] users table with auth_subject
- [x] campaigns table with slug
- [x] runs table (user + campaign)
- [x] save_slots table with active revision tracking
- [x] revisions table with all required fields
- [x] save_snapshots table for artifacts
- [x] turn_requests with client_turn_id replay key
- [x] clarification_state with scene scope
- [x] event_logs, outbox_events, job_records
- [x] checkpoints, migration_records
- [x] advisory_lock_audit for monitoring

### Health & Smoke Tests
- [x] POST /health endpoint responds with 200
- [x] POST /v1/turns accepts TurnRequest contract
- [x] Response is valid TurnAuthoritativeResponse contract
- [x] Tests verify contract validation

**Exit Gate**: ✅ Achieved
- Flutter can call mocked POST /v1/turns
- Contract-valid response received
- CI enforces contract consistency

---

## Phase 1: Input Intake, Safety, Routing, Clarification ✅ COMPLETE

### Safety Gateway
- [x] Hard-block patterns enforced (bomb, doxx, fraud, terrorism, abuse)
- [x] Prompt injection detection (ignore instructions, break character, system prompt)
- [x] Content setting constraints (violence, romance, horror, betrayal, mature)
- [x] Custom exclusion matching
- [x] Sanitization removes control characters and extra whitespace
- [x] Decision outcomes: ALLOW, ALLOW_WITH_CONSTRAINTS, TRANSFORM, REJECT

### Deterministic Router
- [x] Route categories defined (NO_ROLL_DETERMINISTIC, ROLL_REQUIRED, CLARIFICATION_REQUIRED, etc.)
- [x] Verb-based action classification (inspect, open, read, attack, etc.)
- [x] Candidate skill assignment per verb
- [x] UI_ACTION pattern detection (inventory, quests, codex, save/load)
- [x] Fallback determinstic classifier when parser unavailable

### Clarification State Management
- [x] Stored in database (clarification_state table)
- [x] Scoped by run_id + save_slot_id + scene_fingerprint
- [x] Ambiguity counter increments on same target/route/input
- [x] 3-attempt rule: NO_OP returned instead of asking again
- [x] Counter resets on scene/target/input/route changes
- [x] Survives reconnects and device switches

### Idempotency
- [x] Client turn ID + request hash verified for replays
- [x] Same key with different payload → 409 conflict
- [x] Original response returned for valid replays
- [x] No duplicate revisions from replay

**Exit Gate**: ✅ Achieved
- All inputs end in ALLOW, TRANSFORM, REJECT, or safe routing
- Clarification state tracked correctly
- Zero state mutations before turn acceptance

---

## Phase 2: Deterministic Simulation ✅ COMPLETE

### PostgreSQL Advisory Locks
- [x] Lock key keyed by run_id + save_slot_id (SHA256 hash)
- [x] Transaction-scoped lock acquired before turn acceptance
- [x] PgRepository.withTurnLock implementation complete
- [x] pg_advisory_xact_lock used in transaction context
- [x] Lock released on transaction commit/rollback

### Simulation Service
- [x] Sole authority for state truth
- [x] Legality/affordance validation
- [x] Roll math with d20, modifiers, success tiers
- [x] Resource validation (health, stamina, inventory)
- [x] Consequence application (damage, items, flags)
- [x] Canonical event emission
- [x] Deterministic: fixed seed + input → same result

### Atomic Commit Transaction
- [x] Revision row inserted
- [x] Save snapshot inserted
- [x] Event logs inserted
- [x] Outbox events inserted (for Phase 4 workers)
- [x] Checkpoints inserted (if applicable)
- [x] Active revision updated in save_slot
- [x] All writes happen transactionally or rolled back entirely

### Authoritative Response
- [x] Returns revision_id, simulation_result, events
- [x] Includes worker job references (not yet processed)
- [x] Autosave eligibility marker
- [x] Route category, policy decision, intake details

### Idempotency in Simulation
- [x] Replays return original response without new revision
- [x] Advisory lock prevents race conditions
- [x] Same-key/different-payload rejected with 409

**Exit Gate**: ✅ Achieved
- Fixed state + fixed input → deterministic output
- Atomic commits verified
- Replay safety proven
- Advisory locks work on real PostgreSQL

---

## Phase 3: Revisions, Saves, Rollback, Migration ✅ COMPLETE

### Revision Model
- [x] One revision per committed turn
- [x] Sub-events inside revision (no separate checkpoints)
- [x] RevisionRecord includes: revisionId, previousRevisionId, canonicalState, events
- [x] commitKind: PLAYER_TURN or ROLLBACK
- [x] Autosave eligibility marker
- [x] Summary job queued flag

### Save Management
- [x] Manual save creation from active revision
- [x] Autosave ring with configurable size
- [x] Protected chapter-start checkpoints
- [x] Save artifacts: REVISION, MANUAL, AUTOSAVE types
- [x] Checkpoint types: CHAPTER_START (protected until overwritten)

### Rollback Safety
- [x] Rollback by revision ID, checkpoint ID, or save ID
- [x] Target resolution without corrupting state
- [x] Canonical restore as new rollback revision (commitKind: ROLLBACK)
- [x] Active revision atomically updated
- [x] Original saves never overwritten

### Schema Migration
- [x] PERSISTENCE_SCHEMA_VERSION in contracts (currently 1)
- [x] Version field on every save snapshot
- [x] Sequential migration steps (v0_to_v1, etc.)
- [x] Idempotent migration with fallback defaults
- [x] Migration debug bundle on failure:
  - [x] Original snapshot preserved
  - [x] Attempted steps logged
  - [x] Error message captured
  - [x] Schema descriptor attached (currentSchemaVersion, field list)
- [x] Copy-on-success: original never modified in-place
- [x] Failed migration quarantined separately

### Autosave Policy
- [x] Eligible after combat, quest changes, chapter boundaries
- [x] Deferred evaluation (doesn't block turn commit)
- [x] Configurable ring size and limits
- [x] Manual save always available

**Exit Gate**: ✅ Achieved
- Saves/loads/rollback deterministic
- Failed migrations export human-readable JSON bundles
- Revision history persisted correctly
- Manual saves guaranteed

---

## Testing & Verification ✅ COMPLETE

### Unit Tests (In-Memory)
- [x] POST /v1/turns contract validation
- [x] Safety gateway scenarios
- [x] Router classification
- [x] Clarification state tracking
- [x] Deterministic simulation
- [x] Idempotency replay
- [x] Revision commit atomicity

### Integration Tests (PostgreSQL)
- [x] Advisory lock serialization tested
- [x] Atomic commit verified on real database
- [x] Idempotency with real table constraints
- [x] Save history retrieval
- [x] Clarification state across reconnects

### Flutter Client
- [x] Backend URL configurable
- [x] Turn submission with action text
- [x] POST /v1/turns integration
- [x] Authoritative response displayed
- [x] Error handling and loading state
- [x] Draft input stays client-side (never canonical)

---

## Architecture Compliance ✅ VERIFIED

### Core Invariants
- [x] Code owns truth (not models)
- [x] Simulation service is sole state authority
- [x] No client-side state invention
- [x] Safety Gateway single enforcement point
- [x] One revision per turn (no sub-revision races)
- [x] Non-authoritative failures degrade gracefully

### Contract Authority
- [x] Canonical types centralized in contracts package
- [x] CI prevents duplicate schemas
- [x] Generated artifacts checked against source
- [x] OpenAPI and JSON Schema kept in sync

### Determinism
- [x] Fixed prior state + fixed input → same result
- [x] Ruleset version included in commits
- [x] Seed-based randomness consistent
- [x] Schema version tracked

### Trust Boundaries
- [x] Safety Gateway: no state write
- [x] Router: no state write
- [x] Parser: advisory only, no state write
- [x] Simulation: sole write authority
- [x] Narration/Images: read-only presentation

---

## Deployment Readiness

### Configuration
- [x] DATABASE_URL from environment
- [x] DATABASE_POOL_MAX configurable
- [x] PORT from environment
- [x] ENABLE_PARSER_ASSISTANCE feature flag
- [x] AUTOSAVE_RING_SIZE configurable
- [x] MANUAL_SAVE_LIMIT configurable

### Build & Package
- [x] TypeScript compilation
- [x] Contract artifacts included in CI
- [x] Backend dist/ compiled
- [x] Flutter buildable

### Observability
- [x] Fastify structured logging
- [x] PostgreSQL pool connection tracking
- [x] Turn intake metrics logged
- [x] Idempotency conflicts tracked
- [x] Error paths logged

---

## What's NOT Phase 0-3 (Reserved for Phase 4+)

- ❌ pg-boss worker queue initialization
- ❌ Summary, Narration, Image job consumers
- ❌ Transactional outbox consumption
- ❌ Template narration fallback
- ❌ Riverside state management (Phase 5)
- ❌ Full Flutter UI panels (Phase 5)
- ❌ Model routing/parsing (feature-flagged in Phase 1, real implementation Phase 4+)

---

## Summary for Completion

**Phase 0-3: 100% COMPLETE AND VERIFIED**

All exit gates achieved:
- Phase 0: Contract authority, health endpoints, schema generation ✅
- Phase 1: Safety, routing, clarification state with 3-attempt rule ✅
- Phase 2: Deterministic simulation, advisory locks, atomic commits ✅
- Phase 3: Revisions, saves, rollback, migration with debug bundles ✅

**Next Step**: Phase 4 — Post-Commit Workers (pg-boss, summary/narration/image handlers)
