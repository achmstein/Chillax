import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';
import 'customer_detail_screen.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final theme = context.theme;
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FHeader(
          title: const Text('Customers'),
          suffixes: [
            FHeaderAction(
              icon: const Icon(Icons.refresh),
              onPress: () {
                ref.read(customersProvider.notifier).loadCustomers();
              },
            ),
          ],
        ),
        const FDivider(),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(controller: _searchController),
                  hint: 'Search customers...',
                  onSubmit: (_) {
                    ref
                        .read(customersProvider.notifier)
                        .setSearchQuery(_searchController.text);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () {
                  ref
                      .read(customersProvider.notifier)
                      .setSearchQuery(_searchController.text);
                },
                child: const Text('Search'),
              ),
              if (state.searchQuery != null && state.searchQuery!.isNotEmpty) ...[
                const SizedBox(width: 8),
                FButton(
                  style: FButtonStyle.outline(),
                  onPress: () {
                    _searchController.clear();
                    ref.read(customersProvider.notifier).setSearchQuery(null);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${state.totalCount} total customers',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Error
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FAlert(
              style: FAlertStyle.destructive(),
              icon: const Icon(Icons.warning),
              title: const Text('Error'),
              subtitle: Text(state.error!),
            ),
          ),

        // Content
        Expanded(
          child: state.isLoading && state.customers.isEmpty
              ? const Center(child: FProgress())
              : state.customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.searchQuery != null
                                ? 'No customers found'
                                : 'No customers yet',
                            style: theme.typography.lg.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.customers.length,
                      separatorBuilder: (_, __) => const FDivider(),
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        return _CustomerListItem(
                          customer: customer,
                          dateFormat: dateFormat,
                          onTap: () => _showCustomerDetail(context, customer),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showCustomerDetail(BuildContext context, Customer customer) {
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (context) => CustomerDetailScreen(customer: customer),
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  final Customer customer;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _CustomerListItem({
    required this.customer,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FTappable(
      onPress: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            FAvatar.raw(
              size: 48,
              child: Text(customer.initials),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.displayName,
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!customer.enabled)
                        FBadge(
                          style: FBadgeStyle.outline(),
                          child: const Text('Disabled'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (customer.email != null)
                    Text(
                      customer.email!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  if (customer.createdAt != null)
                    Text(
                      'Joined ${dateFormat.format(customer.createdAt!)}',
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
