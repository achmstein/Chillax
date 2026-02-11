import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_detail_sheet.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(orderHistoryProvider.notifier).loadOrderHistory();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(orderHistoryProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(orderHistoryProvider.notifier).loadOrderHistory(loadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderHistoryProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(FIcons.arrowLeft, size: 22),
                ),
              ),
              const SizedBox(width: 4),
              AppText(
                l10n.orderHistory,
                style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.orders.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: RefreshIndicator(
              onRefresh: () => ref.read(orderHistoryProvider.notifier).loadOrderHistory(),
              child: state.orders.isEmpty && !state.isLoading
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.noOrdersFound,
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.orders.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.colors.border,
                      ),
                      itemBuilder: (context, index) {
                        if (index == state.orders.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final order = state.orders[index];
                        return _HistoryOrderTile(order: order);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryOrderTile extends StatelessWidget {
  final Order order;

  const _HistoryOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMd(locale.languageCode).add_Hm();

    return GestureDetector(
      onTap: () => _showOrderDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Order number badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AppText(
                  '#${order.id}',
                  style: theme.typography.xs.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          order.userName ?? l10n.orderNumber(order.id),
                          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(order.status, l10n),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          dateFormat.format(order.date),
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                      if (order.roomName != null) ...[
                        AppText(
                          order.roomName!.localized(context),
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      AppText(
                        l10n.priceFormat(order.total.toStringAsFixed(0)),
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (order.pointsToRedeem > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.stars, size: 12, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        AppText(
                          '-${l10n.priceFormat(order.loyaltyDiscount.toStringAsFixed(0))}',
                          style: theme.typography.xs.copyWith(
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(FIcons.chevronRight, size: 16, color: theme.colors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatus.awaitingValidation:
        return FBadge(
          style: FBadgeStyle.secondary(),
          child: AppText(l10n.validating),
        );
      case OrderStatus.submitted:
        return FBadge(
          style: FBadgeStyle.destructive(),
          child: AppText(l10n.pending),
        );
      case OrderStatus.confirmed:
        return FBadge(child: AppText(l10n.confirmed));
      case OrderStatus.cancelled:
        return FBadge(
          style: FBadgeStyle.outline(),
          child: AppText(l10n.cancelled),
        );
    }
  }

  void _showOrderDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: context.theme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: OrderDetailSheet(order: order),
      ),
    );
  }
}
