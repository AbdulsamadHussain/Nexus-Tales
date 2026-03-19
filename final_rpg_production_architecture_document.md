AI Narrative RPG - Production Architecture

**AI Narrative RPG\
Production Grade Architecture Document**

*Final consolidated system design for a cross-platform, chat-first, deterministic, multi-model narrative RPG application*

|**Document status**|Final draft for implementation planning|
| :- | :- |
|**Audience**|Founders, architects, backend engineers, mobile engineers, QA, product, and operations|
|**Application shell**|Flutter client with backend-owned deterministic simulation and model routing|
|**Design posture**|Code owns truth; models interpret, narrate, summarize, and visualize within enforced boundaries|
|**Scope**|Production-grade architecture, trust model, persistence, routing, safety, failure handling, and implementation guidance|

|**Purpose.** This document replaces high-level brainstorming with enforceable production rules. Wherever previous drafts used philosophy, this draft uses contracts, ownership, trigger semantics, and fallback behavior.|
| :- |


# **Document Outline**
**1.** Executive summary and non-negotiable invariants

**2.** Product scope, user experience posture, and gameplay assumptions

**3.** Core architecture and trust boundaries

**4.** End-to-end turn lifecycle and routing

**5.** Safety/Policy Gateway as a single enforcement authority

**6.** Parser, validation, deterministic fallback, and ambiguity handling

**7.** Deterministic simulation service and state authority

**8.** Revision model, autosave, rollback, and persistence guarantees

**9.** Memory architecture, summaries, and continuity triggers

**10.** Relationship/faction thresholds and event semantics

**11.** Failure-handling matrix and graceful degradation

**12.** Schema versioning, migration, and save export rules

**13.** Client architecture in Flutter and UI ownership boundaries

**14.** Operational performance targets, observability, and release guidance

**15.** Appendices: contracts, schemas, and implementation checklists

|**Reading note.** The words must, may, should, and must not are normative in this document. When there is conflict between narration quality and system integrity, system integrity wins.|
| :- |

# **1. Executive Summary and Non-Negotiable Invariants**
This product is a chat-first narrative RPG application. The user experiences it as a story-driven game master, but the platform is not a freeform AI chat. It is a deterministic game system with a model-driven presentation layer. The central engineering decision is that code owns truth and models never own canonical state.

**•** Canonical game state may be mutated only by the deterministic simulation service.

**•** The client, narrator, summarizer, and image generator are presentation or convenience layers. None of them may commit state directly.

**•** Routing is deterministic by default. A model may assist only in explicitly marked ambiguity paths, and its output must normalize back into fixed route categories before execution.

**•** Safety is enforced by a single Safety/Policy Gateway. Prompts may mirror safety settings, but prompt text is not the enforcement authority.

**•** Each committed player turn produces one revision. Sub-events inside that turn do not create separate authoritative saves.

**•** Non-authoritative service failures may degrade presentation quality or convenience, but must not corrupt or roll back already committed canonical state.

|**Core invariant.** The simulation service is the only writer to canonical state. Model outputs are treated as untrusted presentation artifacts unless converted into validated, schema-safe requests before simulation.|
| :- |

# **2. Product Scope, User Experience Posture, and Gameplay Assumptions**
The intended product is a cross-platform AI narrative RPG with a chat-style primary interface, persistent saves, deterministic checks, optional scene art, and support for curated campaign packs plus guided custom campaigns. The first production line should behave like an app with game systems, not like a real-time action game.

|**Area**|**Decision**|**Reason**|
| :-: | :-: | :-: |
|Primary interface|Chat-first with persistent side panels|Matches the narrative loop and keeps implementation simpler than a real-time map or action combat shell.|
|Platform shell|Flutter|One codebase for mobile, web, and desktop with strong UI composition and Firebase/cloud integration options.|
|Game logic posture|Turn-based deterministic simulation|Fairness, auditability, rollback safety, and anti-exploit enforcement depend on deterministic state transitions.|
|Scene imagery|Asynchronous anchored artwork on major area transitions|Art supports immersion but must not block gameplay.|
|Campaign strategy|Curated defaults first, guided custom creation second|Better quality, balance, and onboarding for v1.|

The system should roll only when an action is risky, uncertain, resisted, materially consequential, or dependent on hidden information. It should not roll trivial actions merely to imitate tabletop ritual.

