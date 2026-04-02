Build a complete Flutter UI for a production-grade AI Narrative RPG application.

This is not a generic chat app and not a real-time action game.
It is a cross-platform, chat-first, turn-based RPG client where:
- the backend owns authoritative state
- the simulation service owns game truth
- the client owns presentation, interaction, local session state, and accessibility
- narration text is presentation-only and never canonical state
- every committed player turn maps to one revision
- save/load and recap are first-class screens
- optional scene art is asynchronous and must never block gameplay

TECH STACK
- Flutter
- Desktop-first responsive layout, but still adaptable to tablet/mobile
- Clean folder structure
- Reusable widgets
- Strong theming system
- Mock local data only for now
- No backend integration yet, but structure the UI so it is ready for real APIs later

PROJECT GOAL
Generate all major pages/screens and shared components for the app UI.
The result should feel like a serious dark fantasy game product with polished app UX, not a toy demo.

VISUAL DIRECTION
Design language:
- premium dark fantasy
- elegant, readable, atmospheric
- near-black charcoal backgrounds
- deep ash/iron-gray surfaces
- muted bronze / aged gold accents
- parchment-gray readable cards and content surfaces
- restrained crimson for alerts, danger, injuries, hostile status
- clean readable sans-serif for most UI
- refined serif or semi-serif for major titles, location names, section headers
- subtle borders, layered panels, card depth, restrained ornament
- avoid clutter, neon, cartoon styling, generic SaaS design, or MMORPG chaos

ARCHITECTURAL RULES THE UI MUST RESPECT
- Do not fabricate authoritative outcomes locally
- Treat HP, mana, stamina, inventory, quests, world facts, location, relationship scores, faction standings, and save metadata as backend-owned authoritative state
- Treat narration text, art captions, and prose as render-only
- The client may own:
  - expanded/collapsed panels
  - selected tab
  - scroll state
  - draft player input
  - local filters
  - accessibility preferences
  - animation state
- The UI should visually distinguish system-truth from narrative flavor

INFORMATION ARCHITECTURE
Create these screens/pages:

1. Main Gameplay Screen
Purpose:
- primary play screen
- chat-first story interface
- action composer
- quick actions
- persistent status sidebar
- access to all other systems

Sections:
- top application bar
  - campaign title
  - current location
  - day/season/time
  - revision/save status
  - recap button
  - save button
  - settings button
- main story/narrative panel
  - scene title
  - streamed or block narration cards
  - player action cards
  - NPC dialogue cards
  - roll/check result cards
  - consequence summary cards
- action composer
  - text input
  - submit/act button
  - helper text
  - suggested action chips
- quick action strip
  - Talk
  - Inspect
  - Travel
  - Rest
  - Use Item
  - Observe
  - Negotiate
  - Cast
  - Inventory
- right status sidebar
  - character name
  - class/archetype
  - HP
  - stamina/mana
  - wounds/injuries
  - gold
  - statuses
  - equipped item summary
  - active objective
  - faction snapshot
  - relationship snapshot
- optional scene art panel or embedded atmospheric visual area that never overtakes the gameplay UI

2. Character Sheet Screen
Purpose:
- detailed player stats and build overview

Sections:
- profile header
  - portrait placeholder
  - name
  - class
  - background
  - origin
- core stats
  - strength
  - agility
  - willpower
  - presence
  - intellect
- derived combat/resource stats
- skills list
- traits/passives
- equipped gear summary
- permanent conditions / scars / curses
- progression section
- tabs or subsections for overview, combat, social, magic, history

3. Inventory Screen
Purpose:
- browse owned items and equipment

Sections:
- inventory search/filter bar
- category tabs
  - weapons
  - armor
  - consumables
  - quest items
  - materials
  - relics
- item list/grid
- selected item detail panel
  - item name
  - rarity
  - description
  - stats/effects
  - weight/stack count if relevant
  - action buttons like equip/use/inspect
- loadout summary
- currency/gold display

4. Quest Log Screen
Purpose:
- track active and completed quests with clarity

Sections:
- tabs
  - active
  - completed
  - failed
  - hidden/discovered if desired
- quest list with urgency and location
- selected quest detail panel
  - summary
  - objective steps
  - current state
  - related NPCs/factions
  - rewards
  - consequences
  - time pressure if present
- visual treatment for main quest vs side quest

5. Codex / Lore Journal Screen
Purpose:
- player-readable discovered knowledge only

Sections:
- category sidebar
  - locations
  - NPCs
  - creatures
  - factions
  - relics
  - history
  - discovered clues
- searchable codex entry list
- selected entry detail panel
- locked/undiscovered style treatment
- readable lore article layout
- note that only discovered info appears

6. Factions & Relationships Screen
Purpose:
- show structured social state

Sections:
- two top-level tabs:
  - factions
  - relationships
- faction cards with:
  - name
  - standing score / tier
  - icon/banner
  - short summary
  - stance toward player
