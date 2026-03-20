import '../../domain/models/game_models.dart';

/// Mock data for development and design purposes.
/// Follows the dark fantasy theme and character background described in UI-design.md
class MockData {
  static final PlayerCharacter mockCharacter = PlayerCharacter(
    id: 'player_001',
    name: 'Kael Vorthos',
    archetype: 'Shadow Rogue',
    background: 'Exiled Thief',
    pronouns: 'he/him',
    healthPoints: 68,
    maxHealthPoints: 85,
    stamina: 45,
    maxStamina: 60,
    mana: 30,
    maxMana: 40,
    stats: {
      'strength': 14,
      'agility': 18,
      'willpower': 12,
      'presence': 11,
      'intellect': 15,
    },
    gold: 2450,
    equippedItems: ['dagger_001', 'leather_armor_001', 'amulet_001'],
    wounds: [],
    activeConditions: ['Weakened', 'Focused'],
    skillLevels: {
      'stealth': 5,
      'lockpicking': 4,
      'perception': 4,
      'deception': 3,
      'blade_arts': 4,
    },
    experience: 4200,
    level: 6,
    passiveTraits: ['Shadow affinity', 'Quick reflexes', 'Keen eye'],
  );

  static final List<Quest> mockQuests = [
    Quest(
      id: 'quest_001',
      title: 'The Crimson Veil',
      description: 'A mysterious shadow falls upon the city. Investigate the rooftops for clues.',
      status: 'active',
      questType: 'main',
      location: 'Shadowed Quarter',
      objectives: [
        'Find clues on the rooftops',
        'Investigate the warehouse district',
        'Meet with the informant',
        'Confront the shadow master'
      ],
      currentObjectiveIndex: 1,
      rewardItems: ['shadow_ring', 'elven_cloak'],
      rewardGold: 500,
      rewardExperience: 1200,
      timeLimit: 12,
      relatedNPCs: ['npc_assassin', 'npc_informant'],
    ),
    Quest(
      id: 'quest_002',
      title: 'Mercy for the Cursed',
      description: 'A child in the lower city is afflicted by a curse. Find a cure before nightfall.',
      status: 'active',
      questType: 'side',
      location: 'Lower City',
      objectives: [
        'Find the herbalist',
        'Gather moonflower essence',
        'Return to the child'
      ],
      currentObjectiveIndex: 0,
      rewardItems: ['blessing_charm'],
      rewardGold: 150,
      rewardExperience: 300,
      timeLimit: 6,
      relatedNPCs: ['npc_herbalist', 'npc_child'],
    ),
    Quest(
      id: 'quest_003',
      title: 'The Warlord\'s Gold',
      description: 'The iron council seeks to recover stolen artifacts. The warlord has them.',
      status: 'active',
      questType: 'main',
      location: 'Obsidian Keep',
      objectives: [
        'Infiltrate the keep',
        'Locate the treasure vault',
        'Escape with the artifacts',
        'Return to the council'
      ],
      currentObjectiveIndex: 0,
      rewardItems: ['artifact_crown', 'warlord_ring'],
      rewardGold: 2000,
      rewardExperience: 3000,
      relatedNPCs: ['npc_warlord', 'npc_councilor'],
    ),
  ];

