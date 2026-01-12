import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
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
    final theme = context.theme;
    final notifier = ref.read(menuProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/menu'),
                tooltip: 'Back to Menu',
              ),
              const SizedBox(width: 8),
              Text(
                'Menu Categories',
                style: context.theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FButton(
                style: FButtonStyle.outline(),
                onPress: () => _showCategoryForm(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Add Category'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => notifier.loadMenu(),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const FDivider(),

        // Content
        Expanded(
          child: state.isLoading && state.categories.isEmpty
              ? const Center(child: FProgress())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
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
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 64,
                                    color: theme.colors.mutedForeground,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No categories found',
                                    style: theme.typography.lg.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Add Category" above to create one',
                                    style: theme.typography.sm.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.categories.length,
                              itemBuilder: (context, index) {
                                final category = state.categories[index];
                                final itemCount = notifier.getItemCountForCategory(category.id);
                                return _CategoryCard(
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

              Navigator.of(context).pop();

              final notifier = ref.read(menuProvider.notifier);
              bool success;
              if (isEditing) {
                success = await notifier.updateCategory(category.id, name);
              } else {
                success = await notifier.createCategory(name);
              }

              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final MenuCategory category;
  final int itemCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.itemCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      style: theme.typography.lg.copyWith(
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
        ),
      ),
    );
  }
}
