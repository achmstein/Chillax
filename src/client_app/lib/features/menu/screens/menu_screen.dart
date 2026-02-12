import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';
import '../providers/favorites_provider.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';
import '../widgets/item_customization_sheet.dart';

/// Provider for grouped menu items by category with localized names
final groupedMenuItemsProvider = FutureProvider.family<Map<MenuCategory, List<MenuItem>>, Locale>((ref, locale) async {
  final service = ref.watch(menuServiceProvider);
  final categories = await service.getCategories();
  final items = await service.getMenuItems();

  final grouped = <MenuCategory, List<MenuItem>>{};

  // Add "Most Popular" section at the top if there are popular items
  final popularItems = items.where((item) => item.isPopular).toList();
  if (popularItems.isNotEmpty) {
    final popularCategory = MenuCategory(
      id: -1,
      name: LocalizedText(en: 'Most Popular', ar: 'الأكثر طلباً'),
      displayOrder: -1,
    );
    grouped[popularCategory] = popularItems;
  }

  for (final category in categories) {
    final categoryItems = items.where((item) => item.catalogTypeId == category.id).toList();
    if (categoryItems.isNotEmpty) {
      grouped[category] = categoryItems;
    }
  }
  return grouped;
});

/// Menu screen showing food and drinks grouped by category
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  final ValueNotifier<String?> _selectedCategoryNotifier = ValueNotifier(null);

  bool _showSearch = false;
  String _searchQuery = '';
  List<String> _categoryNames = [];
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _selectedCategoryNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _isProgrammaticScroll) return;

    // Single pass: find the item at the viewport top
    int topIndex = -1;
    double topLeading = 0.0;
    double topTrailing = 0.0;
    for (final p in positions) {
      if (p.itemLeadingEdge <= 0 && p.itemTrailingEdge > 0 && p.index > topIndex) {
        topIndex = p.index;
        topLeading = p.itemLeadingEdge;
        topTrailing = p.itemTrailingEdge;
      }
    }
    if (topIndex < 0) return;

    final extent = topTrailing - topLeading;
    final fraction = extent > 0 ? (-topLeading).clamp(0.0, extent) / extent : 0.0;
    final offset = topIndex + fraction;

    if (_categoryNames.isNotEmpty) {
      final catIndex = offset.floor().clamp(0, _categoryNames.length - 1);
      final newCategory = _categoryNames[catIndex];
      if (newCategory != _selectedCategoryNotifier.value) {
        _selectedCategoryNotifier.value = newCategory;
      }
    }
  }

  void _scrollToCategory(String category) {
    final index = _categoryNames.indexOf(category);
    if (index == -1) return;

    _selectedCategoryNotifier.value = category;

    _isProgrammaticScroll = true;
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        _isProgrammaticScroll = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final groupedItemsAsync = ref.watch(groupedMenuItemsProvider(locale));
    final cart = ref.watch(cartProvider);
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header with search toggle
        FHeader(
          title: AppText(l10n.menu, style: TextStyle(fontSize: 18)),
          suffixes: [
            FHeaderAction(
              icon: Icon(_showSearch ? FIcons.x : FIcons.search, size: 20),
              onPress: _toggleSearch,
            ),
          ],
        ),

        // Content
        Expanded(
          child: groupedItemsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: colors.primary)),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FIcons.circleAlert, size: 48, color: colors.mutedForeground),
                  const SizedBox(height: 16),
                  AppText(l10n.failedToLoadMenu(error.toString()), style: TextStyle(color: colors.foreground)),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => ref.refresh(groupedMenuItemsProvider(locale)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (groupedItems) {
              if (groupedItems.isEmpty) {
                return Center(child: AppText(l10n.noItemsAvailable));
              }

              // Filter items based on search
              final filteredItems = _filterItemsWithLocale(groupedItems, locale);

              // Store category names for scroll tracking
              _categoryNames = filteredItems.keys.map((c) => c.name.getText(locale)).toList();

              // Set initial selected category
              if (_selectedCategoryNotifier.value == null && _categoryNames.isNotEmpty) {
                _selectedCategoryNotifier.value = _categoryNames.first;
              }

              return Column(
                children: [
                  // Search bar — toggled by header search icon
                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: FTextField(
                        control: FTextFieldControl.managed(controller: _searchController),
                        hint: l10n.searchMenu,
                        autofocus: true,
                      ),
                    ),

                  // Sticky category menu — listens to notifier internally,
                  // only its chips rebuild on selection change.
                  _CategoryMenu(
                    categories: _categoryNames,
                    selectedCategoryNotifier: _selectedCategoryNotifier,
                    onCategoryTap: _scrollToCategory,
                  ),

                  // Menu items — never rebuilt by scroll-driven state changes
                  Expanded(
                    child: RefreshIndicator(
                      color: colors.primary,
                      backgroundColor: colors.background,
                      onRefresh: () async => ref.refresh(groupedMenuItemsProvider(locale)),
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final entry = filteredItems.entries.elementAt(index);
                          final categoryName = entry.key.name.getText(locale);
                          final items = entry.value;
                          return _CategorySection(
                            categoryName: categoryName,
                            items: items,
                            locale: locale,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // View Cart button (fixed at bottom)
        if (!cart.isEmpty)
          Builder(
            builder: (context) {
            final btnColors = context.theme.colors;
            final btnL10n = AppLocalizations.of(context)!;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: btnColors.background,
              border: Border(
                top: BorderSide(color: btnColors.border),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColors.primary,
                  foregroundColor: btnColors.primaryForeground,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      btnL10n.viewCart,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    AppText(
                      btnL10n.priceFormat(cart.totalPrice.toStringAsFixed(2)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ],
    );
  }

  Map<MenuCategory, List<MenuItem>> _filterItemsWithLocale(Map<MenuCategory, List<MenuItem>> items, Locale locale) {
    if (_searchQuery.isEmpty) return items;

    final filtered = <MenuCategory, List<MenuItem>>{};
    final query = _searchQuery.toLowerCase();

    for (final entry in items.entries) {
      final matchingItems = entry.value
          .where((item) =>
              item.name.getText(locale).toLowerCase().contains(query) ||
              item.description.getText(locale).toLowerCase().contains(query) ||
              item.name.en.toLowerCase().contains(query) ||
              item.description.en.toLowerCase().contains(query))
          .toList();
      if (matchingItems.isNotEmpty) {
        filtered[entry.key] = matchingItems;
      }
    }
    return filtered;
  }
}

/// Horizontal category menu — listens to [selectedCategoryNotifier] internally
/// so only this widget rebuilds when the selection changes during scrolling.
class _CategoryMenu extends StatefulWidget {
  final List<String> categories;
  final ValueNotifier<String?> selectedCategoryNotifier;
  final Function(String) onCategoryTap;

  const _CategoryMenu({
    required this.categories,
    required this.selectedCategoryNotifier,
    required this.onCategoryTap,
  });

  @override
  State<_CategoryMenu> createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<_CategoryMenu> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.selectedCategoryNotifier.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.selectedCategoryNotifier.removeListener(_onSelectionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    _scrollToSelectedCategory();
    // Rebuild chips to update highlight — only this widget, not the parent.
    if (mounted) setState(() {});
  }

  void _scrollToSelectedCategory() {
    final selected = widget.selectedCategoryNotifier.value;
    if (selected == null) return;
    final index = widget.categories.indexOf(selected);
    if (index == -1 || !_scrollController.hasClients) return;

    const chipWidth = 80.0;
    final targetOffset = (index * chipWidth) - 100;

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final selected = widget.selectedCategoryNotifier.value;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = category == selected;
          return GestureDetector(
            onTap: () => widget.onCategoryTap(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? colors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: AppText(
                category,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.mutedForeground,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Category section with header and items
class _CategorySection extends StatelessWidget {
  final String categoryName;
  final List<MenuItem> items;
  final Locale locale;

  const _CategorySection({
    super.key,
    required this.categoryName,
    required this.items,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AppText(
            categoryName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colors.foreground,
            ),
          ),
        ),
        // Items
        ...items.asMap().entries.map((entry) => MenuItemTile(
          item: entry.value,
          isLast: entry.key == items.length - 1,
          locale: locale,
        )),
      ],
    );
  }
}

/// Menu item tile - list style with stepper
class MenuItemTile extends ConsumerWidget {
  final MenuItem item;
  final bool isLast;
  final Locale locale;

  const MenuItemTile({super.key, required this.item, this.isLast = false, required this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final cartQuantity = _getCartQuantity(cart, item.id);
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = favoritesState.favoriteIds.contains(item.id);

    return GestureDetector(
      onTap: () => _showCustomizationSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.border),
                ),
              ),
        child: Row(
          children: [
            // Image with heart overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: item.pictureUri != null
                        ? CachedNetworkImage(
                            imageUrl: item.pictureUri!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colors.muted,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colors.muted,
                              child: Icon(FIcons.utensils, size: 24, color: colors.mutedForeground),
                            ),
                          )
                        : Container(
                            color: colors.muted,
                            child: Icon(FIcons.utensils, size: 24, color: colors.mutedForeground),
                          ),
                  ),
                ),
                // Heart icon overlay - positioned based on text direction
                PositionedDirectional(
                  top: 4,
                  start: 4,
                  child: GestureDetector(
                    onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(item.id),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? Colors.red : Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    item.name.getText(locale),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.foreground,
                    ),
                  ),
                  if (item.description.getText(locale).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AppText(
                      item.description.getText(locale),
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  AppText(
                    l10n.priceFormat(item.price.toStringAsFixed(2)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity stepper or add button
            cartQuantity > 0
                ? _QuantityStepper(
                    quantity: cartQuantity,
                    onIncrement: () => _addToCart(ref),
                    onDecrement: () => _decrementFromCart(ref, cart, item.id),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      GestureDetector(
                        onTap: () => _handleAddTap(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            item.customizations.isNotEmpty ? FIcons.chevronRight : FIcons.plus,
                            color: colors.primaryForeground,
                            size: 18,
                          ),
                        ),
                      ),
                      if (item.customizations.isNotEmpty)
                        Positioned(
                          top: 36,
                          child: AppText(
                            l10n.customizable,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  int _getCartQuantity(Cart cart, int productId) {
    int total = 0;
    for (final cartItem in cart.items) {
      if (cartItem.productId == productId) {
        total += cartItem.quantity;
      }
    }
    return total;
  }

  void _handleAddTap(BuildContext context, WidgetRef ref) {
    if (item.customizations.isEmpty) {
      _addToCart(ref);
    } else {
      _showCustomizationSheet(context, ref);
    }
  }

  void _addToCart(WidgetRef ref) {
    final cartItem = CartItem.fromMenuItem(item);
    ref.read(cartProvider.notifier).addItem(cartItem);
  }

  void _decrementFromCart(WidgetRef ref, Cart cart, int productId) {
    for (int i = cart.items.length - 1; i >= 0; i--) {
      if (cart.items[i].productId == productId) {
        if (cart.items[i].quantity > 1) {
          ref.read(cartProvider.notifier).updateQuantity(i, cart.items[i].quantity - 1);
        } else {
          ref.read(cartProvider.notifier).removeItem(i);
        }
        break;
      }
    }
  }

  void _showCustomizationSheet(BuildContext context, WidgetRef ref) {
    if (item.customizations.isEmpty) {
      _addToCart(ref);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => ItemCustomizationSheet(item: item),
      );
    }
  }
}

/// Quantity stepper widget
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // Wrap in GestureDetector with opaque behavior to prevent taps from propagating to parent
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb taps to prevent parent from receiving them
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDecrement,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  quantity == 1 ? FIcons.trash2 : FIcons.minus,
                  color: quantity == 1 ? AppTheme.errorColor : colors.primary,
                  size: 18,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              alignment: Alignment.center,
              child: AppText(
                '$quantity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colors.foreground,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onIncrement,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  FIcons.plus,
                  color: colors.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
