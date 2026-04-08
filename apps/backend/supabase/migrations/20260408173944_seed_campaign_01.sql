-- ── CAMPAIGN ─────────────────────────────────────────────────────
insert into public.campaigns (id, title, description) values (
  'campaign_01',
  'The Vault of the Plague Warden',
  'A dark descent into a plague-ridden vault where an ancient warden guards cursed knowledge.'
);

-- ── SCENES ───────────────────────────────────────────────────────
insert into public.scenes (id, campaign_id, title, description, atmosphere, exits, is_start_scene) values
(
  'vault_of_the_plague_warden',
  'campaign_01',
  'The Vault',
  'A cyclopean chamber of black stone. Iron shelves line every wall, their contents shrouded in dark cloth and dried rot. A locked iron cabinet sits at the far end. The air smells of old plague and older magic.',
  'Oppressive, diseased, ancient. The Plague Warden is present and hostile. Describe decay, shadow, and the weight of death. The cabinet contains the cipher scroll — the player''s objective.',
  '{"north": "vault_inner_sanctum"}',
  true
),
(
  'vault_inner_sanctum',
  'campaign_01',
  'The Inner Sanctum',
  'A smaller chamber behind a heavy door. Ritual markings cover the floor. A stone altar holds plague offerings. The air is heavier here — something powerful was bound in this room.',
  'Sacred and corrupted. Ancient ritual, dark purpose. The bindings on the altar are weakening. Describe the ritual markings, the offerings, and a sense of something about to break free.',
  '{"south": "vault_of_the_plague_warden"}',
  false
);

-- ── NPCS ─────────────────────────────────────────────────────────
insert into public.npcs (id, campaign_id, name, description, personality, hp, hp_max, faction, is_hostile, loot) values
(
  'npc_plague_warden',
  'campaign_01',
  'The Plague Warden',
  'A tall figure in a cracked porcelain mask, robes dark with old blood and plague residue. Carries twin scythes. Moves with unnatural stillness.',
  'Coldly philosophical. Speaks rarely but with absolute certainty. Believes plague is purification. Does not beg, does not flee. References the cipher scroll as "the truth no one should carry."',
  60,
  60,
  'servants_of_rot',
  true,
  '[{"item_id": "item_warden_mask", "quantity": 1}, {"item_id": "item_cipher_scroll", "quantity": 1}]'
),
(
  'npc_mira_voss',
  'campaign_01',
  'Mira Voss',
  'A sharp-eyed broker in a worn leather coat. Not supposed to be in the vault. Claims she is looking for the same scroll.',
  'Calculating and charming. Always has an angle. Loyal to coin first. Will betray the player if the price is right but genuinely respects competence.',
  20,
  20,
  'shadow_compact',
  false,
  '[{"item_id": "item_gold_pouch", "quantity": 1}]'
);

-- ── ITEMS ─────────────────────────────────────────────────────────
insert into public.items (id, campaign_id, name, description, rarity, item_type, effects) values
(
  'item_cipher_scroll',
  'campaign_01',
  'The Cipher Scroll',
  'A rolled parchment sealed with plague wax. The encoded text shifts when you look directly at it. This is what you came for.',
  'legendary',
  'key',
  '{"quest_flag": "cipher_scroll_obtained"}'
),
(
  'item_warden_mask',
  'campaign_01',
  'Cracked Porcelain Mask',
  'The Plague Warden''s mask. Still warm. The crack runs through the left eye socket. Wearing it feels wrong.',
  'rare',
  'armor',
  '{"mp_bonus": 10, "curse": "plague_sight"}'
),
(
  'item_healing_salve',
  'campaign_01',
  'Healing Salve',
  'A dark green paste in a clay pot. Smells of rot and relief.',
  'common',
  'consumable',
  '{"hp_restore": 12}'
),
(
  'item_gold_pouch',
  'campaign_01',
  'Gold Pouch',
  'A pouch of mixed coin. Someone was paid recently.',
  'common',
  'misc',
  '{"gold": 45}'
),
(
  'item_plague_vial',
  'campaign_01',
  'Vial of Plague Essence',
  'A glass vial of dark liquid that moves against gravity. Dangerous and valuable.',
  'rare',
  'misc',
  '{"quest_flag": "plague_sample_obtained", "danger": true}'
);

