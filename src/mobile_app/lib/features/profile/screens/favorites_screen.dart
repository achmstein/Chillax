import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../menu/models/menu_item.dart';
import '../../menu/services/menu_service.dart';
import '../../menu/providers/favorites_provider.dart';
import '../../menu/widgets/item_customization_sheet.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';

/// Provider that combines favorites with menu items
final favoriteMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final favoritesState = ref.watch(favoritesProvider);
  final favoriteIds = favoritesState.favoriteIds;

  if (favoriteIds.isEmpty) {
    return [];
  }

  final service = ref.watch(menuServiceProvider);
  final allItems = await service.getMenuItems();

  return allItems.where((item) => favoriteIds.contains(item.id)).toList();
});

/// Screen showing user's favorite menu items
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteItemsAsync = ref.watch(favoriteMenuItemsProvider);
    final colors = context.theme.colors;

    return FScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Custom header with back button
            Container(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(FIcons.arrowLeft, size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Favorites',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: favoriteItemsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.primary),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FIcons.circleAlert, size: 48, color: colors.mutedForeground),
                      const SizedBox(height: 16),
                      Text('Failed to load favorites: $error', style: TextStyle(color: colors.foreground)),
                      const SizedBox(height: 16),
                      FButton(
                        onPress: () => ref.refresh(favoriteMenuItemsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyState();
                  }

                  return RefreshIndicator(
                    color: colors.primary,
                    backgroundColor: colors.background,
                    onRefresh: () async {
                      await ref.read(favoritesProvider.notifier).loadFavorites();
                      ref.invalidate(favoriteMenuItemsProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (context, _) => Divider(height: 1, color: context.theme.colors.border),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _FavoriteItemTile(item: item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on menu items\nto add them to your favorites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          FButton(
            onPress: () => context.go('/menu'),
            child: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }
}

/// Favorite item tile
class _FavoriteItemTile extends ConsumerWidget {
  final MenuItem item;

  const _FavoriteItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final cart = ref.watch(cartProvider);
    final cartQuantity = _getCartQuantity(cart, item.id);

    return GestureDetector(
      onTap: () => _showCustomizationSheet(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                              color: AppTheme.backgroundColor,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.backgroundColor,
                              child: const Icon(FIcons.utensils, size: 24),
                            ),
                          )
                        : Container(
                            color: AppTheme.backgroundColor,
                            child: const Icon(FIcons.utensils, size: 24),
                          ),
                  ),
                ),
                // Heart icon overlay (always filled for favorites)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(item.id),
                    child: const Icon(
                      Icons.favorite,
                      size: 18,
                      color: Colors.red,
                      shadows: [
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
                    '\u00A3${item.price.toStringAsFixed(2)}',
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