**•** Rolls are appropriate for combat, stealth, persuasion under pressure, unstable magic, dangerous traversal, and high-stakes downtime.

**•** Rolls are not appropriate for obvious no-risk actions such as reading a sign, opening an unlocked bag, or buying an item the player can afford in an ordinary shop.

**•** Difficulty modes should adjust target numbers, resource pressure, and forgiveness. They must not silently rewrite the meaning of success.
# **3. Core Architecture and Trust Boundaries**
The platform is composed of an application client, a backend orchestration layer, and specialized services for safety, routing, simulation, memory, narration, image generation, and persistence. Trust is not evenly distributed. The architecture must explicitly distinguish authoritative services from non-authoritative services.

|Player Input<br>`  `-> Input Sanitization / Safety Gateway<br>`  `-> Deterministic Router / Classifier<br>`  `-> Optional Parser Assist (ambiguity path only)<br>`  `-> Deterministic Simulation Service<br>`  `-> Canonical State Commit (single revision)<br>`  `-> Memory / Summary Triggers<br>`  `-> Narration Request (read-only packet)<br>`  `-> Optional Scene Image Request<br>`  `-> Client UI Render|
| :- |

|**Component**|**Trust level**|**May mutate canonical state?**|**Notes**|
| :-: | :-: | :-: | :-: |
|Safety/Policy Gateway|Authoritative for policy|No|Controls what can proceed, be transformed, or be rejected; does not write game state.|
|Deterministic router/classifier|Authoritative for route categories|No|Owns primary action classification and deterministic fallback classification.|
|Parser model|Untrusted helper|No|May propose structured intent but cannot execute or mutate state.|
|Simulation service|Authoritative|Yes|Only service allowed to compute and commit canonical game state deltas.|
|Narrator model|Presentation only|No|Converts truth into prose; state-like text from this layer is ignored.|
|Summary worker|Convenience only|No|Generates recaps and memory artifacts; failure cannot block progression.|
|Image worker|Presentation only|No|Anchors scenes visually; failure must not block play.|
|Persistence store|Authoritative storage|Stores committed revisions|Receives writes only through the simulation and save pipeline.|

|**Enforcement contract.** The narrator, parser, summary worker, and image worker never receive write credentials for canonical state. Any state-like output they generate is non-authoritative and must be ignored unless translated into a new validated request that goes back through deterministic routing and simulation.|
| :- |

# **4. End-to-End Turn Lifecycle and Routing**
Each player action is processed as a bounded transaction. The system must never let presentation layers mutate state opportunistically mid-turn. The platform should treat the turn as the atomic unit of authority.
## **4.1 Turn phases**
**1.** Receive raw player input together with current scene context, active content settings, and current client session metadata.

**2.** Normalize and sanitize the input. Strip obvious meta-instruction attacks, control-text injection patterns, and unsupported command syntax before any optional LLM parse.

**3.** Run the Safety/Policy Gateway. The gateway may allow, allow with constraints, transform, or reject the input.

**4.** Run the deterministic router/classifier on the sanitized input. This step decides whether the action is non-interactive, deterministic, requires a roll, requires clarification, or is disallowed by game affordance rules.

**5.** If the route is ambiguous and the deterministic classifier cannot safely resolve intent, invoke parser assistance. The parser is advisory only and must return to schema validation.

**6.** Pass the validated action packet into the deterministic simulation service. The simulation service computes legality, roll resolution, consequences, and canonical state delta.

**7.** Commit one authoritative revision for the turn. All sub-events inside the turn are attached to that same revision.

**8.** Emit post-commit jobs: autosave evaluation, summary trigger evaluation, analytics, narration request, optional image request, and client render payloads.
## **4.2 Routing policy**
**•** Primary routing must be rules-based and deterministic.

**•** Model-assisted routing may occur only when the deterministic classifier cannot map the input into a safe known category.

**•** Any model-assisted classification must normalize back into a fixed route enum before execution.

**•** The same deterministic router/classifier owns both the primary route and the fallback route after parser failure. There must not be a second independent classifier with potentially conflicting logic.

|RouteCategory :=<br>`  `NO\_ROLL\_DETERMINISTIC<br>`  `ROLL\_REQUIRED<br>`  `CLARIFICATION\_REQUIRED<br>`  `SAFE\_REJECT<br>`  `UI\_ACTION (inventory, codex, settings, save/load)<br>`  `SYSTEM\_TRANSFORMED\_ACTION|
| :- |

