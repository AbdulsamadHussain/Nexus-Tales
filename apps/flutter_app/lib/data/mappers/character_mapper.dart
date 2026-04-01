import '../../domain/models/game_models.dart';
import '../dto/character_state_dto.dart';
import 'mapper_utils.dart';

/// Mapper for character-related DTOs to domain models

class CharacterMapper {
  /// Convert CharacterStateDto to PlayerCharacter domain model
  static PlayerCharacter toPlayerCharacter(CharacterStateDto dto) {
    return PlayerCharacter(
      id: dto.characterId,
      name: dto.name,
      archetype: dto.className,
      background: 'Traveler', // Not provided by API, use default
      pronouns: 'They/Them', // Not provided by API, use default
      healthPoints: dto.hp,
      maxHealthPoints: dto.hpMax,
      stamina: dto.stamina,
      maxStamina: dto.staminaMax,
      mana: dto.mana,
      maxMana: dto.manaMax,
      stats: {
        'str': dto.strength ?? 10,
        'agi': dto.dexterity ?? 10,
        'willpower': dto.wisdom ?? 10,
        'presence': dto.charisma ?? 10,
        'intellect': dto.intelligence ?? 10,
      },
      gold: dto.gold,
      equippedItems: _extractEquippedItems(dto.inventory ?? []),
      wounds: [], // Not provided by API
      activeConditions: [], // Not provided by API
      skillLevels: {}, // Not provided by API
      experience: dto.experience,
      level: dto.level,
      passiveTraits: [],
    );
  }

  /// Convert InventoryItemDto to InventoryItem domain model
  static InventoryItem toInventoryItem(InventoryItemDto dto) {
    return InventoryItem(
      id: dto.itemId,
      name: dto.name,
      description: dto.description,
      itemType: dto.itemType.toLowerCase(),
      rarity: dto.rarity?.toLowerCase() ?? 'common',
      quantity: dto.quantity,
      weight: 0, // Not provided by API
      effects: {}, // Not provided by API
    );
  }

  /// Convert QuestDto to Quest domain model
  static Quest toQuest(QuestDto dto) {
    return Quest(
      id: dto.questId,
      title: dto.title,
      description: dto.description,
      status: _mapQuestStatus(dto.completed, dto.questStage),
      questType: _mapQuestType(dto.questStage),
      location: 'Unknown', // Not provided by API
      objectives: dto.objectives ?? [],
      currentObjectiveIndex: 0,
      rewardItems: [],
      rewardGold: 0,
      rewardExperience: 0,
      relatedNPCs: [],
    );
  }

  /// Convert CodexEntryDto to CodexEntry domain model
  static CodexEntry toCodexEntry(CodexEntryDto dto) {
    return CodexEntry(
      id: dto.entryId,
      title: dto.title,
      category: dto.entryType.toLowerCase(),
      content: dto.description,
      discovered: dto.discovered,
      relatedId: '',
      discoveredAtRevision: 0,
    );
  }

  /// Convert FactionDto to Faction domain model
  static Faction toFaction(FactionDto dto) {
    return Faction(
      id: dto.factionId,
      name: dto.name,
      description: dto.description,
      standing: dto.standing,
      tier: _mapStandingLevel(dto.standingLevel),
      banner: dto.banner ?? '',
      controlledArea: '',
      knownActions: [],
    );
  }

  /// Convert RelationshipDto to Relationship domain model
  static Relationship toRelationship(RelationshipDto dto) {
    return Relationship(
      npcId: dto.npcId,
      npcName: dto.name,
      role: _mapAffinityToRole(dto.affinityLevel),
      trustScore: _affinityToScore(dto.affinity),
      suspicion: 0,
      loyalty: _affinityToScore(dto.affinity),
      fearLevel: 0,
      lastInteraction: dto.lastInteraction?.toIso8601String() ?? '',
    );
  }

  // Private helper methods

  static List<String> _extractEquippedItems(List<InventoryItemDto> items) {
    return items
        .where((item) => item.equipped == true)
        .map((item) => item.itemId)
        .toList();
  }

  static String _mapQuestStatus(bool completed, String questStage) {
    if (completed) return 'completed';
    if (questStage == 'STARTED' || questStage == 'IN_PROGRESS') {
      return 'active';
    }
    if (questStage == 'FAILED') return 'failed';
    return 'hidden';
  }

  static String _mapQuestType(String questStage) {
    // Assume quests are side quests unless otherwise indicated
    // This would ideally come from the API
    return 'side';
  }

  static String _mapStandingLevel(String standingLevel) {
    return switch (standingLevel) {
      'HOSTILE' => 'hostile',
      'WARY' => 'unfriendly',
      'NEUTRAL' => 'neutral',
      'FRIENDLY' => 'friendly',
      'ALLIED' => 'allied',
      _ => 'neutral',
    };
  }

  static String _mapAffinityToRole(String affinityLevel) {
    return switch (affinityLevel) {
      'HOSTILE' => 'enemy',
      'COLD' => 'rival',
      'NEUTRAL' => 'neutral',
      'WARM' => 'ally',
      'INTIMATE' => 'love',
      _ => 'neutral',
    };
  }

  static int _affinityToScore(int affinity) {
    // Clamp affinity to -100..100 range
    return affinity.clamp(-100, 100);
  }
}
