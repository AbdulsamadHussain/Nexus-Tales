import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/play/play_screen.dart';
import '../../features/character_sheet/character_sheet_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/quests/quests_screen.dart';
import '../../features/codex/codex_screen.dart';
import '../../features/factions/factions_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/saves/saves_screen.dart';
import '../../features/recap/recap_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/campaign_selection/campaign_selection_screen.dart';
import '../../features/character_creation/character_creation_screen.dart';

/// Navigation routes for the Nexus Tales application.
class AppRoutes {
  static const String campaignSelection = '/';
  static const String characterCreation = '/character-creation';
  static const String play = '/play';
  static const String characterSheet = '/character-sheet';
  static const String inventory = '/inventory';
  static const String quests = '/quests';
  static const String codex = '/codex';
  static const String factions = '/factions';
  static const String map = '/map';
  static const String saves = '/saves';
  static const String recap = '/recap';
  static const String settings = '/settings';
}

/// Go Router configuration for the app.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.campaignSelection,
    routes: [
      GoRoute(
        path: '/',
        name: 'campaign_selection',
        builder: (context, state) => const CampaignSelectionScreen(),
      ),
      GoRoute(
        path: '/character-creation',
        name: 'character_creation',
        builder: (context, state) => const CharacterCreationScreen(),
      ),
      GoRoute(
        path: '/play',
        name: 'play',
        builder: (context, state) => const PlayScreen(),
        routes: [
          GoRoute(
            path: 'character-sheet',
            name: 'character_sheet',
            builder: (context, state) => const CharacterSheetScreen(),
          ),
          GoRoute(
            path: 'inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: 'quests',
            name: 'quests',
            builder: (context, state) => const QuestsScreen(),
          ),
          GoRoute(
            path: 'codex',
            name: 'codex',
            builder: (context, state) => const CodexScreen(),
          ),
          GoRoute(
            path: 'factions',
            name: 'factions',
            builder: (context, state) => const FactionsScreen(),
          ),
          GoRoute(
            path: 'map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: 'saves',
            name: 'saves',
            builder: (context, state) => const SavesScreen(),
          ),
          GoRoute(
            path: 'recap',
            name: 'recap',
            builder: (context, state) => const RecapScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
