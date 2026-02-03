import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../widgets/menu_item_form_sheet.dart';

class MenuListScreen extends ConsumerStatefulWidget {
  const MenuListScreen({super.key});

  @override
  ConsumerState<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends ConsumerState<MenuListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(menuProvider.notifier).loadMenu();
    });

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/menu' && previous != '/menu' && previous != null) {
        ref.read(menuProvider.notifier).loadMenu();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AppText(l10n.menu, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              if (state.items.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppText(
                  '${state.items.length}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.category, size: 22),
                onPressed: () => context.go('/categories'),
                tooltip: l10n.categories,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _showItemForm(context),
                tooltip: l10n.addItem,
              ),
            ],
          ),
        ),

        // Category filter chips
        if (state.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: l10n.all,
                    isSelected: state.selectedCategoryId == null,
                    onTap: () {
                      ref.read(menuProvider.notifier).selectCategory(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...state.categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: category.name.localized(context),
                        isSelected: state.selectedCategoryId == category.id,
                        onTap: () {
                          ref.read(menuProvider.notifier).selectCategory(category.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Content - List view like rooms
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.items.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: state.filteredItems.isEmpty
                ? EmptyState(
                    icon: Icons.restaurant_menu_outlined,
                    title: l10n.noItemsFound,
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(menuProvider.notifier).loadMenu(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = state.filteredItems[index];
                        return _MenuItemTile(
                          item: item,
                          onToggleAvailability: (value) {
                            ref.read(menuProvider.notifier).updateItemAvailability(item.id, value);
                          },
                          onEdit: () => _showItemForm(context, item: item),
                          onDelete: () => _deleteItem(context, item),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showItemForm(BuildContext context, {MenuItem? item}) {
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (context) => MenuItemFormSheet(item: item),
    );
  }

  Future<void> _deleteItem(BuildContext context, MenuItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.deleteItem),
        body: AppText(l10n.deleteItemConfirmation(item.name.localized(context))),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.delete),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(menuProvider.notifier).deleteItem(item.id);
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colors.primary : theme.colors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AppText(
          label,
          style: theme.typography.sm.copyWith(
            color: isSelected
                ? theme.colors.primaryForeground
                : theme.colors.secondaryForeground,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Menu item tile - simple list design like rooms
class _MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuItemTile({
    required this.item,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.isAvailable
                  ? theme.colors.primary.withValues(alpha: 0.1)
                  : theme.colors.mutedForeground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant,
              size: 24,
              color: item.isAvailable ? theme.colors.primary : theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.name.localized(context),
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppText(
                      l10n.priceFormat(item.price.toStringAsFixed(0)),
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppText(
                      '• ${item.catalogTypeName.localized(context)}',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Availability toggle
          FSwitch(
            value: item.isAvailable,
            onChange: onToggleAvailability,
          ),
        ],
      ),
    );
  }
}