# **5. Safety/Policy Gateway as a Single Enforcement Authority**
Content boundaries, maturity settings, and platform policy controls must have a single authoritative owner. That owner is the Safety/Policy Gateway. Prompts may repeat the active restrictions, but they do not enforce them. When prompt steering and the gateway disagree, the gateway wins.
## **5.1 Gateway input contract**
**•** Raw or sanitized player input

**•** Current scene metadata and route candidate if already classified

**•** Content settings such as violence level, romance toggle, horror toggle, mature themes toggle, betrayal toggle, and custom exclusions

**•** Account/session policy posture

**•** Optional platform or moderation policy metadata
## **5.2 Gateway output contract**

|{<br>`  `"decision": "ALLOW | ALLOW\_WITH\_CONSTRAINTS | TRANSFORM | REJECT",<br>`  `"sanitized\_input": "...",<br>`  `"policy\_flags": ["..."],<br>`  `"narration\_constraints": ["..."],<br>`  `"transformation\_reason": "optional",<br>`  `"player\_message": "optional for reject",<br>`  `"retry\_allowed": true<br>}|
| :- |

|**Decision**|**Meaning**|**Downstream effect**|
| :-: | :-: | :-: |
|ALLOW|The input is safe as-is.|Proceed to routing and simulation.|
|ALLOW\_WITH\_CONSTRAINTS|The input may proceed, but narration and visuals must obey additional limits.|Proceed with the supplied constraint list attached to post-commit presentation jobs.|
|TRANSFORM|The player intent is preserved in a safer equivalent form.|Proceed only with the transformed sanitized input; raw blocked content must not be forwarded unnecessarily.|
|REJECT|The action cannot proceed under active policy or product rules.|Stop the pipeline, send the player-facing message, and do not simulate.|

## **5.3 Detection and hardening rules**
**•** The gateway must run before any model is trusted to interpret intent.

**•** Prompt injection defense must include deterministic pattern detection, stripping or blocking of meta-control phrases, and refusal logic for attempts to override rules or reveal system instructions.

**•** The gateway must never silently relax content settings because a model wrote a compelling paragraph. All content boundary changes must be user-initiated or admin-configured.

**•** Gateway actions should be logged with policy flags and scene identifiers for auditability.
# **6. Parser, Validation, Deterministic Fallback, and Ambiguity Handling**
The parser exists to improve user flexibility, especially for custom free-text actions. It does not own truth, route authority, or state. Its outputs are suggestions that must survive schema validation before they can influence simulation.
## **6.1 Parser responsibilities**
**•** Convert sanitized player text into a candidate action packet.

**•** Propose action type, target, method, stance, candidate skills, and whether a roll is likely required.

**•** Never propose state mutations, damage, rewards, or quest completion.
## **6.2 Validation rules**

|**Case**|**Example**|**Required behavior**|
| :-: | :-: | :-: |
|A. Unknown harmless field|Extra commentary string or non-semantic confidence note|Strip the field, log it, and continue if the remaining payload is valid.|
|B. Unknown semantic field|Injected state delta, hidden bonus target, fake difficulty class|Reject the entire parser output and do not partially execute it.|
|C. Missing required field|No action type or missing target for a targeted action|Retry parser once with stricter repair instructions; if it still fails, invoke deterministic fallback or ask for clarification.|

## **6.3 Deterministic fallback and clarification rules**
**•** If parser output fails and the same deterministic router/classifier can safely map the sanitized input into a known route category, continue with that category.

**•** If safe classification is not possible, request clarification instead of inventing missing intent.

**•** The system must never silently infer intent that changes risk, target, or legality of the action.

**•** If the same player intent remains ambiguous for three consecutive attempts within the same scene context, the system returns a neutral no-op response: no simulation, no state change, and a prompt to choose a clearer action.

**•** The ambiguity counter resets when the scene changes, the target changes, the input becomes materially different, or the deterministic route category changes.

|**Important edge case.** The deterministic fallback classifier is not a second independent engine. It is the same rules-based routing/classification layer used by the primary router. This prevents conflicting trust paths.|
| :- |

