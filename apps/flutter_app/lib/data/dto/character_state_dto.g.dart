// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_state_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItemDto _$InventoryItemDtoFromJson(Map<String, dynamic> json) =>
    InventoryItemDto(
      itemId: json['item_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      itemType: json['item_type'] as String,
      quantity: (json['quantity'] as num).toInt(),
      equipped: json['equipped'] as bool?,
      rarity: json['rarity'] as String?,
    );

Map<String, dynamic> _$InventoryItemDtoToJson(InventoryItemDto instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'name': instance.name,
      'description': instance.description,
      'item_type': instance.itemType,
      'quantity': instance.quantity,
      'equipped': instance.equipped,
      'rarity': instance.rarity,
    };

QuestDto _$QuestDtoFromJson(Map<String, dynamic> json) => QuestDto(
      questId: json['quest_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questStage: json['quest_stage'] as String,
      progress: (json['progress'] as num?)?.toInt(),
      progressMax: (json['progress_max'] as num?)?.toInt(),
      completed: json['completed'] as bool,
      rewardPreview: json['reward_preview'] as String?,
      objectives: (json['objectives'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuestDtoToJson(QuestDto instance) => <String, dynamic>{
      'quest_id': instance.questId,
      'title': instance.title,
      'description': instance.description,
      'quest_stage': instance.questStage,
      'progress': instance.progress,
      'progress_max': instance.progressMax,
      'completed': instance.completed,
      'reward_preview': instance.rewardPreview,
      'objectives': instance.objectives,
    };

CodexEntryDto _$CodexEntryDtoFromJson(Map<String, dynamic> json) =>
    CodexEntryDto(
      entryId: json['entry_id'] as String,
      entryType: json['entry_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discovered: json['discovered'] as bool,
      discoveredAt: json['discovered_at'] == null
          ? null
          : DateTime.parse(json['discovered_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CodexEntryDtoToJson(CodexEntryDto instance) =>
    <String, dynamic>{
      'entry_id': instance.entryId,
      'entry_type': instance.entryType,
      'title': instance.title,
      'description': instance.description,
      'discovered': instance.discovered,
      'discovered_at': instance.discoveredAt?.toIso8601String(),
      'metadata': instance.metadata,
    };

FactionDto _$FactionDtoFromJson(Map<String, dynamic> json) => FactionDto(
      factionId: json['faction_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      standing: (json['standing'] as num).toInt(),
      standingLevel: json['standing_level'] as String,
      banner: json['banner'] as String?,
    );

Map<String, dynamic> _$FactionDtoToJson(FactionDto instance) =>
    <String, dynamic>{
      'faction_id': instance.factionId,
      'name': instance.name,
      'description': instance.description,
      'standing': instance.standing,
      'standing_level': instance.standingLevel,
      'banner': instance.banner,
    };

RelationshipDto _$RelationshipDtoFromJson(Map<String, dynamic> json) =>
    RelationshipDto(
      npcId: json['npc_id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      affinity: (json['affinity'] as num).toInt(),
      affinityLevel: json['affinity_level'] as String,
      description: json['description'] as String?,
      lastInteraction: json['last_interaction'] == null
          ? null
          : DateTime.parse(json['last_interaction'] as String),
    );

Map<String, dynamic> _$RelationshipDtoToJson(RelationshipDto instance) =>
    <String, dynamic>{
      'npc_id': instance.npcId,
      'name': instance.name,
      'title': instance.title,
      'affinity': instance.affinity,
      'affinity_level': instance.affinityLevel,
      'description': instance.description,
      'last_interaction': instance.lastInteraction?.toIso8601String(),
    };

CharacterStateDto _$CharacterStateDtoFromJson(Map<String, dynamic> json) =>
    CharacterStateDto(
      characterId: json['character_id'] as String,
      name: json['name'] as String,
      className: json['class_name'] as String,
      classDescription: json['class_description'] as String,
      level: (json['level'] as num).toInt(),
      experience: (json['experience'] as num).toInt(),
      experienceMax: (json['experience_max'] as num).toInt(),
      hp: (json['hp'] as num).toInt(),
      hpMax: (json['hp_max'] as num).toInt(),
      stamina: (json['stamina'] as num).toInt(),
      staminaMax: (json['stamina_max'] as num).toInt(),
      mana: (json['mana'] as num).toInt(),
      manaMax: (json['mana_max'] as num).toInt(),
      strength: (json['strength'] as num?)?.toInt(),
      dexterity: (json['dexterity'] as num?)?.toInt(),
      constitution: (json['constitution'] as num?)?.toInt(),
      intelligence: (json['intelligence'] as num?)?.toInt(),
      wisdom: (json['wisdom'] as num?)?.toInt(),
      charisma: (json['charisma'] as num?)?.toInt(),
      gold: (json['gold'] as num).toInt(),
      resources: (json['resources'] as num?)?.toInt(),
      currentLocation: json['current_location'] as String?,
      inventory: (json['inventory'] as List<dynamic>?)
          ?.map((e) => InventoryItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      quests: (json['quests'] as List<dynamic>?)
          ?.map((e) => QuestDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      codex: (json['codex'] as List<dynamic>?)
          ?.map((e) => CodexEntryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      factions: (json['factions'] as List<dynamic>?)
          ?.map((e) => FactionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List<dynamic>?)
          ?.map((e) => RelationshipDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$CharacterStateDtoToJson(CharacterStateDto instance) =>
    <String, dynamic>{
      'character_id': instance.characterId,
      'name': instance.name,
      'class_name': instance.className,
      'class_description': instance.classDescription,
      'level': instance.level,
      'experience': instance.experience,
      'experience_max': instance.experienceMax,
      'hp': instance.hp,
      'hp_max': instance.hpMax,
      'stamina': instance.stamina,
      'stamina_max': instance.staminaMax,
      'mana': instance.mana,
      'mana_max': instance.manaMax,
      'strength': instance.strength,
      'dexterity': instance.dexterity,
      'constitution': instance.constitution,
      'intelligence': instance.intelligence,
      'wisdom': instance.wisdom,
      'charisma': instance.charisma,
      'gold': instance.gold,
      'resources': instance.resources,
      'current_location': instance.currentLocation,
      'inventory': instance.inventory,
      'quests': instance.quests,
      'codex': instance.codex,
      'factions': instance.factions,
      'relationships': instance.relationships,
      'last_updated': instance.lastUpdated?.toIso8601String(),
    };
