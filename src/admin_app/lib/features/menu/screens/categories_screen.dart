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

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/categories' && previous != '/categories' && previous != null) {
        ref.read(menuProvider.notifier).loadMenu();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final notifier = ref.read(menuProvider.notifier);
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
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () => context.go('/menu'),
                tooltip: l10n.backToMenu,
              ),
              const SizedBox(width: 8),
              AppText(l10n.categories, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _showCategoryForm(context),
                tooltip: l10n.addCategory,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.categories.isEmpty,
            shimmer: const ShimmerLoadingList(showLeadingCircle: false),
            child: RefreshIndicator(
              onRefresh: () => ref.read(menuProvider.notifier).loadMenu(),
              child: state.categories.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(
                          icon: Icons.category,
                          title: l10n.noCategoriesFound,
                          subtitle: l10n.clickAddCategoryHint,
                        ),
                      ],
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
          ),
        ),
      ],
    );
  }

  void _showCategoryForm(BuildContext context, {MenuCategory? category}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: category?.name ?? '');
    final isEditing = category != null;

    showAdaptiveDialog(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.vertical,
        title: AppText(isEditing ? l10n.editCategory : l10n.addCategory),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.categoryName,
              hintText: l10n.categoryNameHint,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(),
          ),
          FButton(
            child: AppText(isEditing ? l10n.update : l10n.create),
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
                    content: AppText(isEditing
                        ? l10n.categoryUpdatedSuccess
                        : l10n.categoryCreatedSuccess),
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
    final l10n = AppLocalizations.of(context)!;
    if (itemCount > 0) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => FDialog(
          direction: Axis.vertical,
          title: AppText(l10n.cannotDeleteCategory),
          body: AppText(l10n.categoryHasItems(itemCount)),
          actions: [
            FButton(
              child: AppText(l10n.ok),
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
        title: AppText(l10n.deleteCategory),
        body: AppText(l10n.deleteCategoryConfirmation(category.name)),
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
      final success = await ref.read(menuProvider.notifier).deleteCategory(category.id);
      if (mounted && success) {
        messenger.showSnackBar(
          SnackBar(content: AppText(l10n.categoryDeletedSuccess)),
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
                AppText(
                  category.name,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
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
