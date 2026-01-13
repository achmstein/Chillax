import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final theme = context.theme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('Menu Management'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.category),
              onPress: () => context.go('/categories'),
            ),
            FHeaderAction(
              icon: const Icon(Icons.add),
              onPress: () => _showItemForm(context),
            ),
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(menuProvider.notifier).loadMenu();
              },
            ),
          ],
        ),
        const FDivider(),

        // Content
        Expanded(
          child: state.isLoading && state.items.isEmpty
              ? const Center(child: FProgress())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FAlert(style: FAlertStyle.destructive(), 
                          icon: const Icon(Icons.warning),
                          title: const Text('Error'),
                          subtitle: Text(state.error!),
                        ),
                      ),

                    // Category filter
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: 'All',
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

                    // Items grid
                    Expanded(
                      child: state.filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 64,
                                    color: theme.colors.mutedForeground,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items found',
                                    style: theme.typography.lg.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 350,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: 200,
                              ),
                              itemCount: state.filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = state.filteredItems[index];
                                return _MenuItemCard(
                                  item: item,
                                  currencyFormat: currencyFormat,
                                  onToggleAvailability: (value) {
                                    ref.read(menuProvider.notifier)
                                        .updateItemAvailability(item.id, value);
                                  },
                                  onEdit: () => _showItemForm(context, item: item),
                                  onDelete: () => _deleteItem(context, item),
                                );
                              },
                            ),
                    ),
                  ],
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
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Delete Item?'),
        body: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: const Text('Delete'),
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
        child: Text(
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
  final NumberFormat currencyFormat;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuItemCard({
    required this.item,
    required this.currencyFormat,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.all(16),
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
                    Text(
                      item.name,
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FBadge(style: FBadgeStyle.secondary(),
                      child: Text(item.catalogTypeName),
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
          Text(
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
              Text(
                currencyFormat.format(item.price),
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.primary,
                ),
              ),
              Row(
                children: [
                  Text(
                    item.isAvailable ? 'Available' : 'Unavailable',
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