# **7. Deterministic Simulation Service and State Authority**
The simulation service is the product’s truth engine. It validates legality of actions, computes rolls, applies resource costs, produces canonical deltas, and emits the single authoritative revision object for the turn.
## **7.1 What the simulation service owns**
**•** Affordance validation: whether the player can currently attempt the action at all.

**•** Resource validation: health, mana, stamina, inventory possession, item durability, cooldowns, position/range, and knowledge requirements.

**•** Roll math: dice, stat modifiers, skill modifiers, situational modifiers, enemy defense or resistance, and success tier mapping.

**•** Consequence application: damage, healing, status effects, quest changes, relationship/faction shifts, item transfers, time progression, and location changes.

**•** Canonical event emission for downstream systems.
## **7.2 Success tiers and difficulty modes**

|**Tier**|**Meaning**|**Typical use**|
| :-: | :-: | :-: |
|Critical failure|The action fails badly and usually creates a worse future state.|Hard modes, unstable magic, dangerous combat, severe social failure.|
|Failure|The intended goal is not achieved.|Standard contested checks.|
|Partial success|The goal is partly achieved or achieved with a cost.|Easy mode, cinematic pacing, non-lethal progression, forgiving narrative flow.|
|Full success|The intended goal is achieved cleanly.|Standard successful roll outcome.|
|Critical success|The goal is achieved exceptionally well and may create a bonus effect.|High roll, specialized build, strong preparation, advantageous conditions.|

Difficulty modes may alter thresholds, penalties, and recovery rules, but they must not change the authoritative meanings of the tiers listed above. Easy mode may remove critical failure from ordinary checks if that is a product decision, but the system must document that explicitly and consistently.
## **7.3 Example action packet and simulation result**

|{<br>`  `"action\_type": "ATTACK\_BASIC",<br>`  `"target\_entity\_id": "enemy\_plague\_warden\_01",<br>`  `"method": "sword\_strike",<br>`  `"stance": "aggressive",<br>`  `"candidate\_skills": ["melee", "strength"],<br>`  `"requires\_roll": true<br>}<br><br>=><br><br>{<br>`  `"revision\_id": "rev\_008142",<br>`  `"success\_tier": "FULL\_SUCCESS",<br>`  `"roll": {"die": 17, "modifier": 5, "total": 22, "target": 16},<br>`  `"state\_delta": {"player": {"stamina": -4}, "enemy\_plague\_warden\_01": {"hp": -9, "status": ["BLEEDING"]}},<br>`  `"events": ["COMBAT\_TURN\_RESOLVED", "ENEMY\_STATUS\_APPLIED"],<br>`  `"summary\_flags": ["COMBAT\_ACTIVE"]<br>}|
| :- |

|**State mutation rule.** The narrator may describe the plague warden as reeling or bleeding, but that description is presentation. The authoritative bleeding status exists because the simulation result committed it, not because prose mentioned it.|
| :- |

# **8. Revision Model, Autosave, Rollback, and Persistence Guarantees**
Every committed turn creates one authoritative revision. Sub-events inside the turn do not independently create separate revisions, even if multiple important things happen at once. This eliminates duplicate checkpoint races and keeps rollback coherent.
## **8.1 Revision rules**
**•** A revision is the canonical persisted result of exactly one committed player turn or one explicit system-only state transition such as chapter initialization.

**•** Combat end, quest update, location change, and relationship threshold crossing may all occur inside one revision if they are consequences of the same turn.

**•** Autosave attaches to the committed revision, not to event names.

**•** Rollback checkpoints reference revision IDs, not triggers.
## **8.2 Authoritative revision payload**

|{<br>`  `"revision\_id": "rev\_008142",<br>`  `"previous\_revision\_id": "rev\_008141",<br>`  `"schema\_version": 3,<br>`  `"saved\_at": "2026-03-19T18:42:14Z",<br>`  `"player\_action": {...},<br>`  `"simulation\_result": {...},<br>`  `"canonical\_state": {...},<br>`  `"events": ["COMBAT\_ENDED", "QUEST\_UPDATED"],<br>`  `"autosave\_candidate": true,<br>`  `"summary\_job\_queued": true<br>}|
| :- |

## **8.3 Autosave policy**
**•** Autosave evaluation occurs after commit.

**•** A committed revision may be marked as autosave-eligible if it meets a configured importance policy, such as combat end, chapter boundary, quest update, or explicit user setting.

