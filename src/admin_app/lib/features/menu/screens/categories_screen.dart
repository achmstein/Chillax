import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
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
    final notifier = ref.read(menuProvider.notifier);

    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action bar with back button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () => context.go('/menu'),
                tooltip: 'Back to menu',
              ),
              Text(
                'Categories',
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _showCategoryForm(context),
                tooltip: 'Add category',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () => notifier.loadMenu(),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: state.isLoading && state.categories.isEmpty
              ? const ShimmerLoadingList(showLeadingCircle: false)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (state.error != null)
                      Padding(
                        padding: kScreenPadding,
                        child: FAlert(
                          style: FAlertStyle.destructive(),
                          icon: const Icon(Icons.warning),
                          title: const Text('Error'),
                          subtitle: Text(state.error!),
                        ),
                      ),

                    // Categories list
                    Expanded(
                      child: state.categories.isEmpty
                          ? const EmptyState(
                              icon: Icons.category,
                              title: 'No categories found',
                              subtitle: 'Click the + button above to create one',
                            )
                          : ListView.separated(
                              padding: kScreenPadding,
                              itemCount: state.categories.length,
                              separatorBuilder: (_, __) => const FDivider(),
                              itemBuilder: (context, index) {
                                final category = state.categories[index];
                                final itemCount = notifier.getItemCountForCategory(category.id);
                                return _CategoryListItem(
                                  category: category,
                                  itemCount: itemCount,
                                  onEdit: () => _showCategoryForm(context, category: category),
                                  onDelete: () => _deleteCategory(context, category, itemCount),
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

  void _showCategoryForm(BuildContext context, {MenuCategory? category}) {
    final controller = TextEditingController(text: category?.name ?? '');
    final isEditing = category != null;

    showAdaptiveDialog(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.vertical,
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Drinks, Food, Desserts',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: const Text('Cancel'),
            onPress: () => Navigator.of(context).pop(),
          ),
          FButton(
            child: Text(isEditing ? 'Update' : 'Create'),
            onPress: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();

              final notifier = ref.read(menuProvider.notifier);
              bool success;
              if (isEditing) {
                success = await notifier.updateCategory(category.id, name);
              } else {
                success = await notifier.createCategory(name);
              }

              if (mounted && success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Category updated successfully'
                        : 'Category created successfully'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    MenuCategory category,
    int itemCount,
  ) async {
    if (itemCount > 0) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => FDialog(
          direction: Axis.vertical,
          title: const Text('Cannot Delete Category'),
          body: Text(
            'This category has $itemCount item${itemCount > 1 ? 's' : ''}. '
            'Move or delete the items before deleting the category.',
          ),
          actions: [
            FButton(
              child: const Text('OK'),
              onPress: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Delete Category?'),
        body: Text('Are you sure you want to delete "${category.name}"?'),
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
      final success = await ref.read(menuProvider.notifier).deleteCategory(category.id);
      if (mounted && success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    }
  }
}

class _CategoryListItem extends StatelessWidget {
  final MenuCategory category;
  final int itemCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListItem({
    required this.category,
    required this.itemCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              color: theme.colors.primary,
            ),
          ),
          const SizedBox(width: 16),
          // Name and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount item${itemCount != 1 ? 's' : ''}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: theme.colors.mutedForeground,
                ),
                onPressed: onEdit,
                tooltip: 'Edit category',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: itemCount > 0
                      ? theme.colors.mutedForeground.withValues(alpha: 0.5)
                      : theme.colors.destructive,
                ),
                onPressed: onDelete,
                tooltip: itemCount > 0
                    ? 'Cannot delete: has items'
                    : 'Delete category',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
