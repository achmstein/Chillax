import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrderDetailSheet extends ConsumerStatefulWidget {
  final Order order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  ConsumerState<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<OrderDetailSheet> {
  Order? _fullOrder;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadFullOrder();
  }

  Future<void> _loadFullOrder() async {
    if (widget.order.items.isNotEmpty) {
      _fullOrder = widget.order;
      return;
    }
    setState(() => _isLoadingDetails = true);
    try {
      final detailedOrder = await ref.read(orderDetailsProvider(widget.order.id).future);
      if (mounted) {
        setState(() {
          _fullOrder = detailedOrder;
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _fullOrder ?? widget.order;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMd(locale.languageCode).add_Hm();

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    l10n.orderNumber(order.id),
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  _buildStatusBadge(order.status, l10n),

                  // Rating
                  if (order.rating != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          i < order.rating!.ratingValue ? Icons.star : Icons.star_border,
                          size: 22,
                          color: i < order.rating!.ratingValue ? Colors.amber : theme.colors.mutedForeground,
                        ),
                      )),
                    ),
                    if (order.rating!.comment != null && order.rating!.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                size: 16,
                                color: theme.colors.mutedForeground,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppText(
                                  order.rating!.comment!,
                                  style: theme.typography.sm.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),

                  // Customer name
                  if (order.userName != null && order.userName!.isNotEmpty)
                    _buildInfoRow(theme, l10n.customer, order.userName!),

                  // Room name
                  if (order.roomName != null)
                    _buildInfoRow(theme, l10n.room, order.roomName!.localized(context)),

                  // Date
                  _buildInfoRow(theme, l10n.date, dateFormat.format(order.date)),

                  // Customer note
                  if (order.customerNote != null && order.customerNote!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AppText(
                      l10n.customerNote,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.message,
                              size: 16,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppText(
                                order.customerNote!,
                                style: theme.typography.sm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Order items
                  AppText(
                    l10n.items,
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingDetails)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (order.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: AppText(
                        '-',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    )
                  else
                    ...order.items.map((item) => _buildOrderItem(context, theme, item, l10n)),

                  const SizedBox(height: 16),
                  const FDivider(),
                  const SizedBox(height: 16),

                  // Subtotal + Loyalty Discount + Total
                  if (order.pointsToRedeem > 0) ...(() {
                    final subtotal = order.total;
                    final discount = order.loyaltyDiscount;
                    final total = subtotal - discount;
                    return [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          l10n.subtotal,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        AppText(
                          l10n.priceFormat(subtotal.toStringAsFixed(2)),
                          style: theme.typography.sm,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            AppText(
                              l10n.loyaltyDiscount,
                              style: theme.typography.sm.copyWith(
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                        AppText(
                          '-${l10n.priceFormat(discount.toStringAsFixed(2))}',
                          style: theme.typography.sm.copyWith(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                  // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          l10n.total,
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppText(
                          l10n.priceFormat(total.toStringAsFixed(2)),
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colors.primary,
                          ),
                        ),
                      ],
                    ),
                    ];
                  })() else

                  // Total (no discount)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        l10n.total,
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppText(
                        l10n.priceFormat(order.total.toStringAsFixed(2)),
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          if (order.status == OrderStatus.submitted) ...[
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      child: AppText(l10n.cancelOrder),
                      onPress: () => _cancelOrder(context, ref, l10n),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      child: AppText(l10n.confirmOrder),
                      onPress: () => _confirmOrder(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatus.awaitingValidation:
        return FBadge(variant: FBadgeVariant.secondary,
          child: AppText(l10n.validating),
        );
      case OrderStatus.submitted:
        return FBadge(variant: FBadgeVariant.destructive,
          child: AppText(l10n.pending),
        );
      case OrderStatus.confirmed:
        return FBadge(
          child: AppText(l10n.confirmed),
        );
      case OrderStatus.cancelled:
        return FBadge(variant: FBadgeVariant.outline,
          child: AppText(l10n.cancelled),
        );
    }
  }

  Widget _buildInfoRow(FThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        AppText(
          value,
          style: theme.typography.sm,
        ),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, FThemeData theme, OrderItem item, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: AppText(
              '${item.units}x',
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.productName.localized(context),
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppText(
                  '${l10n.priceFormat(item.unitPrice.toStringAsFixed(0))} ${l10n.each}',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          AppText(
            l10n.priceFormat(item.totalPrice.toStringAsFixed(0)),
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    await ref.read(ordersProvider.notifier).confirmOrder(widget.order.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.cancelOrderQuestion),
        body: AppText(l10n.cancelOrderConfirmation),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            child: AppText(l10n.noKeep),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            child: AppText(l10n.yesCancel),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ordersProvider.notifier).cancelOrder(widget.order.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