-- ── SCENE ITEMS ───────────────────────────────────────────────────
insert into public.scene_items (scene_id, item_id, find_dc, quantity, is_hidden) values
('vault_of_the_plague_warden', 'item_healing_salve', 10, 2, false),
('vault_of_the_plague_warden', 'item_plague_vial', 16, 1, true),
('vault_inner_sanctum', 'item_healing_salve', 8, 1, false);

-- ── SCENE NPCS ────────────────────────────────────────────────────
insert into public.scene_npcs (scene_id, npc_id, spawn_condition) values
('vault_of_the_plague_warden', 'npc_plague_warden', '{}'),
('vault_of_the_plague_warden', 'npc_mira_voss', '{"first_visit": true}');

-- ── STORY BEATS ───────────────────────────────────────────────────
insert into public.story_beats (campaign_id, title, trigger_type, trigger_data, consequences, priority) values
(
  'campaign_01',
  'Warden defeated',
  'NPC_DEFEATED',
  '{"npc_id": "npc_plague_warden"}',
  '{"grant_items": ["item_cipher_scroll", "item_warden_mask"], "quest_flag": "warden_defeated", "narration_hint": "The Plague Warden crumbles. The cipher scroll falls from the cabinet as the lock releases. The vault grows quiet for the first time in decades."}',
  10
),
(
  'campaign_01',
  'Cipher scroll obtained',
  'ITEM_ACQUIRED',
  '{"item_id": "item_cipher_scroll"}',
  '{"quest_complete": "the_wardens_cipher", "narration_hint": "The scroll is in your hands. The encoded text pulses faintly — it knows it has been claimed. Now you need to get out."}',
  9
),
(
  'campaign_01',
  'Mira reveals her angle',
  'STATE_CONDITION',
  '{"relationship_npc": "npc_mira_voss", "min_score": 15}',
  '{"dialogue_unlock": "mira_true_objective", "narration_hint": "Mira drops the performance. She tells you who actually hired her — and it is not who you expected."}',
  5
);

-- ── CHARACTER PRESETS ─────────────────────────────────────────────
insert into public.character_presets (id, name, class, origin, description, backstory, hp_max, mp_max, stamina_max, starting_items, skills) values
(
  'preset_shadow_rogue',
  'Seraphyn Vael',
  'Rogue',
  'Street Rat',
  'A shadow dancer from the Ashroot Quarter. Fast, precise, deadly.',
  'Grew up running errands for the Shadow Compact. Learned that loyalty is a commodity. Now sells her skills to whoever pays — as long as the work is interesting.',
  40, 20, 20,
  '[{"item_id": "item_healing_salve", "quantity": 1}]',
  '{"stealth": 6, "lockpick": 5, "dagger": 7, "perception": 4}'
),
(
  'preset_war_mage',
  'Aldric Voss',
  'War Mage',
  'Academy Exile',
  'A disgraced mage who weaponized forbidden theory.',
  'Expelled from the Collegium for experimenting on living subjects. Not sorry about the research. Sorry about getting caught.',
  28, 40, 15,
  '[]',
  '{"evocation": 8, "arcane_theory": 7, "staff": 4, "perception": 3}'
),
(
  'preset_iron_warden',
  'Bryn Ashfeld',
  'Warden',
  'Fallen Knight',
  'A former city guard who survived something they refuse to name.',
  'Was first through the door at the Ashroot Incident. Only one who came back. Does not talk about it. Does not sleep much either.',
  60, 10, 30,
  '[{"item_id": "item_healing_salve", "quantity": 2}]',
  '{"shield": 7, "intimidate": 6, "endurance": 8, "perception": 5}'
);