  static final List<InventoryItem> mockInventory = [
    InventoryItem(
      id: 'dagger_001',
      name: 'Shadows Whisper',
      description: 'An expertly crafted dagger with an edge that seems to drink in light.',
      itemType: 'weapon',
      rarity: 'rare',
      quantity: 1,
      weight: 2,
      effects: {'damage': 8, 'lethal': true},
    ),
    InventoryItem(
      id: 'leather_armor_001',
      name: 'Tailored Leather',
      description: 'Supple leather armor dyed deep charcoal. Optimized for stealth.',
      itemType: 'armor',
      rarity: 'uncommon',
      quantity: 1,
      weight: 8,
      effects: {'armor': 4, 'stealth_bonus': 1},
    ),
    InventoryItem(
      id: 'amulet_001',
      name: 'Ward of the Fade',
      description: 'An ancient amulet that protects the wearer from magical detection.',
      itemType: 'relic',
      rarity: 'rare',
      quantity: 1,
      weight: 0,
      effects: {'magic_detection_resistance': true},
    ),
    InventoryItem(
      id: 'potion_heal_001',
      name: 'Vitality Elixir',
      description: 'Restores moderate health when consumed.',
      itemType: 'consumable',
      rarity: 'common',
      quantity: 3,
      weight: 0,
      effects: {'healing': 30},
    ),
    InventoryItem(
      id: 'material_silk',
      name: 'Shadowsilk Thread',
      description: 'Rare thread harvested from ancient spiders. Valuable to enchanters.',
      itemType: 'material',
      rarity: 'uncommon',
      quantity: 12,
      weight: 1,
      effects: {},
    ),
  ];

  static final List<CodexEntry> mockCodexEntries = [
    CodexEntry(
      id: 'codex_shadowed_quarter',
      title: 'The Shadowed Quarter',
      category: 'location',
      content:
          'The older district of the city, where narrow alleys wind between ancient stone structures. Once home to merchants and artisans, it has fallen into decline. Now it serves as a refuge for those who wish to remain unseen. Few travelers venture here after dark.',
      discovered: true,
      discoveredAtRevision: 102,
    ),
    CodexEntry(
      id: 'codex_kael_past',
      title: 'Kael\'s Past',
      category: 'history',
      content:
          'You were once a thief for hire in the great houses. A job went wrong. Someone died. You were blamed, though the truth was more complex. You fled the city, spending years in the wilderness. Now you have returned, seeking redemption or revenge—even you are not certain which.',
      discovered: true,
      discoveredAtRevision: 1,
    ),
    CodexEntry(
      id: 'codex_eclipse_guild',
      title: 'The Eclipse Guild',
      category: 'faction',
      content: 'A secretive network of assassins and thieves. Their symbol is a crescent moon that swallows the sun.',
      discovered: true,
      discoveredAtRevision: 45,
    ),
    CodexEntry(
      id: 'codex_crimson_veil',
      title: 'Shadow Entities',
      category: 'creature',
      content: 'Creatures drawn to darkness and despair. Their true nature remains unknown.',
      discovered: false,
      discoveredAtRevision: 0,
    ),
  ];

  static final List<Faction> mockFactions = [
    Faction(
      id: 'faction_iron_council',
      name: 'Iron Council',
      description: 'The governing body of the free cities. Bureaucratic and removed from common folk.',
      standing: 15,
      tier: 'neutral',
      controlledArea: 'The Capital',
    ),
    Faction(
      id: 'faction_eclipse_guild',
      name: 'Eclipse Guild',
      description: 'Assassins and thieves united under one crescent banner.',
      standing: 45,
      tier: 'friendly',
      controlledArea: 'Shadowed Quarter',
    ),
    Faction(
      id: 'faction_temple_order',
      name: 'Temple Order',
      description: 'Monks devoted to the old faiths. Mysterious and insular.',
      standing: -10,
      tier: 'unfriendly',
      controlledArea: 'Sacred Heights',
    ),
    Faction(
      id: 'faction_warlord_army',
      name: 'Warlord\'s Army',
      description: 'A militant force led by the ruthless warlord. They control the northern territories.',
      standing: -50,
      tier: 'hostile',
      controlledArea: 'Northern Reaches',
    ),
  ];

  static final List<Relationship> mockRelationships = [
    Relationship(
      npcId: 'npc_informant',
      npcName: 'Morrigan',
      role: 'ally',
      trustScore: 65,
      suspicion: 10,
      loyalty: 55,
      fearLevel: 0,
      lastInteraction: 'Shared information about the warlord',
    ),
    Relationship(
      npcId: 'npc_assassin',
      npcName: 'Blades',
      role: 'rival',
      trustScore: 25,
      suspicion: 60,
      loyalty: 20,
      fearLevel: 45,
      lastInteraction: 'Competed for a contract',
    ),
    Relationship(
      npcId: 'npc_warlord',
      npcName: 'Lord Theron',
      role: 'enemy',
      trustScore: -80,
      suspicion: 100,
      loyalty: -100,
      fearLevel: 80,
      lastInteraction: 'Stole from his treasury',
    ),
    Relationship(
      npcId: 'npc_herbalist',
      npcName: 'Lyra',
      role: 'mentor',
      trustScore: 80,
      suspicion: 5,
      loyalty: 70,
      fearLevel: 0,
      lastInteraction: 'Sought advice on poisons',
    ),
  ];