**•** Manual save is a guaranteed feature and is the primary user fallback when autosave is degraded.

**•** The system should keep a rolling window of autosaves plus protected manual saves and chapter-start checkpoints.
## **8.4 Rollback policy**
**•** Rollback restores a full canonical state snapshot associated with a selected revision or protected checkpoint.

**•** The platform should preserve at least the last N autosaves plus the latest stable chapter-start revision; the exact N is a product tuning decision, but it must be explicit in deployment policy.

**•** Manual save slots stay separate from the autosave ring.

**•** Rollback may not bypass schema validation. If a selected revision predates the current schema version, migration must succeed before the state is made live.
# **9. Memory Architecture, Summaries, and Continuity Triggers**
Long-term continuity must not rely on giant context windows alone. The system needs layered memory with distinct owners, distinct update policies, and bounded prompt packets for each downstream model.

|**Memory layer**|**Owner**|**Purpose**|**Update policy**|
| :-: | :-: | :-: | :-: |
|Canonical state|Simulation + persistence|Truth for stats, inventory, quests, world facts, locations, and relationships|Updated on every committed revision.|
|Recent context window|Session service|Short-term conversational continuity|Sliding window of the most recent turns or scene-local exchanges.|
|Pinned world facts|Content pipeline + simulation events|Immutable or rare-changing lore that must not drift|Manual content authoring plus specific simulation events.|
|Pinned player facts|Simulation|Player identity, class, origin, established background, and permanent conditions|Updated only on deliberate state changes.|
|Chapter summaries|Summary worker|Compact recap of major events to rehydrate later sessions|Generated by hard or soft summary triggers after commit.|
|Codex / discovered lore|Simulation + content pipeline|What the player has actually learned|Updated on knowledge-acquisition events.|

## **9.1 Summary trigger policy**
**•** Hard-summary job: queue immediately after commit when combat ends, quest state changes, chapter starts or ends, named location changes, relationship tier changes, faction standing crosses a threshold, downtime completes, a unique/rare item is acquired, or a severe permanent state change occurs such as death, jail, curse, or permanent injury.

**•** Soft-summary job: queue when 8 committed player turns have passed since the last successful summary and no hard-summary job has been created in those 8 turns.

**•** Debounce: maximum one summary job per committed revision. If multiple hard triggers fire in the same revision, they collapse into one summary job.

**•** Soft-summary suppression: after any hard-summary job is queued, soft summaries are suppressed for the next 3 committed revisions. Hard-summary jobs are never suppressed by this rule.

**•** Summary generation happens after commit and may fail asynchronously without blocking progression.
## **9.2 Relationship and faction tier thresholds**

|**Tier**|**Numeric range**|**Trigger on threshold crossing?**|
| :-: | :-: | :-: |
|Hostile|-100 to -51|Yes|
|Distrustful|-50 to -11|Yes|
|Neutral|-10 to 10|Yes|
|Warm|11 to 40|Yes|
|Loyal|41 to 75|Yes|
|Devoted|76 to 100|Yes|

A relationship summary trigger fires only when a committed revision causes a threshold crossing. Example: 8 to 14 triggers Neutral to Warm; 14 to 18 does not trigger; 45 to 39 triggers Loyal to Warm. Faction standing should follow the same threshold-crossing semantics if represented numerically.
# **10. Event Semantics and Downstream Consumers**
Canonical events are the glue between simulation, memory, persistence, analytics, UI refresh, and support tooling. They must be generated by the simulation service and treated as immutable facts for that revision.

|**Event**|**Producer**|**Typical consumers**|
| :-: | :-: | :-: |
|COMBAT\_ENDED|Simulation|Autosave evaluator, summary worker, analytics, combat UI teardown|
|QUEST\_UPDATED|Simulation|Quest panel, autosave evaluator, summary worker, notifications|
|LOCATION\_CHANGED|Simulation|Map panel, image worker, summary worker, travel UI|
|RELATIONSHIP\_TIER\_CHANGED|Simulation|Companion UI, summary worker, dialogue logic|
|FACTION\_THRESHOLD\_CROSSED|Simulation|Faction UI, summary worker, world event system|
|UNIQUE\_ITEM\_ACQUIRED|Simulation|Inventory UI, summary worker, achievement logic|
|DOWNTIME\_COMPLETED|Simulation|Summary worker, quest timers, resource updates|
|CHAPTER\_STARTED / CHAPTER\_ENDED|Simulation|Protected checkpoints, summary worker, recaps|

