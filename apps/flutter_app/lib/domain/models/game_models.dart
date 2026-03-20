import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_models.freezed.dart';
part 'game_models.g.dart';

/// Represents the player character.
@freezed
class PlayerCharacter with _$PlayerCharacter {
  const factory PlayerCharacter({
    required String id,
    required String name,
    required String archetype,
    required String background,
    required String pronouns,
    required int healthPoints,
    required int maxHealthPoints,
    required int stamina,
    required int maxStamina,
    required int mana,
    required int maxMana,
    required Map<String, int> stats, // str, agi, willpower, presence, intellect
    required int gold,
    required List<String> equippedItems,
    required List<String> wounds,
    required List<String> activeConditions,
    required Map<String, int> skillLevels,
    required int experience,
    required int level,
    @Default([]) List<String> passiveTraits,
  }) = _PlayerCharacter;

  factory PlayerCharacter.fromJson(Map<String, dynamic> json) =>
      _$PlayerCharacterFromJson(json);
}

/// Represents a quest or objective.
@freezed
class Quest with _$Quest {
  const factory Quest({
    required String id,
    required String title,
    required String description,
    required String status, // active, completed, failed, hidden
    required String questType, // main, side, hidden
    required String location,
    required List<String> objectives,
    required int currentObjectiveIndex,
    required List<String> rewardItems,
    required int rewardGold,
    required int rewardExperience,
    @Default(0) int timeLimit,
    @Default([]) List<String> relatedNPCs,
  }) = _Quest;

  factory Quest.fromJson(Map<String, dynamic> json) =>
      _$QuestFromJson(json);
}

/// Represents an inventory item.
@freezed
class InventoryItem with _$InventoryItem {
  const factory InventoryItem({
    required String id,
    required String name,
    required String description,
    required String itemType, // weapon, armor, consumable, quest, material, relic
    required String rarity, // common, uncommon, rare, legendary, mythic
    required int quantity,
    @Default(0) int weight,
    @Default({}) Map<String, dynamic> effects,
  }) = _InventoryItem;

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
}

/// Represents a discovered codex entry (lore).
@freezed
class CodexEntry with _$CodexEntry {
  const factory CodexEntry({
    required String id,
    required String title,
    required String category, // location, npc, creature, faction, relic, history, clue
    required String content,
    required bool discovered,
    @Default('') String relatedId,
    @Default(0) int discoveredAtRevision,
  }) = _CodexEntry;

  factory CodexEntry.fromJson(Map<String, dynamic> json) =>
      _$CodexEntryFromJson(json);
}

/// Represents a faction or organization.
@freezed
class Faction with _$Faction {
  const factory Faction({
    required String id,
    required String name,
    required String description,
    required int standing, // -100 to 100
    required String tier, // hostile, unfriendly, neutral, friendly, allied
    @Default('') String banner,
    @Default('') String controlledArea,
    @Default([]) List<String> knownActions,
  }) = _Faction;

  factory Faction.fromJson(Map<String, dynamic> json) =>
      _$FactionFromJson(json);
}

/// Represents a relationship with an NPC.
@freezed
class Relationship with _$Relationship {
  const factory Relationship({
    required String npcId,
    required String npcName,
    required String role, // ally, rival, mentor, love, enemy, neutral
    required int trustScore, // -100 to 100
    required int suspicion, // 0 to 100
    required int loyalty, // -100 to 100
    required int fearLevel, // 0 to 100
    @Default('') String lastInteraction,
  }) = _Relationship;

  factory Relationship.fromJson(Map<String, dynamic> json) =>
      _$RelationshipFromJson(json);
}

/// Represents a game save slot.
@freezed
class SaveSlot with _$SaveSlot {
  const factory SaveSlot({
    required String id,
    required String campaignTitle,
    required String characterName,
    required String location,
    required String currentChapter,
    required DateTime lastSavedAt,
    required bool isAutosave,
    required bool isCheckpoint,
    required int revisionNumber,
    required int playtimeMinutes,
    @Default('') String thumbnailUrl,
  }) = _SaveSlot;

  factory SaveSlot.fromJson(Map<String, dynamic> json) =>
      _$SaveSlotFromJson(json);
}

/// Represents a turn result from the backend (authoritative).
@freezed
class TurnResult with _$TurnResult {
  const factory TurnResult({
    required String revisionId,
    required String actionSummary,
    required List<String> canonicalEvents,
    required int authorityVersion,
    required DateTime committedAt,
    required Map<String, dynamic> stateDelta, // What changed in player state
    @Default([]) List<String> narrativeBlocks, // Prose narration
    @Default('') String sceneSuggestion, // Image anchor for async art
  }) = _TurnResult;

  factory TurnResult.fromJson(Map<String, dynamic> json) =>
      _$TurnResultFromJson(json);
}

/// Represents a scene/location in the world.
@freezed
class Scene with _$Scene {
  const factory Scene({
    required String id,
    required String title,
    required String description,
    required String controllingFaction,
    required String dangerLevel, // safe, moderate, dangerous, deadly
    @Default('') String artPath,
    @Default([]) List<String> npcsPresent,
    @Default([]) List<String> availableActions,
  }) = _Scene;

  factory Scene.fromJson(Map<String, dynamic> json) =>
      _$SceneFromJson(json);
}

/// Represents a game world region.
@freezed
class Region with _$Region {
  const factory Region({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> discoveredLocations,
    @Default([]) List<String> routes,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) =>
      _$RegionFromJson(json);
}

/// Represents campaign metadata.
@freezed
class Campaign with _$Campaign {
  const factory Campaign({
    required String id,
    required String title,
    required String description,
    required String difficulty, // story, seasoned, legendary
    required String tone, // noir, heroic, gritty, mystical, dark
    required int estimatedLengthHours,
    @Default([]) List<String> tags,
    @Default('') String worldSummary,
  }) = _Campaign;

  factory Campaign.fromJson(Map<String, dynamic> json) =>
      _$CampaignFromJson(json);
}
