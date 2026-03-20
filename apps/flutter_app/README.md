# Nexus Tales Flutter Client

A production-grade, contract-first AI Narrative RPG client built with Flutter and Riverpod.

**Status**: Phase 5 - Flutter Client Architecture & Foundation Complete ✅

## Quick Start

### Prerequisites
- Flutter 3.16+ 
- Dart 3.4+
- A running Nexus Tales backend (Phase 0+)

### Setup
```bash
cd apps/flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome  # or macOS, Linux, Windows, iOS, Android
```

### First Run
The app boots to Campaign Selection screen with mock data. You can:
1. Select a campaign (mocked)
2. Create a character (UI ready)
3. Play the game (screens ready for implementation)

## Architecture Overview

### Three-Tier State Management

This app implements a strict separation between authoritative backend state, ephemeral UI state, and draft user input:

```
┌─ BACKEND ──────────────────────────────────────────┐
│  Authoritative truth:                              │
│  - Character stats, inventory, quests            │
│  - Faction standings, relationships              │
│  - Discovered lore, saves metadata               │
│  - Current revision ID, scene context            │
└────────────────────────────────────────────────────┘
                      ⬇️ (via HTTP)
┌─ CLIENT (Watch) ───────────────────────────────────────────┐
│  Authoritative Remote State Providers:                     │
│  currentCharacterProvider, questListProvider, ...          │
│  Never mutated locally. Updated only from backend.        │
└────────────────────────────────────────────────────────────┘
                      ⬆️ (via form)
       ┌─ Local Presentation State ──────┐
       │ selectedQuestProvider            │
       │ sidePanelExpandedProvider        │
       │ (ephemeral UI state)             │
       └─────────────────────────────────┘
                      ⬆️ (user types)
          ┌─ Draft/Input State ────────────┐
          │ draftActionProvider             │
          │ clarificationAnswerProvider     │
          │ (user input before submission) │
          └────────────────────────────────┘
```

### Key Principle

> The client **never** invents canonical game state. All truth comes from the backend.

If a player action would change HP, mana, gold, inventory, quest progress, or faction standing, it happens only when the backend confirms it via the turn result.

## Code Organization

```
lib/
  ├── main.dart                      # App bootstrap
  │
  ├── app/
  │   ├── routing/
  │   │   ├── app_router.dart       # Go Router (all screens)
  │   │   └── riverpod_providers.dart # State providers (3 tiers)
  │   └── theme/                     # Design system
  │       ├── theme_constants.dart   # Tokens (colors, spacing, typography)
  │       └── app_theme.dart         # Material 3 theme
  │
  ├── features/                      # Screen implementations
  │   ├── play/                      # Main gameplay
  │   ├── character_sheet/
  │   ├── inventory/
  │   ├── quests/
  │   ├── codex/
  │   ├── factions/
  │   ├── map/
  │   ├── saves/
  │   ├── recap/
  │   ├── settings/
  │   ├── campaign_selection/
  │   └── character_creation/
  │
  ├── domain/
  │   └── models/game_models.dart   # Immutable @freezed models
  │
  ├── data/
  │   ├── dto/                      # API data shapes (to implement)
  │   ├── mappers/                  # DTO ↔ Domain conversion (to implement)
  │   └── mock/mock_data.dart       # Development data
  │
  └── shared/
      └── widgets/                   # 25+ reusable components
          ├── app_buttons.dart
          ├── app_panels.dart
          ├── story_cards.dart
          └── game_cards.dart
```

## Design System

### Colors (Dark Fantasy)
```dart
AppColors.background          // #0A0A0A (charcoal)
AppColors.accentBronze        // #B8860B (muted bronze)
AppColors.accentGold          // #C9A961 (aged gold)
AppColors.statusDanger        // #AA3333 (restrained crimson)
AppColors.statusSuccess       // #559955 (muted green)
AppColors.textPrimary         // #E8E8E8 (parchment gray)
```

### Spacing (4dp base)
```dart
AppSpacing.xs  // 4px    AppSpacing.lg  // 16px
AppSpacing.sm  // 8px    AppSpacing.xl  // 24px
AppSpacing.md  // 12px   AppSpacing.xxl // 32px
```

### Typography
- **Display**: 28-32px, bold, wide letter spacing
- **Heading**: 18-24px, bold
- **Body**: 14-16px, normal
- **Label**: 12-14px, semi-bold
- **Caption**: 10-12px, normal, low emphasis

## State Management Patterns

### Watching Providers in Widgets

```dart
class CharacterPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authoritative state
    final character = ref.watch(currentCharacterProvider);
    
    // Watch UI state
    final selectedTab = ref.watch(characterSheetTabProvider);
    
    // Watch derived values
    final isCritical = ref.watch(isCriticalProvider);
    
    return Scaffold(
      body: character == null
          ? const LoadingScreen()
          : CharacterSheet(character: character),
    );
  }
}
```

### Updating Providers

```dart
// Update local UI state
ref.read(selectedQuestProvider.notifier).state = quest;

// Update draft input
final draftAction = ref.read(draftActionProvider).copyWith(
  text: 'Attack the orc',
  quickActionType: null,
);
ref.read(draftActionProvider.notifier).state = draftAction;

// Process backend response
final gameResult = await submitTurn(actionText);
if (gameResult.success) {
  // Update authoritative state with backend response
  ref.read(currentCharacterProvider.notifier).state = 
      characterFromServerResult(gameResult);
}
```

### Computed Providers

```dart
// Derived values automatically update when source providers change
final isCriticalProvider = Provider<bool>(
  (ref) {
    final character = ref.watch(currentCharacterProvider);
    if (character == null) return false;
    return (character.healthPoints / character.maxHealthPoints) < 0.25;
  },
);

// Usage in widget
final isCritical = ref.watch(isCriticalProvider);
if (isCritical) {
  // Show warning UI
}
```

