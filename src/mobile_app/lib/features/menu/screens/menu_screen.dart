import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';
import '../providers/favorites_provider.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';
import '../widgets/item_customization_sheet.dart';

/// Provider for grouped menu items by category
final groupedMenuItemsProvider = FutureProvider<Map<String, List<MenuItem>>>((ref) async {
  final service = ref.watch(menuServiceProvider);
  final categories = await service.getCategories();
  final items = await service.getMenuItems();

  final grouped = <String, List<MenuItem>>{};
  for (final category in categories) {
    final categoryItems = items.where((item) => item.catalogTypeId == category.id).toList();
    if (categoryItems.isNotEmpty) {
      grouped[category.name] = categoryItems;
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GlobalKey> _categoryKeys = {};

  String? _selectedCategory;
  bool _showSearch = false;
  double _lastScrollOffset = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final isScrollingDown = offset > _lastScrollOffset;

    // Don't show search during programmatic scroll (category tap)
    if (!_isProgrammaticScroll) {
      // Show search when scrolling down past threshold, hide when scrolling up
      if (offset > 50 && isScrollingDown && !_showSearch) {
        setState(() => _showSearch = true);
      } else if (offset < 50 || (!isScrollingDown && offset < _lastScrollOffset - 30)) {
        if (_showSearch && _searchQuery.isEmpty) {
          setState(() => _showSearch = false);
        }
      }
    }

    _lastScrollOffset = offset;

    // Update selected category based on scroll position (skip during programmatic scroll)
    if (!_isProgrammaticScroll) {
      _updateSelectedCategory();
    }
  }

  void _updateSelectedCategory() {
    if (_categoryKeys.isEmpty) return;

    String? visibleCategory;
    double minDistance = double.infinity;

    for (final entry in _categoryKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          final distance = (position.dy - 150).abs(); // 150 is approximate header height
          if (distance < minDistance && position.dy < 200) {
            minDistance = distance;
            visibleCategory = entry.key;
          }
        }
      }
    }

    if (visibleCategory != null && visibleCategory != _selectedCategory) {
      setState(() => _selectedCategory = visibleCategory);
    }
  }

  bool _isProgrammaticScroll = false;

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      _isProgrammaticScroll = true;
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      ).then((_) {
        _isProgrammaticScroll = false;
      });
      setState(() => _selectedCategory = category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedItemsAsync = ref.watch(groupedMenuItemsProvider);
    final cart = ref.watch(cartProvider);
    final hasItems = !cart.isEmpty;
    final colors = context.theme.colors;

    return Column(
      children: [
        // Header
        FHeader(
          title: const Text('Menu', style: TextStyle(fontSize: 18)),
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
                  Text('Failed to load menu: $error', style: TextStyle(color: colors.foreground)),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => ref.refresh(groupedMenuItemsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (groupedItems) {
              if (groupedItems.isEmpty) {
                return const Center(child: Text('No items available'));
              }

              // Initialize category keys
              for (final category in groupedItems.keys) {
                _categoryKeys.putIfAbsent(category, () => GlobalKey());
              }

              // Set initial selected category
              _selectedCategory ??= groupedItems.keys.first;

              // Filter items based on search
              final filteredItems = _filterItems(groupedItems);

              return Column(
                children: [
                  // Search bar (animated) - above category menu
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _showSearch ? 56 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showSearch ? 1 : 0,
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search menu...',
                              prefixIcon: Icon(FIcons.search, size: 20, color: colors.mutedForeground),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(FIcons.x, size: 20, color: colors.mutedForeground),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: colors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: colors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: colors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sticky category menu
                  _CategoryMenu(
                    categories: groupedItems.keys.toList(),
                    selectedCategory: _selectedCategory,
                    onCategoryTap: _scrollToCategory,
                  ),

                  // Menu items
                  Expanded(
                    child: RefreshIndicator(
                      color: colors.primary,
                      backgroundColor: colors.background,
                      onRefresh: () async => ref.refresh(groupedMenuItemsProvider),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 16),
                        cacheExtent: 2000, // Pre-render off-screen items for category scrolling
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final category = filteredItems.keys.elementAt(index);
                          final items = filteredItems[category]!;
                          return _CategorySection(
                            key: _categoryKeys[category],
                            categoryName: category,
                            items: items,
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
        if (hasItems)
          Builder(
            builder: (context) {
            final btnColors = context.theme.colors;
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
                    const Text(
                      'View Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '£${cart.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
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

  Map<String, List<MenuItem>> _filterItems(Map<String, List<MenuItem>> items) {
    if (_searchQuery.isEmpty) return items;

    final filtered = <String, List<MenuItem>>{};
    final query = _searchQuery.toLowerCase();

    for (final entry in items.entries) {
      final matchingItems = entry.value
          .where((item) =>
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query))
          .toList();
      if (matchingItems.isNotEmpty) {
        filtered[entry.key] = matchingItems;
      }
    }
    return filtered;
  }
}

/// Horizontal category menu
class _CategoryMenu extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String) onCategoryTap;

  const _CategoryMenu({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  State<_CategoryMenu> createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<_CategoryMenu> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    for (final category in widget.categories) {
      _chipKeys[category] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(_CategoryMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _scrollToSelectedCategory();
    }
  }

  void _scrollToSelectedCategory() {
    if (widget.selectedCategory == null) return;
    final key = _chipKeys[widget.selectedCategory];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 200),
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
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
          final isSelected = category == widget.selectedCategory;
          return GestureDetector(
            key: _chipKeys[category],
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
              child: Text(
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

  const _CategorySection({
    super.key,
    required this.categoryName,
    required this.items,
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
          child: Text(
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
        )),
      ],
    );
  }
}

/// Menu item tile - list style with stepper
class MenuItemTile extends ConsumerWidget {
  final MenuItem item;
  final bool isLast;

  const MenuItemTile({super.key, required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
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
                // Heart icon overlay
                Positioned(
                  top: 4,
                  right: 4,
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
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.foreground,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '£${item.price.toStringAsFixed(2)}',
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
                : GestureDetector(
                    onTap: () => _handleAddTap(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        FIcons.plus,
                        color: colors.primaryForeground,
                        size: 18,
                      ),
                    ),
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
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
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
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colors.foreground,
              ),
            ),
          ),
          GestureDetector(
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
    );
  }
}