# **11. Failure-Handling Matrix and Graceful Degradation**
Failure handling must specify a fallback producer, retry policy, and state rule. Non-authoritative service failures may reduce richness, but they must not invalidate already committed truth.

|**Failure type**|**Fallback producer**|**Retry policy**|**State rule**|
| :-: | :-: | :-: | :-: |
|Parser failure|Deterministic router/classifier or clarification prompt|One parser repair retry, then deterministic fallback; after 3 consecutive ambiguity loops in the same scene, return neutral no-op|No state mutation before classification succeeds.|
|Narration timeout|Code-generated template renderer from simulation result|Optional one async retry with cheaper or shorter prompt; no blocking second wait by default|Committed state remains live; narration failure never rolls back truth.|
|Image generation failure|Placeholder art, existing area art, or no art|Optional manual retry and optional single background retry while scene remains active|Presentation-only failure; gameplay continues immediately.|
|Summary generation failure|Async retry, then minimal deterministic event-log recap|Retry on next eligible background cycle; after threshold, generate code-built recap|Canonical progression continues; mark summary\_pending until resolved.|
|Migration failure|Safe abort with export and restore options|Retry on demand only after preserving original save and quarantining failed copy|Original save remains untouched; no partial migrated state becomes live.|
|Autosave failure|In-memory committed state plus manual save prompt|Retry after next successful committed revision; warn after 3 consecutive failures|Persistence convenience degraded, not simulation correctness.|

## **11.1 Narration timeout fallback definition**
When the premium or default narrator exceeds the latency budget, the system must return concise narration rendered by code templates from the structured simulation result. Example: “You strike the plague warden for 9 damage. The enemy begins bleeding. You lose 4 stamina.” This fallback is authoritative enough for player understanding but clearly less stylistic than the normal narrator.
## **11.2 Migration failure and export format**
Any save exported for debugging after migration failure must be human-readable JSON or must be accompanied by a machine- and human-readable schema descriptor tied to its schema\_version. Handing support teams opaque binary blobs without a descriptor is not an acceptable fallback.
## **11.3 Autosave escalation**
If autosave fails for 3 consecutive committed revisions, the system must show a visible warning and prompt the player to create a manual save immediately. Manual save is guaranteed and is the product’s primary user fallback when autosave is degraded.

|**Failure-handling principle.** Any non-authoritative service failure must degrade presentation quality or convenience, but must not corrupt or roll back already committed canonical state.|
| :- |

# **12. Schema Versioning, Migration, and Save Export Rules**
Persistent save data must be versioned explicitly. The product should not assume that future code can deserialize older saves without migration. The recommended strategy for v1 and early growth is versioned snapshots with explicit migration scripts.
## **12.1 Required save metadata**

|{<br>`  `"save\_id": "save\_001",<br>`  `"schema\_version": 3,<br>`  `"game\_revision": "rev\_008142",<br>`  `"saved\_at": "2026-03-19T18:42:14Z",<br>`  `"campaign\_id": "campaign\_dark\_frontier\_01",<br>`  `"canonical\_state": {...}<br>}|
| :- |

## **12.2 Migration strategy**
**•** Every save includes a schema\_version field.

**•** Loading an older save runs sequential migration scripts such as v1\_to\_v2, then v2\_to\_v3, until the current version is reached.

**•** Migration scripts must be idempotent, tested, and capable of inserting explicit defaults for newly introduced fields.

**•** Original saves must never be overwritten in place before successful migration and validation.

**•** A migrated save should be written as a new revision or upgraded artifact after validation succeeds.
## **12.3 Why event sourcing is not the default recommendation for v1**
Event sourcing is powerful but operationally heavier. For this product’s early lifecycle, versioned snapshots with migration scripts offer a better balance of simplicity, debuggability, and testability. Event sourcing may be reconsidered later if replay, audit reconstruction, or highly granular analytics justify the added complexity.
# **13. Client Architecture in Flutter and UI Ownership Boundaries**
Flutter is a strong fit because the product is a state-heavy, cross-platform application with a chat-first interface, side panels, settings, saves, and optional media. It is not primarily a physics-driven or real-time action game. The client should be responsible for presentation, interaction, and local session state, not for authoritative game truth.
## **13.1 Recommended screen and panel model**
**•** Main story/chat panel with streamed narration or template fallback results.