  static final Scene mockCurrentScene = Scene(
    id: 'scene_rooftops',
    title: 'The Rooftops at Dusk',
    description:
        'You stand atop a weathered stone building overlooking the Shadowed Quarter. Rain threatens on the horizon. Somewhere below, the sound of city life continues—merchants closing their stalls, children calling to each other, the distant sound of a stringed instrument.',
    controllingFaction: 'faction_eclipse_guild',
    dangerLevel: 'moderate',
    artPath: '/art/rooftops_dusk.png',
    npcsPresent: ['npc_informant'],
    availableActions: ['Talk', 'Inspect', 'Observe', 'Travel'],
  );

  static final List<Campaign> mockCampaigns = [
    Campaign(
      id: 'campaign_shadows',
      title: 'The Crimson Shadows',
      description: 'A noir tale of deception, betrayal, and the thin line between right and wrong.',
      difficulty: 'seasoned',
      tone: 'noir',
      estimatedLengthHours: 25,
      tags: ['noir', 'crime', 'political', 'mystery'],
      worldSummary:
          'A world of shadow and steel, where information is currency and trust is a liability.',
    ),
    Campaign(
      id: 'campaign_warlord',
      title: 'The Warlord\'s Gambit',
      description: 'Survive the machinations of warring factions in a land torn by ambition and greed.',
      difficulty: 'legendary',
      tone: 'gritty',
      estimatedLengthHours: 40,
      tags: ['war', 'politics', 'dragons', 'conquest'],
      worldSummary:
          'A realm of military might and dark magic, where alliances shift like sand.',
    ),
  ];

  static final List<SaveSlot> mockSaveSlots = [
    SaveSlot(
      id: 'save_001',
      campaignTitle: 'The Crimson Shadows',
      characterName: 'Kael Vorthos',
      location: 'Shadowed Quarter',
      currentChapter: 'Act II: Betrayal',
      lastSavedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isAutosave: false,
      isCheckpoint: false,
      revisionNumber: 247,
      playtimeMinutes: 450,
    ),
    SaveSlot(
      id: 'save_002',
      campaignTitle: 'The Crimson Shadows',
      characterName: 'Kael Vorthos',
      location: 'The Capital',
      currentChapter: 'Act I: Whispers',
      lastSavedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isAutosave: true,
      isCheckpoint: false,
      revisionNumber: 203,
      playtimeMinutes: 380,
    ),
    SaveSlot(
      id: 'save_checkpoint_001',
      campaignTitle: 'The Crimson Shadows',
      characterName: 'Kael Vorthos',
      location: 'Sacred Heights',
      currentChapter: 'Act I: The Descent',
      lastSavedAt: DateTime.now().subtract(const Duration(days: 1)),
      isAutosave: false,
      isCheckpoint: true,
      revisionNumber: 150,
      playtimeMinutes: 280,
    ),
  ];

  // Mock turn result (authoritative response from backend)
  static TurnResult mockTurnResult(String action) {
    return TurnResult(
      revisionId: 'rev_248',
      actionSummary: 'You $action',
      canonicalEvents: ['action_taken', 'roll_required', 'skill_check_performed'],
      authorityVersion: 1,
      committedAt: DateTime.now(),
      stateDelta: {
        'health_points': 68,
        'stamina': 42,
        'experience': 4220,
      },
      narrativeBlocks: [
        'The action unfolds. Your skills prove invaluable in this moment of tension.'
      ],
      sceneSuggestion: 'shadowed_alley_night',
    );
  }
}
