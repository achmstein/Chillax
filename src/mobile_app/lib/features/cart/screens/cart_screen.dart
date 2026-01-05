import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../../orders/services/order_service.dart';

/// Shopping cart screen
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _tableController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(context),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Cart items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      return CartItemCard(
                        item: cart.items[index],
                        index: index,
                      );
                    },
                  ),
                ),

                // Order details and checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Table number
                        TextField(
                          controller: _tableController,
                          decoration: const InputDecoration(
                            labelText: 'Table Number (optional)',
                            prefixIcon: Icon(Icons.table_restaurant),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        // Note
                        TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Order Note (optional)',
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${cart.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Checkout button
                        ElevatedButton(
                          onPressed: checkoutState.isLoading
                              ? null
                              : () => _handleCheckout(cart),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: checkoutState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Place Order',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the menu',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(Cart cart) async {
    final tableNumber = int.tryParse(_tableController.text);
    final note = _noteController.text.isNotEmpty ? _noteController.text : null;

    final success = await ref.read(checkoutProvider.notifier).submitOrder(
          items: cart.items,
          tableNumber: tableNumber,
          customerNote: note,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _tableController.clear();
      _noteController.clear();
    } else if (mounted) {
      final error = ref.read(checkoutProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to place order'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

/// Cart item card
class CartItemCard extends ConsumerWidget {
  final CartItem item;
  final int index;

  const CartItemCard({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.selectedCustomizations.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.selectedCustomizations
                              .map((c) => c.optionName)
                              .join(', '),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (item.specialInstructions != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${item.specialInstructions}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quantity and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: item.quantity > 1
                          ? () {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(index, item.quantity - 1);
                            }
                          : null,
                      iconSize: 24,
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(index, item.quantity + 1);
                      },
                      iconSize: 24,
                    ),
                  ],
                ),

                // Price
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