## Components

### Buttons
```dart
PrimaryButton(
  label: 'Attack',
  onPressed: () => submitAction('attack'),
);

SecondaryButton(
  label: 'Inspect',
  onPressed: () => submitAction('inspect'),
);

DangerButton(
  label: 'Delete',
  onPressed: () => deleteItem(),
);
```

### Cards & Lists
```dart
QuestCard(
  quest: mockQuests[0],
  isSelected: selectedQuest?.id == mockQuests[0].id,
  onTap: () => ref.read(selectedQuestProvider.notifier).state = mockQuests[0],
);

SaveSlotCard(
  save: mockSaveSlots[0],
  onSelect: () => loadGame(mockSaveSlots[0]),
  onDelete: () => deleteSave(mockSaveSlots[0]),
);

RelationshipCard(
  relationship: mockRelationships[0],
  onTap: () => ref.read(selectedRelationshipProvider.notifier).state = mockRelationships[0],
);
```

### Containers
```dart
SectionHeader(
  title: 'Inventory',
  icon: Icons.backpack,
  onActionTap: () => showFilters(),
  actionIcon: Icons.tune,
);

PanelContainer(
  child: Text('Your action text here'),
  borderSide: Border.all(color: AppColors.accentBronze),
  elevation: 2,
);

EmptyStateCard(
  icon: Icons.book,
  title: 'No entries discovered',
  description: 'Explore the world to discover lore',
  actionLabel: 'Continue',
  onAction: () => goBackToPlay(),
);
```

## Backend Integration

### Submitting a Turn

The typical flow:

1. **User types action** → updates `draftActionProvider`
2. **Player clicks "Act"** → validate, submit to backend
3. **Backend responds** → authoritative result with revision ID
4. **Client updates state** → watchers rebuild UI

```dart
Future<void> submitTurn(String actionText, WidgetRef ref) async {
  ref.read(isSubmittingTurnProvider.notifier).state = true;
  
  try {
    final response = await http.post(
      Uri.parse('http://localhost:3000/v1/turns'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerId': playerId,
        'runId': runId,
        'saveSlotId': saveSlotId,
        'clientTurnId': 'flutter_${DateTime.now().millisecondsSinceEpoch}',
        'inputText': actionText,
        'contentSettings': {
          'violenceLevel': ref.read(contentSettingsProvider).violenceLevel,
          // ... other settings
        },
      }),
    );

    if (response.statusCode == 200) {
      final result = TurnResult.fromJson(jsonDecode(response.body));
      
      // Update authoritative state
      ref.read(currentCharacterProvider.notifier).state = 
          applyStateDelta(result.stateDelta);
      ref.read(currentRevisionProvider.notifier).state = 
          (id: result.revisionId, timestamp: DateTime.now());
      
      // Clear draft
      ref.read(draftActionProvider.notifier).state = const DraftAction(
        text: '', quickActionType: null,
      );
    }
  } catch (e) {
    ref.read(lastErrorProvider.notifier).state = 
        'Failed to submit turn: $e';
  } finally {
    ref.read(isSubmittingTurnProvider.notifier).state = false;
  }
}
```

## Accessibility

The app is built with accessibility first:

- **Font scaling**: `AccessibilitySettings.fontSizeMultiplier`
- **High contrast**: `AccessibilitySettings.highContrast`
- **Reduce motion**: `AccessibilitySettings.reduceMotion`
- **Screen reader**: `AccessibilitySettings.screenReaderMode`

Components use semantic labels and proper text contrast (WCAG AA).

## Testing

### Unit Test Example
```dart
test('isCriticalProvider returns true when HP < 25%', () async {
  final container = ProviderContainer();
  
  // Set character with low HP
  container.read(currentCharacterProvider.notifier).state = 
      PlayerCharacter(healthPoints: 20, maxHealthPoints: 100, ...);
  
  expect(container.read(isCriticalProvider), true);
});
```

### Widget Test Example
```dart
testWidgets('PrimaryButton onClick fires callback', (tester) async {
  var callCount = 0;
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PrimaryButton(
          label: 'Test',
          onPressed: () => callCount++,
        ),
      ),
    ),
  );
  
  await tester.tap(find.byType(PrimaryButton));
  expect(callCount, 1);
});
```

## Development Tips

### Hot Reload
- Changes to UI widgets reload instantly
- State is preserved (Riverpod rebuilds only affected widgets)
- Model changes require restart

### Code Generation
After modifying `game_models.dart`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Debugging State
```dart
// Print current state
print(ref.read(currentCharacterProvider));

// Watch changes in console
ref.listen(currentCharacterProvider, (prev, next) {
  print('Character changed: $prev → $next');
});
```

### Routing
Navigate with:
```dart
context.go('/play/inventory');   // Replace current
context.push('/play/quests');    // Stack navigation
```

## Known Issues & Notes

- Main gameplay screen is ready for implementation
- Secondary screens are scaffold-only (awaiting your implementation)
- Backend integration uses mock responses during development
- main.dart has legacy template code (non-critical, can be cleaned)

## Resources

- **Architecture**: See `IMPLEMENTATION_GUIDE.md`
- **Design**: See `PHASE5_DELIVERY.md`
- **API**: `/v1/turns` endpoint (POST)
- **Designs**: `UI-desgin.md` in project root
- **Backend**: Nexus Tales backend (Phase 0+)

## Contributing

When implementing new screens:

1. Create screen file in `lib/features/{feature}/`
2. Use `ConsumerWidget` for state access
3. Import components from `lib/shared/widgets/`
4. Follow color/spacing/typography constants
5. Test with mock data first
6. Connect to backend when ready

## License

Part of Nexus Tales project—proprietary.

