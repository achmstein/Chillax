import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';
import '../widgets/item_customization_sheet.dart';

/// Menu screen showing food and drinks
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider(selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          categoriesAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => const SizedBox.shrink(),
            data: (categories) => SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: selectedCategory == null,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state = null;
                      },
                    ),
                  ),
                  ...categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: selectedCategory == category.id,
                          onSelected: (_) {
                            ref.read(selectedCategoryProvider.notifier).state =
                                category.id;
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),

          // Menu items grid
          Expanded(
            child: menuItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Failed to load menu: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(menuItemsProvider(selectedCategory)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text('No items available'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return MenuItemCard(item: items[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu item card
class MenuItemCard extends ConsumerWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showCustomizationSheet(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: item.pictureUri != null
                  ? CachedNetworkImage(
                      imageUrl: item.pictureUri!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant, size: 40),
                    ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizationSheet(BuildContext context, WidgetRef ref) {
    if (item.customizations.isEmpty) {
      // No customizations, add directly
      final cartItem = CartItem.fromMenuItem(item);
      ref.read(cartProvider.notifier).addItem(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // Navigate to cart
            },
          ),
        ),
      );
    } else {
      // Show customization sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => ItemCustomizationSheet(item: item),
      );
    }
  }
}
