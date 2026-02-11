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
import '../widgets/category_form_sheet.dart';

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
                onPressed: state.isReorderingCategories
                    ? null
                    : () => context.go('/menu'),
                tooltip: l10n.backToMenu,
              ),
              const SizedBox(width: 8),
              AppText(l10n.categories, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (state.isReorderingCategories) ...[
                TextButton(
                  onPressed: () => notifier.cancelCategoryReorder(),
                  child: AppText(l10n.cancel),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.check, size: 22),
                  onPressed: () async {
                    final success = await notifier.saveReorderedCategories();
                    if (context.mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(content: AppText(success ? l10n.orderSavedSuccess : l10n.failedToSaveOrder)),
                      );
                    }
                  },
                  tooltip: l10n.saveOrder,
                ),
              ] else ...[
                if (state.categories.length > 1)
                  IconButton(
                    icon: const Icon(Icons.swap_vert, size: 22),
                    onPressed: () => notifier.toggleCategoryReorderMode(),
                    tooltip: l10n.reorder,
                  ),
                IconButton(
                  icon: const Icon(Icons.add, size: 22),
                  onPressed: () => _showCategoryForm(context),
                  tooltip: l10n.addCategory,
                ),
              ],
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.categories.isEmpty,
            shimmer: const ShimmerLoadingList(showLeadingCircle: false),
            child: RefreshIndicator(
              color: theme.colors.primary,
              backgroundColor: theme.colors.background,
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
                  : state.isReorderingCategories
                      ? ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.categories.length,
                          onReorder: notifier.reorderCategories,
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              color: theme.colors.background,
                              elevation: 2,
                              shadowColor: theme.colors.border,
                              borderRadius: BorderRadius.circular(8),
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            final itemCount = notifier.getItemCountForCategory(category.id);
                            return Column(
                              key: ValueKey(category.id),
                              children: [
                                _CategoryListItem(
                                  category: category,
                                  itemCount: itemCount,
                                  isReorderMode: true,
                                  onTap: () {},
                                  onDelete: () {},
                                ),
                                if (index < state.categories.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: theme.colors.border,
                                  ),
                              ],
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            final itemCount = notifier.getItemCountForCategory(category.id);
                            return Column(
                              children: [
                                _CategoryListItem(
                                  category: category,
                                  itemCount: itemCount,
                                  onTap: () => _showCategoryForm(context, category: category),
                                  onDelete: () => _deleteCategory(context, category, itemCount),
                                ),
                                if (index < state.categories.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: theme.colors.border,
                                  ),
                              ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => CategoryFormSheet(category: category),
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
        body: AppText(l10n.deleteCategoryConfirmation(category.name.localized(context))),
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
  final bool isReorderMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CategoryListItem({
    required this.category,
    required this.itemCount,
    this.isReorderMode = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return FTappable(
      onPress: isReorderMode ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category,
                size: 24,
                color: theme.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Name and count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    category.name.localized(context),
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    l10n.itemCount(itemCount),
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            if (isReorderMode)
              Icon(
                Icons.drag_handle,
                color: theme.colors.mutedForeground,
              )
            else
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 20,
                  color: itemCount > 0
                      ? theme.colors.mutedForeground.withValues(alpha: 0.5)
                      : theme.colors.destructive,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
