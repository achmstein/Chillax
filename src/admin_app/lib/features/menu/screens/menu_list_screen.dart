import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
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

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.items.isEmpty,
            shimmer: const ShimmerLoadingList(showLeadingCircle: false),
            child: RefreshIndicator(
                  onRefresh: () => ref.read(menuProvider.notifier).loadMenu(),
                  child: CustomScrollView(
                    slivers: [
                      // Category filter
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: kScreenPadding,
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
                                      label: category.name,
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
                      ),

                      // Items grid
                      if (state.filteredItems.isEmpty)
                        SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.restaurant,
                            title: l10n.noItemsFound,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: kScreenPadding,
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              mainAxisExtent: 200,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = state.filteredItems[index];
                                return _MenuItemCard(
                                  item: item,
                                  onToggleAvailability: (value) {
                                    ref.read(menuProvider.notifier)
                                        .updateItemAvailability(item.id, value);
                                  },
                                  onEdit: () => _showItemForm(context, item: item),
                                  onDelete: () => _deleteItem(context, item),
                                );
                              },
                              childCount: state.filteredItems.length,
                            ),
                          ),
                        ),
                    ],
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
        body: AppText(l10n.deleteItemConfirmation(item.name)),
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

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuItemCard({
    required this.item,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: kScreenPadding,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      item.name,
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FBadge(style: FBadgeStyle.secondary(),
                      child: AppText(item.catalogTypeName),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit,
                      size: 18,
                      color: theme.colors.mutedForeground,
                    ),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete,
                      size: 18,
                      color: theme.colors.destructive,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          AppText(
            item.description,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                l10n.priceFormat(item.price.toStringAsFixed(0)),
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.primary,
                ),
              ),
              Row(
                children: [
                  AppText(
                    item.isAvailable
                        ? l10n.availableLabel
                        : l10n.unavailable,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FSwitch(
                    value: item.isAvailable,
                    onChange: onToggleAvailability,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
