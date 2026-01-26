import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../../orders/services/order_service.dart';

/// Shopping cart screen - minimalistic
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

    return FScaffold(
      child: SafeArea(
        bottom: false,
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
                      'Cart',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!cart.isEmpty)
                    GestureDetector(
                      onTap: () => _showClearCartDialog(context),
                      child: const Icon(FIcons.trash2, size: 22),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? _buildEmptyCart()
                  : Column(
                      children: [
                        // Cart items
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: cart.items.length,
                            separatorBuilder: (_, _) => const FDivider(),
                            itemBuilder: (context, index) {
                              return CartItemTile(
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
                            border: Border(
                              top: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Table number
                                FTextField(
                                  control: FTextFieldControl.managed(controller: _tableController),
                                  label: const Text('Table Number (optional)'),
                                  hint: 'Enter table number',
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                // Note
                                FTextField.multiline(
                                  control: FTextFieldControl.managed(controller: _noteController),
                                  label: const Text('Order Note (optional)'),
                                  hint: 'Any special requests',
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
                                      '£${cart.totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Checkout button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: checkoutState.isLoading
                                        ? null
                                        : () => _handleCheckout(cart),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: checkoutState.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Place Order',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.shoppingCart,
            size: 80,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the menu',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style.call,
        animation: animation,
        title: const Text('Clear Cart'),
        body: const Text('Remove all items from your cart?'),
        direction: Axis.horizontal,
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(context);
            },
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
      showFToast(
        context: context,
        title: const Text('Order placed successfully!'),
        icon: Icon(FIcons.check, color: AppTheme.successColor),
      );
      _tableController.clear();
      _noteController.clear();
    } else if (mounted) {
      final error = ref.read(checkoutProvider).error;
      showFToast(
        context: context,
        title: Text(error ?? 'Failed to place order'),
        icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
      );
    }
  }
}

/// Cart item tile - minimalistic
class CartItemTile extends ConsumerWidget {
  final CartItem item;
  final int index;

  const CartItemTile({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (item.specialInstructions != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: ${item.specialInstructions}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Remove button
              FButton.icon(
                style: FButtonStyle.ghost(),
                onPress: () {
                  ref.read(cartProvider.notifier).removeItem(index);
                },
                child: const Icon(FIcons.x, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quantity and price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity controls
              Row(
                children: [
                  FButton.icon(
                    style: FButtonStyle.outline(),
                    onPress: item.quantity > 1
                        ? () {
                            ref
                                .read(cartProvider.notifier)
                                .updateQuantity(index, item.quantity - 1);
                          }
                        : null,
                    child: const Icon(FIcons.minus, size: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FButton.icon(
                    style: FButtonStyle.outline(),
                    onPress: () {
                      ref
                          .read(cartProvider.notifier)
                          .updateQuantity(index, item.quantity + 1);
                    },
                    child: const Icon(FIcons.plus, size: 16),
                  ),
                ],
              ),

              // Price
              Text(
                '£${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
