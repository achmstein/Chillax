import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/rating_widget.dart';

/// Orders history screen with infinite scroll
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    // Auto-refresh if there are pending orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIfPendingOrders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app resumes if there are pending orders
    if (state == AppLifecycleState.resumed) {
      _refreshIfPendingOrders();
    }
  }

  void _refreshIfPendingOrders() {
    final ordersState = ref.read(ordersProvider);
    final hasPendingOrders = ordersState.orders.any(
      (order) => order.status == OrderStatus.submitted,
    );
    if (hasPendingOrders) {
      ref.read(ordersProvider.notifier).refresh();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header
        FHeader(
          title: AppText(l10n.orders, style: TextStyle(fontSize: 18)),
        ),

        // Body
        Expanded(
          child: _buildBody(ordersState),
        ),
      ],
    );
  }

  Widget _buildBody(OrdersState state) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context)!;

    // Initial loading
    if (state.isLoading && state.orders.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    // Error state
    if (state.error != null && state.orders.isEmpty) {
      return RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.background,
        onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FIcons.circleAlert, size: 48, color: colors.mutedForeground),
                    const SizedBox(height: 16),
                    AppText(l10n.failedToLoadOrders, style: TextStyle(color: colors.foreground)),
                    const SizedBox(height: 8),
                    AppText(
                      l10n.pullDownToRetry,
                      style: TextStyle(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (state.orders.isEmpty) {
      return RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.background,
        onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(colors),
            ),
          ],
        ),
      );
    }

    // Orders list with infinite scroll
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.background,
      onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, _) => Divider(height: 1, color: context.theme.colors.border),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index == state.orders.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ),
            );
          }
          return OrderTile(order: state.orders[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.receipt,
            size: 80,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          AppText(
            l10n.noOrdersYet,
            style: TextStyle(
              fontSize: 18,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            l10n.orderHistoryWillAppearHere,
            style: TextStyle(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order tile - minimalistic expandable with lazy loading of details
class OrderTile extends ConsumerStatefulWidget {
  final Order order;

  const OrderTile({super.key, required this.order});

  @override
  ConsumerState<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends ConsumerState<OrderTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.order.status == OrderStatus.submitted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OrderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.status == OrderStatus.submitted) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final locale = ref.watch(localeProvider);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a', locale.languageCode);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - tappable to expand
        FTappable(
          onPress: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusDot(widget.order.status),
                          const SizedBox(width: 8),
                          AppText(
                            l10n.orderNumber(widget.order.id.toString()),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.foreground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppText(
                            dateFormat.format(widget.order.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.mutedForeground,
                            ),
                          ),
                          if (widget.order.roomName != null) ...[
                            const SizedBox(width: 8),
                            AppText(
                              '• ${widget.order.roomName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AppText(
                  l10n.priceFormat(widget.order.total.toStringAsFixed(2)),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.foreground),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded ? FIcons.chevronUp : FIcons.chevronDown,
                  size: 16,
                  color: colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),

        // Expanded content - fetch details when expanded
        if (_expanded) ...[
          _buildExpandedContent(),
        ],
      ],
    );
  }

  Widget _buildExpandedContent() {
    final colors = context.theme.colors;
    final orderDetailsAsync = ref.watch(orderProvider(widget.order.id));
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: orderDetailsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
        error: (error, _) => AppText(
          l10n.failedToLoadDetails,
          style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
        ),
        data: (orderDetails) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order items
            if (orderDetails.items.isNotEmpty) ...[
              ...orderDetails.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              '${item.units}x ',
                              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                            ),
                            Expanded(child: AppText(item.productName.getText(locale), style: TextStyle(fontSize: 14, color: colors.foreground))),
                            AppText(
                              l10n.priceFormat(item.totalPrice.toStringAsFixed(2)),
                              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                            ),
                          ],
                        ),
                        // Customizations
                        if (item.customizationsDescription != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 2),
                            child: AppText(
                              item.customizationsDescription!.getText(locale),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                        // Special instructions
                        if (item.specialInstructions != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 2),
                            child: AppText(
                              '"${item.specialInstructions}"',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
            ] else ...[
              AppText(
                l10n.noItems,
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              ),
            ],

            // Customer note
            if (orderDetails.customerNote != null) ...[
              const SizedBox(height: 8),
              AppText(
                l10n.noteWithText(orderDetails.customerNote!),
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ],

            // Rating section
            if (orderDetails.hasRating) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  AppText(
                    l10n.yourRating,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                  RatingDisplay(rating: orderDetails.rating!, color: colors.mutedForeground),
                ],
              ),
              if (orderDetails.rating!.comment != null && orderDetails.rating!.comment!.isNotEmpty) ...[
                const SizedBox(height: 4),
                AppText(
                  '"${orderDetails.rating!.comment}"',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ] else if (orderDetails.canBeRated) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showRatingDialog(
                      context: context,
                      ref: ref,
                      orderId: orderDetails.id,
                    );
                  },
                  icon: const Icon(Icons.star_border, size: 18),
                  label: Text(l10n.rateThisOrder),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(OrderStatus status) {
    final color = switch (status) {
      OrderStatus.awaitingValidation => Colors.blue,
      OrderStatus.submitted => Colors.orange,
      OrderStatus.confirmed => AppTheme.successColor,
      OrderStatus.cancelled => AppTheme.errorColor,
    };

    // Pulse animation for submitted orders
    if (status == OrderStatus.submitted) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _pulseAnimation.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: _pulseAnimation.value * 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