**•** Action input bar with suggested quick actions plus free-text input.

**•** Persistent or tabbed panels for character sheet, inventory, quest log, codex, faction standings, and relationships.

**•** Save/load screen with manual save entry points and rollback-safe presentation of revisions or slots.

**•** Settings for content boundaries, narrative style, difficulty mode, accessibility options, and scene art preferences.
## **13.2 Client-side state categories**

|**State category**|**Owner**|**Examples**|
| :-: | :-: | :-: |
|Authoritative remote state|Backend|HP, mana, inventory, quest flags, location, world facts, relationship scores, schema version.|
|Derived presentation state|Client|Expanded/collapsed panels, tab selection, animation state, scroll position, cached art references.|
|Session convenience state|Client|Pending draft text, last viewed codex tab, temporary filters, local accessibility preferences.|
|Never-authoritative model text|Client render only|Narration paragraphs, tooltips, transient prose, generated art captions.|

## **13.3 Suggested code organization**

|lib/<br>`  `app/<br>`    `routing/<br>`    `theme/<br>`    `bootstrap/<br>`  `features/<br>`    `chat/<br>`    `character\_sheet/<br>`    `inventory/<br>`    `quests/<br>`    `codex/<br>`    `factions/<br>`    `saves/<br>`    `settings/<br>`  `domain/<br>`    `models/<br>`    `usecases/<br>`    `repositories/<br>`  `data/<br>`    `api/<br>`    `dto/<br>`    `mappers/<br>`    `local\_cache/<br>`  `shared/<br>`    `widgets/<br>`    `utils/<br>`    `accessibility/|
| :- |

State management may use Riverpod, Bloc, or another mature approach, but the architectural rule remains the same: authoritative truth arrives from backend revisions and validated APIs, not from local optimistic fabrication of game outcomes.
# **14. Operational Performance Targets, Observability, and Release Guidance**
A production document should not talk about latency philosophy without budgets. The exact numbers may change after testing, but the system needs target classes now so engineering, QA, and operations can evaluate trade-offs.

|**Path**|**Target**|**Notes**|
| :-: | :-: | :-: |
|Trivial UI action or non-roll deterministic action|p95 <= 800 ms|Includes route, simulation, and render payload generation.|
|Standard narrative turn|p95 <= 2.0 s|Allows normal narrator use under healthy conditions.|
|Complex/combat turn|p95 <= 3.0 s|Roll math plus narration under heavier load.|
|Autosave write|p95 <= 250 ms service target|May complete after client render if architecture uses background persistence ack.|
|Summary generation|Async|Must not block live turn completion.|
|Scene image generation|Soft target <= 6 s asynchronous|Gameplay proceeds without waiting; image may arrive late or be skipped.|

## **14.1 Observability requirements**
**•** Track route category frequencies, parser failure rates, clarification loops, narration timeout rate, image failure rate, summary backlog, autosave failure streaks, and migration success/failure rates.

**•** Log policy gateway decisions with policy flags but handle sensitive text carefully.

**•** Capture revision creation timing, summary job timing, and storage latency to support SLO monitoring.

**•** Build QA suites for state integrity, migration correctness, rollback fidelity, exploit handling, and continuity checks.
## **14.2 Release strategy**
**•** Prototype phase: one curated campaign, limited classes/origins, one difficulty baseline, one content profile, and one stable deployment profile for models.

**•** Beta phase: add more campaign packs, more explicit difficulty tuning, stronger analytics, and support tooling around failed saves and moderation events.

**•** General release: add broader deployment profile management, richer fallback assets, and support for safely evolving schema over time.
# **15. Deployment Profile and Model Neutrality**
The architecture should define model role requirements, not hard-code dependency on specific vendor SKU names. Model catalogs change quickly. Procurement and deployment choices should be captured in a separate deployment profile that can be refreshed without rewriting core architecture.

**•** Reasoning/parser helper tier requirements: strong structured output discipline, stable schema compliance, acceptable latency for ambiguity paths, and predictable cost.

**•** Narration tier requirements: high prose quality, style adherence, streaming support where useful, and bounded latency.

**•** Worker tier requirements: low cost, fast classification/summarization ability, and stable extraction behavior.

