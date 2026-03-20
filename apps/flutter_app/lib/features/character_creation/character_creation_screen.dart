import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../shared/widgets/index.dart';

class CharacterCreationScreen extends ConsumerStatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  ConsumerState<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState
    extends ConsumerState<CharacterCreationScreen> {
  late TextEditingController _nameController;
  String _selectedClass = 'Shadow Knight';
  String _selectedBackground = 'Exiled Noble';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create Your Character', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Character Name', _buildNameInput()),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection('Choose Your Class', _buildClassSelector()),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection('Choose Your Background', _buildBackgroundSelector()),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SecondaryButton(
                  label: 'Back',
                  onPressed: () => context.go('/'),
                ),
                PrimaryButton(
                  label: 'Create & Play',
                  onPressed: () => context.go('/play'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Enter your character\'s name',
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: AppBorders.thin,
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    final classes = [
      'Shadow Knight',
      'Mystic Enchanter',
      'Ranger Scout',
      'Battle Mage',
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: classes
          .map((cls) => ChoiceChip(
                label: Text(cls),
                selected: _selectedClass == cls,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedClass = cls);
                },
              ))
          .toList(),
    );
  }

  Widget _buildBackgroundSelector() {
    final backgrounds = [
      'Exiled Noble',
      'Street Outlaw',
      'Lost Scholar',
      'Wandering Mercenary',
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: backgrounds
          .map((bg) => ChoiceChip(
                label: Text(bg),
                selected: _selectedBackground == bg,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedBackground = bg);
                },
              ))
          .toList(),
    );
  }
}
