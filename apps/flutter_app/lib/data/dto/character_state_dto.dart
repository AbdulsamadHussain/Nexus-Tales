import 'package:json_annotation/json_annotation.dart';

part 'character_state_dto.g.dart';

/// Inventory item DTO
@JsonSerializable()
class InventoryItemDto {
  @JsonKey(name: 'item_id')
  final String itemId;

  final String name;

  final String description;

  @JsonKey(name: 'item_type')
  final String itemType;

  final int quantity;

  final bool? equipped;

  @JsonKey(name: 'rarity')
  final String? rarity;

  InventoryItemDto({
    required this.itemId,
    required this.name,
    required this.description,
    required this.itemType,
    required this.quantity,
    this.equipped,
    this.rarity,
  });

  factory InventoryItemDto.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemDtoToJson(this);
}

/// Quest progression DTO
@JsonSerializable()
class QuestDto {
  @JsonKey(name: 'quest_id')
  final String questId;

  final String title;

  final String description;

  @JsonKey(name: 'quest_stage')
  final String questStage;

  final int? progress;

  @JsonKey(name: 'progress_max')
  final int? progressMax;

  final bool completed;

  @JsonKey(name: 'reward_preview')
  final String? rewardPreview;

  final List<String>? objectives;

  QuestDto({
    required this.questId,
    required this.title,
    required this.description,
    required this.questStage,
    this.progress,
    this.progressMax,
    required this.completed,
    this.rewardPreview,
    this.objectives,
  });

  factory QuestDto.fromJson(Map<String, dynamic> json) =>
      _$QuestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuestDtoToJson(this);
}

/// Codex entry DTO
@JsonSerializable()
class CodexEntryDto {
  @JsonKey(name: 'entry_id')
  final String entryId;

  @JsonKey(name: 'entry_type')
  final String entryType; // 'LORE', 'NPC', 'LOCATION', 'CREATURE', etc.

  final String title;

  final String description;

  final bool discovered;

  @JsonKey(name: 'discovered_at')
  final DateTime? discoveredAt;

  final Map<String, dynamic>? metadata;

  CodexEntryDto({
    required this.entryId,
    required this.entryType,
    required this.title,
    required this.description,
    required this.discovered,
    this.discoveredAt,
    this.metadata,
  });

  factory CodexEntryDto.fromJson(Map<String, dynamic> json) =>
      _$CodexEntryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CodexEntryDtoToJson(this);
}

/// Faction standing DTO
@JsonSerializable()
class FactionDto {
  @JsonKey(name: 'faction_id')
  final String factionId;

  final String name;

  final String description;

  final int standing;

  @JsonKey(name: 'standing_level')
  final String standingLevel; // 'HOSTILE', 'WARY', 'NEUTRAL', 'FRIENDLY', 'ALLIED'

  final String? banner;

  FactionDto({
    required this.factionId,
    required this.name,
    required this.description,
    required this.standing,
    required this.standingLevel,
    this.banner,
  });

  factory FactionDto.fromJson(Map<String, dynamic> json) =>
      _$FactionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FactionDtoToJson(this);
}

/// Relationship DTO
@JsonSerializable()
class RelationshipDto {
  @JsonKey(name: 'npc_id')
  final String npcId;

  final String name;

  final String title;

  final int affinity;

  @JsonKey(name: 'affinity_level')
  final String affinityLevel; // 'HOSTILE', 'COLD', 'NEUTRAL', 'WARM', 'INTIMATE'

  final String? description;

  @JsonKey(name: 'last_interaction')
  final DateTime? lastInteraction;

  RelationshipDto({
    required this.npcId,
    required this.name,
    required this.title,
    required this.affinity,
    required this.affinityLevel,
    this.description,
    this.lastInteraction,
  });

  factory RelationshipDto.fromJson(Map<String, dynamic> json) =>
      _$RelationshipDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RelationshipDtoToJson(this);
}

/// Player character state DTO
@JsonSerializable()
class CharacterStateDto {
  @JsonKey(name: 'character_id')
  final String characterId;

  final String name;

  @JsonKey(name: 'class_name')
  final String className;

  @JsonKey(name: 'class_description')
  final String classDescription;

  final int level;

  final int experience;

  @JsonKey(name: 'experience_max')
  final int experienceMax;

  // Stats
  final int hp;

  @JsonKey(name: 'hp_max')
  final int hpMax;

  final int stamina;

  @JsonKey(name: 'stamina_max')
  final int staminaMax;

  final int mana;

  @JsonKey(name: 'mana_max')
  final int manaMax;

  // Abilities
  @JsonKey(name: 'strength')
  final int? strength;

  @JsonKey(name: 'dexterity')
  final int? dexterity;

  @JsonKey(name: 'constitution')
  final int? constitution;

  @JsonKey(name: 'intelligence')
  final int? intelligence;

  @JsonKey(name: 'wisdom')
  final int? wisdom;

  @JsonKey(name: 'charisma')
  final int? charisma;

  // Gold and resources
  final int gold;

  final int? resources;

  // Current location
  @JsonKey(name: 'current_location')
  final String? currentLocation;

  // Inventory and quests
  final List<InventoryItemDto>? inventory;
  final List<QuestDto>? quests;
  final List<CodexEntryDto>? codex;
  final List<FactionDto>? factions;
  final List<RelationshipDto>? relationships;

  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;

  CharacterStateDto({
    required this.characterId,
    required this.name,
    required this.className,
    required this.classDescription,
    required this.level,
    required this.experience,
    required this.experienceMax,
    required this.hp,
    required this.hpMax,
    required this.stamina,
    required this.staminaMax,
    required this.mana,
    required this.manaMax,
    this.strength,
    this.dexterity,
    this.constitution,
    this.intelligence,
    this.wisdom,
    this.charisma,
    required this.gold,
    this.resources,
    this.currentLocation,
    this.inventory,
    this.quests,
    this.codex,
    this.factions,
    this.relationships,
    this.lastUpdated,
  });

  factory CharacterStateDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterStateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CharacterStateDtoToJson(this);
}