- relationship cards with:
  - NPC name
  - role
  - trust / suspicion / loyalty / fear indicators
  - recent interaction summary
- detail view on selection
- threshold/tier visual style, but keep it elegant and readable

7. Map / World Screen
Purpose:
- overview of current area and discovered routes

Sections:
- region map panel
- discovered locations list
- current location highlight
- travel connections / route nodes
- danger indicators
- locked/unknown areas
- location details panel
  - description
  - controlling faction
  - danger level
  - recent events
- do not build an action game map; keep it strategic and information-centric

8. Saves / Load / Revision Screen
Purpose:
- manual saves, autosaves, rollback-safe presentation

Sections:
- autosaves tab
- manual saves tab
- protected checkpoint tab
- save slot cards with:
  - title
  - timestamp
  - revision id
  - location
  - chapter/quest snapshot
- save detail modal/panel
- load confirmation
- rollback warning UI
- export/debug-ready visual placeholders if needed
- show that saves are revision-based, not random narrative snapshots

9. Recap Screen
Purpose:
- “Previously in your story” / chapter summaries

Sections:
- latest recap hero panel
- chapter summaries timeline
- recent major events list
- current unresolved threads
- last known location/objective
- clean reading mode
- support concise and expanded recap cards

10. Settings Screen
Purpose:
- app preferences and content controls

Sections:
- gameplay settings
  - difficulty
  - narration density
  - quick actions visibility
- content boundary settings
  - violence level
  - romance toggle
  - horror toggle
  - mature themes toggle
  - custom exclusions placeholder
- accessibility
  - font size
  - contrast
  - reduce motion
  - screen reader friendliness
- visual settings
  - scene art on/off
  - animation preferences
  - UI density
- account/system placeholders
- save/data management placeholders

11. Character Creation / New Campaign Flow
Purpose:
- onboarding into a new run

Pages or steps:
- welcome / choose campaign
- choose class
- choose background/origin
- choose boon/flaw
- enter name/pronouns
- review build
- start campaign
This flow should feel premium and dramatic, but still clear and app-like.

12. Campaign Selection Screen
Purpose:
- curated campaigns first

Sections:
- featured campaign cards
- difficulty indicator
- estimated length
- tone tags
- world summary
- continue campaign / new campaign actions

13. Loading / Empty / Error / Fallback States
Create polished states for:
- empty quest log
- no codex entries yet
- no scene art available
- narration fallback card
- autosave degraded warning
- connection error banner
- safe reject / clarification required response card
These states matter and should match the main design system.

NAVIGATION MODEL
Use a scalable app shell:
- desktop: sidebar + top bar + content region
- smaller screens: collapsible nav / drawer
Recommended global navigation destinations:
- Play
- Character
- Inventory
- Quests
- Codex
- Factions
- Map
- Saves
- Recap
- Settings

COMPONENTS TO BUILD
Create reusable widgets/components:
- AppShell
- TopCampaignBar
- SidebarNav
- StoryCard
- DialogueCard
- PlayerActionCard
- RollResultCard
- ConsequenceCard
- StatusSidebar
- StatPill
- QuestCard
- CodexEntryCard
- RelationshipCard
- FactionCard
- SaveSlotCard
- SectionHeader
- QuickActionChip
- PrimaryButton / SecondaryButton / DangerButton
- SearchBar
- FilterTabs
- EmptyStateCard
- WarningBanner
- SettingsToggleRow
- SceneArtFrame
- PanelContainer
- RevisionStatusBadge

MOCK DATA
Use believable placeholder dark fantasy data throughout:
- campaign title
- current location
- faction names
- NPC names
- active quests
- inventory items
- codex entries
- save slot metadata
- relationship/faction values
Keep the world consistent across pages.

FOLDER STRUCTURE
Use this approximate organization:

lib/
  app/
    bootstrap/
    routing/
    theme/
  features/
    play/
    character_sheet/
    inventory/
    quests/
    codex/
    factions/
    map/
    saves/
    recap/
    settings/
    campaign_selection/
    character_creation/
  domain/
    models/
    usecases/
    repositories/
  data/
    dto/
    mappers/
    local_cache/
    mock/
  shared/
    widgets/
    utils/
    accessibility/

IMPLEMENTATION RULES
- Use clean, maintainable Flutter code
- Prefer reusable widgets over giant files
- Separate screens from components
- Create theme constants for colors, spacing, radius, typography
- Use mock repositories / seeded sample data
- Make desktop layout polished
- Add comments only where useful
- Do not wire real networking yet
- Do not implement real gameplay logic
- Do not fake canonical state mutation rules in the client
- Build the UI so it is ready to receive backend revisions later

DELIVERABLE
Generate:
- all screen/page files
- shared theme files
- reusable components
- mock models/data
- routing/navigation setup
- a polished desktop-first dark fantasy UI skeleton for the full application

Start by creating:
1. app shell
2. theme
3. navigation
4. main gameplay screen
5. remaining screens
6. reusable components
7. mock data