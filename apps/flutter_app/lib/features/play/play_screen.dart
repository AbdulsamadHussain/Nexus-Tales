import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../domain/models/game_models.dart';
import '../../shared/widgets/index.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  late final TextEditingController _actionInputController;

  final List<Map<String, String>> _narrativeBlocks = [
    {
      'title': 'The arrival',
      'content':
          'The shadows lengthen as you step into The Raven\'s Threshold. The scent of old oak and spiced wine fills your nostrils. Conversations hush as heads turn—some curious, others wary.',
      'source': 'narration',
    },
    {
      'title': 'A watcher',
      'content':
          'A hooded figure in the corner catches your eye, fingers wrapped around a goblet of burgundy. Their attention is unmistakably yours.',
      'source': 'narration',
    },
  ];

  @override
  void initState() {
    super.initState();
    _actionInputController = TextEditingController();
  }

  @override
  void dispose() {
    _actionInputController.dispose();
    super.dispose();
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'talk':
        return Icons.chat_bubble;
      case 'inspect':
        return Icons.search;
      case 'travel':
        return Icons.directions_walk;
      case 'rest':
        return Icons.hotel;
      case 'use item':
        return Icons.backpack;
      case 'negotiate':
        return Icons.handshake;
      default:
        return Icons.help;
    }
  }

  String _formatDangerLevel(dynamic dangerLevel) {
    if (dangerLevel == null) return 'UNKNOWN';

    if (dangerLevel is String) {
      return dangerLevel.toUpperCase();
    }

    if (dangerLevel is Enum) {
      return dangerLevel.name.toUpperCase();
    }

    return dangerLevel.toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final character =
        ref.watch(currentCharacterProvider) ?? MockData.mockCharacter;
    final scene = ref.watch(currentSceneProvider);
    final draftAction = ref.watch(draftActionProvider);
    final isSubmitting = ref.watch(isSubmittingTurnProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildTopBar(context, scene),
                Expanded(child: _buildStoryPanel()),
                _buildActionComposer(context, draftAction, isSubmitting),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            child: _buildStatusSidebar(context, character),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Scene? scene) {
    return Container(
      color: AppColors.surfaceCard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene?.title ?? 'Unknown Location',
                  style: AppTypography.headingMedium,
                ),
                Text(
                  scene != null
                      ? '${_formatDangerLevel(scene.dangerLevel)} • ${scene.controllingFaction}'
                      : '',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: 'Recap',
            icon: Icons.history,
            onPressed: () => context.push('/play/recap'),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(
            label: 'Save',
            icon: Icons.save,
            onPressed: () => context.push('/play/saves'),
          ),
          const SizedBox(width: AppSpacing.sm),
          SecondaryButton(
            label: 'Settings',
            icon: Icons.settings,
            onPressed: () => context.push('/play/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryPanel() {
    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView.separated(
          itemCount: _narrativeBlocks.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final block = _narrativeBlocks[index];
            return StoryCard(
              title: block['title'] ?? '',
              content: block['content'] ?? '',
              source: block['source'] ?? 'narration',
              isHighlighted: index == _narrativeBlocks.length - 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionComposer(
    BuildContext context,
    DraftAction draftAction,
    bool isSubmitting,
  ) {
    return Container(
      color: AppColors.surfaceCard,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              'Talk',
              'Inspect',
              'Travel',
              'Rest',
              'Use Item',
              'Negotiate',
            ]
                .map(
                  (action) => QuickActionChip(
                    label: action,
                    icon: _getActionIcon(action),
                    onPressed: () {
                      _actionInputController.text = action;
                      _actionInputController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _actionInputController.text.length),
                      );

                      ref.read(draftActionProvider.notifier).state = DraftAction(
                            text: action,
                            quickActionType: action.toLowerCase(),
                            hasClarificationPending: false,
                          );
                    },
                    isSelected:
                        draftAction.quickActionType == action.toLowerCase(),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _actionInputController,
            onChanged: (value) {
              ref.read(draftActionProvider.notifier).state = DraftAction(
                    text: value,
                    quickActionType: null,
                    hasClarificationPending: false,
                  );
            },
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'What do you do?',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceHover,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: AppBorders.thin,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),

          PrimaryButton(
            label: isSubmitting ? 'Submitting...' : 'Act',
            icon: Icons.send,
            isLoading: isSubmitting,
            isEnabled: !isSubmitting && draftAction.text.trim().isNotEmpty,
            onPressed: () async {
              if (draftAction.text.trim().isEmpty) return;

              ref.read(isSubmittingTurnProvider.notifier).state = true;

              await Future.delayed(const Duration(milliseconds: 800));

              setState(() {
                _narrativeBlocks.add({
                  'title': 'You act',
                  'content': 'You ${draftAction.text.toLowerCase()}.',
                  'source': 'action',
                });
                _narrativeBlocks.add({
                  'title': 'The world responds',
                  'content':
                      'The scene shifts. Something has changed. The hooded figure\'s hand trembles slightly on their goblet.',
                  'source': 'narration',
                });
              });

              _actionInputController.clear();

              ref.read(draftActionProvider.notifier).state = const DraftAction(
                    text: '',
                    quickActionType: null,
                    hasClarificationPending: false,
                  );

              ref.read(isSubmittingTurnProvider.notifier).state = false;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSidebar(BuildContext context, PlayerCharacter character) {
    return Container(
      color: AppColors.surfaceCard,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: AppTypography.headingMedium,
                ),
                Text(
                  '${character.archetype} • Lvl ${character.level}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatPill(
                    label: 'Health',
                    value:
                        '${character.healthPoints}/${character.maxHealthPoints}',
                    color: AppColors.statusDanger,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StatPill(
                    label: 'Stamina',
                    value: '${character.stamina}/${character.maxStamina}',
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StatPill(
                    label: 'Mana',
                    value: '${character.mana}/${character.maxMana}',
                    color: AppColors.statusInfo,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      border: Border.all(color: AppColors.accentGold),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: AppColors.accentGold,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${character.gold} Gold',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (character.wounds.isNotEmpty ||
                      character.activeConditions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Conditions',
                          icon: Icons.warning,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...character.wounds.map(
                          (w) => _buildConditionTag(
                            w,
                            AppColors.statusDanger,
                          ),
                        ),
                        ...character.activeConditions.map(
                          (c) => _buildConditionTag(
                            c,
                            AppColors.statusWarning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  const SectionHeader(
                    title: 'Quick Access',
                    icon: Icons.apps,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildNavButton(
                    context,
                    'Character',
                    Icons.person,
                    '/play/character-sheet',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildNavButton(
                    context,
                    'Inventory',
                    Icons.backpack,
                    '/play/inventory',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildNavButton(
                    context,
                    'Quests',
                    Icons.assignment,
                    '/play/quests',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildNavButton(
                    context,
                    'Codex',
                    Icons.book,
                    '/play/codex',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildNavButton(
                    context,
                    'Factions',
                    Icons.groups,
                    '/play/factions',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildNavButton(
                    context,
                    'Map',
                    Icons.map,
                    '/play/map',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionTag(String condition, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        condition.replaceAll('_', ' ').toUpperCase(),
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: AppTypography.labelMedium),
        onPressed: () => context.push(route),
      ),
    );
  }
}