**•** Image tier requirements: consistent scene quality, reference-image or seed support where possible, and asynchronous API reliability.

|**Recommendation.** Keep the role requirements in the architecture document and place concrete vendor/model names in a separate Current Deployment Profile appendix or operational runbook so refreshes do not invalidate the architecture.|
| :- |

# **16. Implementation Checklist for a Production-Ready v1**
**1.** Implement the Safety/Policy Gateway with the four legal decisions: ALLOW, ALLOW\_WITH\_CONSTRAINTS, TRANSFORM, and REJECT.

**2.** Implement the deterministic router/classifier and ensure it owns both primary routing and parser-failure fallback routing.

**3.** Implement parser assistance only as an advisory helper behind sanitization and schema validation.

**4.** Implement the deterministic simulation service as the only writer to canonical state.

**5.** Define the revision payload and make one committed turn equal one authoritative revision.

**6.** Implement autosave, manual save, rollback, and protected chapter-start checkpoints.

**7.** Implement schema\_version and migration scripts before public persistence is considered stable.

**8.** Implement hard-summary and soft-summary triggers exactly as specified, including debounce and suppression rules.

**9.** Implement code-template narration fallback so narrator timeouts cannot leave the player without understandable results.

**10.** Implement exportable human-readable save debugging artifacts for migration failures.

**11.** Implement Flutter client screens for chat, sheet, inventory, quests, codex, factions/relationships, saves, and settings.

**12.** Build QA coverage for state integrity, exploit resistance, migration correctness, latency targets, and continuity regression.


# **Appendix A. Canonical State Ownership Summary**

|**State domain**|**Authoritative owner**|**Examples**|
| :-: | :-: | :-: |
|Player resources|Simulation service|HP, mana, stamina, gold, cooldowns, injuries|
|Inventory and equipment|Simulation service|Item possession, quantity, durability, equipped slots|
|Quest state|Simulation service|Active, failed, completed, hidden, timed branch state|
|World facts|Simulation service plus authored pinned facts|Known truth about locations, factions, discovered clues, and permanent world changes|
|Relationships/factions|Simulation service|Numeric standings and threshold tiers|
|Presentation prose|Narrator / client render|Descriptive paragraphs, tone, and emotional framing only|


# **Appendix B. Minimal Safety Gateway Decision Examples**

|ALLOW<br>{<br>`  `"decision": "ALLOW",<br>`  `"sanitized\_input": "I attack the bandit.",<br>`  `"policy\_flags": [],<br>`  `"narration\_constraints": []<br>}<br><br>ALLOW\_WITH\_CONSTRAINTS<br>{<br>`  `"decision": "ALLOW\_WITH\_CONSTRAINTS",<br>`  `"sanitized\_input": "I attack the bandit.",<br>`  `"policy\_flags": ["VIOLENCE\_LIMITED"],<br>`  `"narration\_constraints": ["NO\_GORE"]<br>}<br><br>TRANSFORM<br>{<br>`  `"decision": "TRANSFORM",<br>`  `"sanitized\_input": "I intimidate the prisoner for information.",<br>`  `"transformation\_reason": "Disallowed torture content removed",<br>`  `"policy\_flags": ["COERCION\_SOFTENED"],<br>`  `"narration\_constraints": ["NO\_GRAPHIC\_ABUSE"]<br>}<br><br>REJECT<br>{<br>`  `"decision": "REJECT",<br>`  `"player\_message": "That action is not allowed under your current content settings.",<br>`  `"policy\_flags": ["HARD\_BLOCK"],<br>`  `"retry\_allowed": true<br>}|
| :- |


# **Appendix C. Example Save Export Debug Bundle**
**•** original\_save.raw or original\_save.json

**•** decoded\_save.json (if live format is compressed or binary)

**•** schema\_descriptor\_vX.json or equivalent field map

**•** migration\_error\_report.txt with stack or validation summary

**•** campaign and revision metadata sufficient for support reproduction


# **Appendix D. Final Decision Record**
The production baseline for this product is now explicit: code owns truth, policy gateway owns safety, the deterministic router owns route categories, the parser is advisory only, the simulation service owns state mutation, and every committed turn produces one revision. This document should be treated as the authoritative engineering baseline until replaced by a newer version with an explicit change log.
Production Grade Architecture Document  |  Page 
