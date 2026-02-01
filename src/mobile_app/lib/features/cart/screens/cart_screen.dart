import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../../orders/services/order_service.dart';
import '../../profile/providers/loyalty_provider.dart';
import '../../rooms/models/room.dart';
import '../../rooms/services/room_service.dart';

/// Shopping cart screen - minimalistic
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _noteController = TextEditingController();
  int _pointsToRedeem = 0;
  bool _usePoints = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

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
                  Expanded(
                    child: AppText(
                      l10n.cart,
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 32, // Account for padding
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Cart items section (top)
                                Column(
                                  children: cart.items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    return Column(
                                      children: [
                                        CartItemTile(item: item, index: index),
                                        if (index < cart.items.length - 1)
                                          Divider(height: 1, color: colors.border),
                                      ],
                                    );
                                  }).toList(),
                                ),

                                // Checkout section (bottom)
                                Column(
                                  children: [
                                    const SizedBox(height: 24),

                                    // Note
                                    FTextField.multiline(
                                      control: FTextFieldControl.managed(controller: _noteController),
                                      label: Text(l10n.orderNoteOptional),
                                      hint: l10n.anySpecialRequests,
                                    ),
                                    const SizedBox(height: 16),

                                    // Points redemption
                                    _buildPointsRedemption(cart.totalPrice, colors),
                                    const SizedBox(height: 16),

                                    // Total
                                    _buildTotalSection(cart.totalPrice, colors),
                                    const SizedBox(height: 16),

                                    // Checkout button
                                    SafeArea(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: checkoutState.isLoading
                                              ? null
                                              : () => _handleCheckout(cart),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colors.primary,
                                            foregroundColor: colors.primaryForeground,
                                            disabledBackgroundColor: Colors.grey,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                            shape: const StadiumBorder(),
                                          ),
                                          child: checkoutState.isLoading
                                              ? SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    color: colors.primaryForeground,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : AppText(
                                                  l10n.placeOrder,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildPointsRedemption(double orderTotal, dynamic colors) {
    final l10n = AppLocalizations.of(context)!;
    final loyaltyState = ref.watch(loyaltyProvider);
    final loyaltyInfo = loyaltyState.loyaltyInfo;

    // Don't show if no loyalty account or no points
    if (loyaltyInfo == null || loyaltyInfo.pointsBalance <= 0) {
      return const SizedBox.shrink();
    }

    final numberFormat = NumberFormat('#,###');
    final maxRedeemable = ref.read(loyaltyProvider.notifier).getMaxRedeemablePoints(orderTotal);
    final discount = LoyaltyNotifier.pointsToDiscount(_pointsToRedeem);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Icon(FIcons.gift, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  l10n.useLoyaltyPoints,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              AppText(
                '${numberFormat.format(loyaltyInfo.pointsBalance)} ${l10n.pts}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(width: 8),
              FSwitch(
                value: _usePoints,
                onChange: maxRedeemable > 0
                    ? (value) {
                        setState(() {
                          _usePoints = value;
                          if (value) {
                            _pointsToRedeem = maxRedeemable;
                          } else {
                            _pointsToRedeem = 0;
                          }
                        });
                      }
                    : null,
              ),
            ],
          ),

          // Points slider when enabled
          if (_usePoints && maxRedeemable > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.border,
                        thumbColor: colors.primary,
                      ),
                      child: Slider(
                        value: _pointsToRedeem.toDouble(),
                        min: 0,
                        max: maxRedeemable.toDouble(),
                        divisions: maxRedeemable > 0 ? (maxRedeemable / 10).ceil() : 1,
                        onChanged: (value) {
                          setState(() {
                            _pointsToRedeem = value.round();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  '${numberFormat.format(_pointsToRedeem)} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                AppText(
                  '-£${discount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSection(double orderTotal, dynamic colors) {
    final l10n = AppLocalizations.of(context)!;
    final discount = LoyaltyNotifier.pointsToDiscount(_pointsToRedeem);
    final finalTotal = orderTotal - discount;

    return Column(
      children: [
        // Subtotal if discount applied
        if (_pointsToRedeem > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                l10n.subtotal,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              AppText(
                '£${orderTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                l10n.pointsDiscount,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.successColor,
                ),
              ),
              AppText(
                '-£${discount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              l10n.total,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppText(
              '£${finalTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.shoppingCart,
            size: 80,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          AppText(
            l10n.yourCartIsEmpty,
            style: TextStyle(
              fontSize: 18,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            l10n.addItemsFromMenu,
            style: TextStyle(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style.call,
        animation: animation,
        title: Text(l10n.clearCart),
        body: Text(l10n.removeAllItemsFromCart),
        direction: Axis.horizontal,
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(Cart cart) async {
    final l10n = AppLocalizations.of(context)!;
    final note = _noteController.text.isNotEmpty ? _noteController.text : null;

    // Get active room session's room name (if any)
    String? roomName;
    final sessionsState = ref.read(mySessionsProvider);
    sessionsState.whenData((sessions) {
      final activeSession = sessions.where((s) => s.status == SessionStatus.active).firstOrNull;
      if (activeSession != null) {
        roomName = activeSession.roomName.en;
      }
    });

    final success = await ref.read(checkoutProvider.notifier).submitOrder(
          items: cart.items,
          roomName: roomName,
          customerNote: note,
          pointsToRedeem: _pointsToRedeem,
        );

    if (success && mounted) {
      _noteController.clear();
      setState(() {
        _pointsToRedeem = 0;
        _usePoints = false;
      });

      // Refresh loyalty info to show updated balance after order is confirmed
      ref.read(loyaltyProvider.notifier).refresh();

      // Navigate to orders page and show success toast
      context.go('/orders');
      showFToast(
        context: context,
        title: Text(l10n.orderPlacedSuccessfully),
        icon: Icon(FIcons.check, color: AppTheme.successColor),
      );
    } else if (mounted) {
      final error = ref.read(checkoutProvider).error;
      showFToast(
        context: context,
        title: Text(error ?? l10n.failedToPlaceOrder),
        icon: Icon(FIcons.circleX, color: AppTheme.errorColor),
      );
    }
  }
}

/// Cart item tile with image
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
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.pictureUri != null
                ? Image.network(
                    item.pictureUri!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 64,
                      color: colors.muted,
                      child: Icon(
                        FIcons.image,
                        color: colors.mutedForeground,
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: colors.muted,
                    child: Icon(
                      FIcons.coffee,
                      color: colors.mutedForeground,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Item info and controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and remove button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppText(
                        item.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(cartProvider.notifier).removeItem(index),
                      child: Icon(FIcons.x, size: 18, color: colors.mutedForeground),
                    ),
                  ],
                ),
                if (item.selectedCustomizations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText(
                    item.selectedCustomizations
                        .map((c) => c.optionName)
                        .join(', '),
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (item.specialInstructions != null) ...[
                  const SizedBox(height: 4),
                  AppText(
                    AppLocalizations.of(context)!.noteWithText(item.specialInstructions!),
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Quantity controls and price on same row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: item.quantity > 1
                              ? () => ref.read(cartProvider.notifier).updateQuantity(index, item.quantity - 1)
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              FIcons.minus,
                              size: 14,
                              color: item.quantity > 1 ? colors.foreground : colors.mutedForeground,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AppText(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(index, item.quantity + 1),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(FIcons.plus, size: 14, color: colors.foreground),
                          ),
                        ),
                      ],
                    ),

                    // Price
                    AppText(
                      '£${item.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
