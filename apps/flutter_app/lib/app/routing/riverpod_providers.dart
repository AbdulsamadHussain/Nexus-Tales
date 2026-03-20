import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/game_models.dart';

part 'riverpod_providers.freezed.dart';

/// ============================================================================
/// AUTHORITATIVE REMOTE STATE (Backend-owned, revision-scoped)
/// ============================================================================

/// Current active player character (from backend).
final currentCharacterProvider = StateProvider<PlayerCharacter?>(
  (ref) => null,
  name: 'authoritative_character',
);

/// Current active quest list (from backend).
final questListProvider = StateProvider<List<Quest>>(
  (ref) => [],
  name: 'authoritative_quests',
);

/// Current inventory (from backend).
final inventoryProvider = StateProvider<List<InventoryItem>>(
  (ref) => [],
  name: 'authoritative_inventory',
);

/// Discovered codex entries (from backend).
final codexEntriesProvider = StateProvider<List<CodexEntry>>(
  (ref) => [],
  name: 'authoritative_codex',
);

/// Faction standings (from backend).
final factionsProvider = StateProvider<List<Faction>>(
  (ref) => [],
  name: 'authoritative_factions',
);

/// NPC relationships (from backend).
final relationshipsProvider = StateProvider<List<Relationship>>(
  (ref) => [],
  name: 'authoritative_relationships',
);

/// Current scene/location (from backend).
final currentSceneProvider = StateProvider<Scene?>(
  (ref) => null,
  name: 'authoritative_scene',
);

/// All available save slots (from backend).
final saveSlotsProvider = StateProvider<List<SaveSlot>>(
  (ref) => [],
  name: 'authoritative_save_slots',
);

/// Current revision ID and timestamp.
final currentRevisionProvider = StateProvider<({String id, DateTime timestamp})?>(
  (ref) => null,
  name: 'authoritative_revision',
);

/// List of available campaigns.
final campaignListProvider = StateProvider<List<Campaign>>(
  (ref) => [],
  name: 'authoritative_campaigns',
);

/// Current campaign metadata.
final currentCampaignProvider = StateProvider<Campaign?>(
  (ref) => null,
  name: 'authoritative_campaign',
);

/// ============================================================================
/// LOCAL PRESENTATION STATE (Ephemeral UI state, not authoritative)
/// ============================================================================

/// Currently selected quest in the quest view.
final selectedQuestProvider = StateProvider<Quest?>(
  (ref) => null,
  name: 'local_selected_quest',
);

/// Currently selected codex entry.
final selectedCodexEntryProvider = StateProvider<CodexEntry?>(
  (ref) => null,
  name: 'local_selected_codex',
);

/// Currently selected faction.
final selectedFactionProvider = StateProvider<Faction?>(
  (ref) => null,
  name: 'local_selected_faction',
);

/// Currently selected item in inventory.
final selectedInventoryItemProvider = StateProvider<InventoryItem?>(
  (ref) => null,
  name: 'local_selected_item',
);

/// Expanded/collapsed state of side panel.
final sidePanelExpandedProvider = StateProvider<bool>(
  (ref) => true,
  name: 'local_side_panel_expanded',
);

/// Active tab in character sheet.
final characterSheetTabProvider = StateProvider<String>(
  (ref) => 'overview',
  name: 'local_character_tab',
);

/// Active tab in inventory view.
final inventoryTabProvider = StateProvider<String>(
  (ref) => 'equipped',
  name: 'local_inventory_tab',
);

/// Search/filter text in various lists.
final searchQueryProvider = StateProvider<String>(
  (ref) => '',
  name: 'local_search_query',
);

/// Scroll position tracking key.
final scrollOffsetProvider = StateProvider<Map<String, double>>(
  (ref) => {},
  name: 'local_scroll_offsets',
);

/// ============================================================================
/// DRAFT / INPUT STATE (Unsaved user input, pending submission)
/// ============================================================================

@freezed
class DraftAction with _$DraftAction {
  const factory DraftAction({
    required String text,
    required String? quickActionType,
    required bool hasClarificationPending,
    @Default('') String clarificationPrompt,
  }) = _DraftAction;
}

