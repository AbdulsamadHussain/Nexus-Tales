import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final items = inventory.isEmpty ? MockData.mockInventory : inventory;
    final selectedItem = ref.watch(selectedInventoryItemProvider);
    final activeTab = ref.watch(inventoryTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Inventory', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: Row(
        children: [
          // Left: Item list
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Tabs
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['weapons', 'armor', 'consumables', 'materials']
                        .map((tab) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: FilterChip(
                                label: Text(tab.toUpperCase()),
                                selected: activeTab == tab,
                                onSelected: (_) => ref
                                    .read(inventoryTabProvider.notifier)
                                    .state = tab,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                // Item list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => ref
                            .read(selectedInventoryItemProvider.notifier)
                            .state = item,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: selectedItem?.id == item.id
                                ? AppColors.accentBronze.withValues(alpha: 0.2)
                                : AppColors.surfaceCard,
                            border: Border.all(
                              color: selectedItem?.id == item.id
                                  ? AppColors.accentBronze
                                  : AppColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTypography.headingSmall),
                              Text(item.rarity,
                                  style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: Item detail
          if (selectedItem != null)
            Expanded(
              flex: 1,
              child: Container(
                color: AppColors.surfaceCard,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedItem.name,
                        style: AppTypography.headingMedium),
                    const SizedBox(height: AppSpacing.md),
                    Text(selectedItem.description,
                        style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Rarity: ${selectedItem.rarity}',
                        style: AppTypography.bodyMedium),
                    Text('Type: ${selectedItem.itemType}',
                        style: AppTypography.bodyMedium),
                    Text('Qty: ${selectedItem.quantity}',
                        style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
