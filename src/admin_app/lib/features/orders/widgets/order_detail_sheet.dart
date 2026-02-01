import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrderDetailSheet extends ConsumerWidget {
  final Order order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final currencyFormat = NumberFormat.currency(symbol: '£', decimalDigits: 0);
    final dateFormat = DateFormat.yMd(locale.languageCode).add_Hm();

    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  l10n.orderNumber(order.id),
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  child: const Icon(Icons.close),
                  onPress: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const FDivider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and info
                  Row(
                    children: [
                      _buildStatusBadge(order.status, l10n),
                      if (order.roomName != null) ...[
                        const SizedBox(width: 8),
                        FBadge(style: FBadgeStyle.secondary(),
                          child: AppText(order.roomName!.localized(context)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

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
                  ...order.items.map((item) => _buildOrderItem(context, theme, item, currencyFormat, l10n)),

                  const SizedBox(height: 16),
                  const FDivider(),
                  const SizedBox(height: 16),

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
                        currencyFormat.format(order.total),
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
            const FDivider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
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
        return FBadge(style: FBadgeStyle.secondary(),
          child: AppText(l10n.validating),
        );
      case OrderStatus.submitted:
        return FBadge(style: FBadgeStyle.destructive(),
          child: AppText(l10n.pending),
        );
      case OrderStatus.confirmed:
        return FBadge(
          child: AppText(l10n.confirmed),
        );
      case OrderStatus.cancelled:
        return FBadge(style: FBadgeStyle.outline(),
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

  Widget _buildOrderItem(BuildContext context, FThemeData theme, OrderItem item, NumberFormat format, AppLocalizations l10n) {
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
                  '${format.format(item.unitPrice)} ${l10n.each}',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          AppText(
            format.format(item.totalPrice),
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    await ref.read(ordersProvider.notifier).confirmOrder(order.id);
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
            style: FButtonStyle.outline(),
            child: AppText(l10n.noKeep),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.yesCancel),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
