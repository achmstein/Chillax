import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customersProvider.notifier).loadCustomers();
    });
    _searchController.addListener(_onSearchChanged);

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/customers' && previous != '/customers' && previous != null) {
        ref.read(customersProvider.notifier).loadCustomers();
      }
    });
  }

  void _onSearchChanged() {
    ref.read(customersProvider.notifier).setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final notifier = ref.read(customersProvider.notifier);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AppText(l10n.customers, style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              if (state.totalCount > 0) ...[
                const SizedBox(width: 8),
                AppText(
                  '${state.totalCount}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FTextField(
            control: FTextFieldControl.managed(controller: _searchController),
            hint: l10n.searchByNameOrEmail,
          ),
        ),

        const SizedBox(height: 8),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.customers.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: state.customers.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noCustomersFound,
                  )
                : RefreshIndicator(
                    onRefresh: () => notifier.loadCustomers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.customers.length,
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        return _CustomerTile(
                          customer: customer,
                          onTap: () => context.go('/customers/${customer.id}'),
                          l10n: l10n,
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _CustomerTile({required this.customer, required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: AppText(
                  customer.initials,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    customer.displayName,
                    style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customer.email != null) ...[
                    const SizedBox(height: 2),
                    AppText(
                      customer.email!,
                      style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Status indicator
            if (!customer.enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AppText(
                  l10n.disabled,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
