// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerCharacterImpl _$$PlayerCharacterImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerCharacterImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      archetype: json['archetype'] as String,
      background: json['background'] as String,
      pronouns: json['pronouns'] as String,
      healthPoints: (json['healthPoints'] as num).toInt(),
      maxHealthPoints: (json['maxHealthPoints'] as num).toInt(),
      stamina: (json['stamina'] as num).toInt(),
      maxStamina: (json['maxStamina'] as num).toInt(),
      mana: (json['mana'] as num).toInt(),
      maxMana: (json['maxMana'] as num).toInt(),
      stats: Map<String, int>.from(json['stats'] as Map),
      gold: (json['gold'] as num).toInt(),
      equippedItems: (json['equippedItems'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      wounds:
          (json['wounds'] as List<dynamic>).map((e) => e as String).toList(),
      activeConditions: (json['activeConditions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      skillLevels: Map<String, int>.from(json['skillLevels'] as Map),
      experience: (json['experience'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      passiveTraits: (json['passiveTraits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerCharacterImplToJson(
        _$PlayerCharacterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'archetype': instance.archetype,
      'background': instance.background,
      'pronouns': instance.pronouns,
      'healthPoints': instance.healthPoints,
      'maxHealthPoints': instance.maxHealthPoints,
      'stamina': instance.stamina,
      'maxStamina': instance.maxStamina,
      'mana': instance.mana,
      'maxMana': instance.maxMana,
      'stats': instance.stats,
      'gold': instance.gold,
      'equippedItems': instance.equippedItems,
      'wounds': instance.wounds,
      'activeConditions': instance.activeConditions,
      'skillLevels': instance.skillLevels,
      'experience': instance.experience,
      'level': instance.level,
      'passiveTraits': instance.passiveTraits,
    };

_$QuestImpl _$$QuestImplFromJson(Map<String, dynamic> json) => _$QuestImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      questType: json['questType'] as String,
      location: json['location'] as String,
      objectives: (json['objectives'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      currentObjectiveIndex: (json['currentObjectiveIndex'] as num).toInt(),
      rewardItems: (json['rewardItems'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rewardGold: (json['rewardGold'] as num).toInt(),
      rewardExperience: (json['rewardExperience'] as num).toInt(),
      timeLimit: (json['timeLimit'] as num?)?.toInt() ?? 0,
      relatedNPCs: (json['relatedNPCs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$QuestImplToJson(_$QuestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'questType': instance.questType,
      'location': instance.location,
      'objectives': instance.objectives,
      'currentObjectiveIndex': instance.currentObjectiveIndex,
      'rewardItems': instance.rewardItems,
      'rewardGold': instance.rewardGold,
      'rewardExperience': instance.rewardExperience,
      'timeLimit': instance.timeLimit,
      'relatedNPCs': instance.relatedNPCs,
    };

_$InventoryItemImpl _$$InventoryItemImplFromJson(Map<String, dynamic> json) =>
    _$InventoryItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      itemType: json['itemType'] as String,
      rarity: json['rarity'] as String,
      quantity: (json['quantity'] as num).toInt(),
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      effects: json['effects'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$InventoryItemImplToJson(_$InventoryItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'itemType': instance.itemType,
      'rarity': instance.rarity,
      'quantity': instance.quantity,
      'weight': instance.weight,
      'effects': instance.effects,
    };

_$CodexEntryImpl _$$CodexEntryImplFromJson(Map<String, dynamic> json) =>
    _$CodexEntryImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      discovered: json['discovered'] as bool,
      relatedId: json['relatedId'] as String? ?? '',
      discoveredAtRevision:
          (json['discoveredAtRevision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CodexEntryImplToJson(_$CodexEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'content': instance.content,
      'discovered': instance.discovered,
      'relatedId': instance.relatedId,
      'discoveredAtRevision': instance.discoveredAtRevision,
    };

_$FactionImpl _$$FactionImplFromJson(Map<String, dynamic> json) =>
    _$FactionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      standing: (json['standing'] as num).toInt(),
      tier: json['tier'] as String,
      banner: json['banner'] as String? ?? '',
      controlledArea: json['controlledArea'] as String? ?? '',
      knownActions: (json['knownActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$FactionImplToJson(_$FactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'standing': instance.standing,
      'tier': instance.tier,
      'banner': instance.banner,
      'controlledArea': instance.controlledArea,
      'knownActions': instance.knownActions,
    };

_$RelationshipImpl _$$RelationshipImplFromJson(Map<String, dynamic> json) =>
    _$RelationshipImpl(
      npcId: json['npcId'] as String,
      npcName: json['npcName'] as String,
      role: json['role'] as String,
      trustScore: (json['trustScore'] as num).toInt(),
      suspicion: (json['suspicion'] as num).toInt(),
      loyalty: (json['loyalty'] as num).toInt(),
      fearLevel: (json['fearLevel'] as num).toInt(),
      lastInteraction: json['lastInteraction'] as String? ?? '',
    );

Map<String, dynamic> _$$RelationshipImplToJson(_$RelationshipImpl instance) =>
    <String, dynamic>{
      'npcId': instance.npcId,
      'npcName': instance.npcName,
      'role': instance.role,
      'trustScore': instance.trustScore,
      'suspicion': instance.suspicion,
      'loyalty': instance.loyalty,
      'fearLevel': instance.fearLevel,
      'lastInteraction': instance.lastInteraction,
    };

_$SaveSlotImpl _$$SaveSlotImplFromJson(Map<String, dynamic> json) =>
    _$SaveSlotImpl(
      id: json['id'] as String,
      campaignTitle: json['campaignTitle'] as String,
      characterName: json['characterName'] as String,
      location: json['location'] as String,
      currentChapter: json['currentChapter'] as String,
      lastSavedAt: DateTime.parse(json['lastSavedAt'] as String),
      isAutosave: json['isAutosave'] as bool,
      isCheckpoint: json['isCheckpoint'] as bool,
      revisionNumber: (json['revisionNumber'] as num).toInt(),
      playtimeMinutes: (json['playtimeMinutes'] as num).toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    );

Map<String, dynamic> _$$SaveSlotImplToJson(_$SaveSlotImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'campaignTitle': instance.campaignTitle,
      'characterName': instance.characterName,
      'location': instance.location,
      'currentChapter': instance.currentChapter,
      'lastSavedAt': instance.lastSavedAt.toIso8601String(),
      'isAutosave': instance.isAutosave,
      'isCheckpoint': instance.isCheckpoint,
      'revisionNumber': instance.revisionNumber,
      'playtimeMinutes': instance.playtimeMinutes,
      'thumbnailUrl': instance.thumbnailUrl,
    };

_$TurnResultImpl _$$TurnResultImplFromJson(Map<String, dynamic> json) =>
    _$TurnResultImpl(
      revisionId: json['revisionId'] as String,
      actionSummary: json['actionSummary'] as String,
      canonicalEvents: (json['canonicalEvents'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      authorityVersion: (json['authorityVersion'] as num).toInt(),
      committedAt: DateTime.parse(json['committedAt'] as String),
      stateDelta: json['stateDelta'] as Map<String, dynamic>,
      narrativeBlocks: (json['narrativeBlocks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sceneSuggestion: json['sceneSuggestion'] as String? ?? '',
    );

Map<String, dynamic> _$$TurnResultImplToJson(_$TurnResultImpl instance) =>
    <String, dynamic>{
      'revisionId': instance.revisionId,
      'actionSummary': instance.actionSummary,
      'canonicalEvents': instance.canonicalEvents,
      'authorityVersion': instance.authorityVersion,
      'committedAt': instance.committedAt.toIso8601String(),
      'stateDelta': instance.stateDelta,
      'narrativeBlocks': instance.narrativeBlocks,
      'sceneSuggestion': instance.sceneSuggestion,
    };

_$SceneImpl _$$SceneImplFromJson(Map<String, dynamic> json) => _$SceneImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      controllingFaction: json['controllingFaction'] as String,
      dangerLevel: json['dangerLevel'] as String,
      artPath: json['artPath'] as String? ?? '',
      npcsPresent: (json['npcsPresent'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      availableActions: (json['availableActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SceneImplToJson(_$SceneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'controllingFaction': instance.controllingFaction,
      'dangerLevel': instance.dangerLevel,
      'artPath': instance.artPath,
      'npcsPresent': instance.npcsPresent,
      'availableActions': instance.availableActions,
    };

_$RegionImpl _$$RegionImplFromJson(Map<String, dynamic> json) => _$RegionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      discoveredLocations: (json['discoveredLocations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      routes: (json['routes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RegionImplToJson(_$RegionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'discoveredLocations': instance.discoveredLocations,
      'routes': instance.routes,
    };

_$CampaignImpl _$$CampaignImplFromJson(Map<String, dynamic> json) =>
    _$CampaignImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      tone: json['tone'] as String,
      estimatedLengthHours: (json['estimatedLengthHours'] as num).toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      worldSummary: json['worldSummary'] as String? ?? '',
    );

Map<String, dynamic> _$$CampaignImplToJson(_$CampaignImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'difficulty': instance.difficulty,
      'tone': instance.tone,
      'estimatedLengthHours': instance.estimatedLengthHours,
      'tags': instance.tags,
      'worldSummary': instance.worldSummary,
    };