/// Current draft player action being composed.
final draftActionProvider = StateProvider<DraftAction>(
  (ref) => const DraftAction(
    text: '',
    quickActionType: null,
    hasClarificationPending: false,
  ),
  name: 'draft_action',
);

/// Content boundary settings (user preferences, local only until saved).
@freezed
class ContentSettings with _$ContentSettings {
  const factory ContentSettings({
    @Default('medium') String violenceLevel,
    @Default(true) bool romanceEnabled,
    @Default(true) bool horrorEnabled,
    @Default(true) bool matureThemesEnabled,
    @Default(true) bool betrayalEnabled,
    @Default([]) List<String> customExclusions,
  }) = _ContentSettings;
}

final contentSettingsProvider = StateProvider<ContentSettings>(
  (ref) => const ContentSettings(),
  name: 'draft_content_settings',
);

/// Game difficulty preference (not yet committed).
final difficultySettingProvider = StateProvider<String>(
  (ref) => 'seasoned',
  name: 'draft_difficulty',
);

/// Accessibility settings (local user preferences).
@freezed
class AccessibilitySettings with _$AccessibilitySettings {
  const factory AccessibilitySettings({
    @Default(1.0) double fontSizeMultiplier,
    @Default(false) bool highContrast,
    @Default(false) bool reduceMotion,
    @Default(false) bool screenReaderMode,
  }) = _AccessibilitySettings;
}

final accessibilitySettingsProvider = StateProvider<AccessibilitySettings>(
  (ref) => const AccessibilitySettings(),
  name: 'draft_accessibility',
);

/// Pending clarification answer from player.
final clarificationAnswerProvider = StateProvider<String?>(
  (ref) => null,
  name: 'draft_clarification_answer',
);

/// ============================================================================
/// DERIVED / COMPUTED PROVIDERS
/// ============================================================================

/// Filtered quest list based on search and status.
final filteredQuestsProvider = Provider<List<Quest>>(
  (ref) {
    final quests = ref.watch(questListProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    
    if (searchQuery.isEmpty) return quests;
    
    return quests.where((quest) {
      return quest.title.toLowerCase().contains(searchQuery) ||
          quest.description.toLowerCase().contains(searchQuery);
    }).toList();
  },
  name: 'derived_filtered_quests',
);

/// Calculate derived combat stats from base stats.
final derivedStatsProvider = Provider<Map<String, int>>(
  (ref) {
    final character = ref.watch(currentCharacterProvider);
    if (character == null) return {};

    final stats = Map<String, int>.from(character.stats);
    
    // Example derived calculations
    stats['armor'] = (stats['strength'] ?? 0) ~/ 2;
    stats['dodge'] = (stats['agility'] ?? 0) ~/ 2;
    stats['spellDefense'] = (stats['willpower'] ?? 0) ~/ 2;
    
    return stats;
  },
  name: 'derived_combat_stats',
);

/// Total equipped weight.
final equippedWeightProvider = Provider<int>(
  (ref) {
    final inventory = ref.watch(inventoryProvider);
    final character = ref.watch(currentCharacterProvider);
    
    if (character == null) return 0;
    
    final equippedIds = character.equippedItems;
    int totalWeight = 0;
    
    for (final item in inventory) {
      if (equippedIds.contains(item.id)) {
        totalWeight += item.weight;
      }
    }
    
    return totalWeight;
  },
  name: 'derived_equipped_weight',
);

/// Check if player is in critical condition.
final isCriticalProvider = Provider<bool>(
  (ref) {
    final character = ref.watch(currentCharacterProvider);
    if (character == null) return false;
    
    final healthPercent = (character.healthPoints / character.maxHealthPoints) * 100;
    return healthPercent <= 25;
  },
  name: 'derived_is_critical',
);

/// ============================================================================
/// UTILITY PROVIDERS (For form validation, etc.)
/// ============================================================================

/// Whether a turn submission is currently in flight.
final isSubmittingTurnProvider = StateProvider<bool>(
  (ref) => false,
  name: 'utility_is_submitting',
);

/// Last error message from backend.
final lastErrorProvider = StateProvider<String?>(
  (ref) => null,
  name: 'utility_last_error',
);

/// Currently loading state.
final isLoadingProvider = StateProvider<bool>(
  (ref) => false,
  name: 'utility_is_loading',
);
