import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/ui_components.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';

/// Full page screen showing customer details
class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customersProvider.notifier).loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final theme = context.theme;
    final dateFormat = DateFormat.yMMMd().add_jm();

    final customer =
        state.customers.where((c) => c.id == widget.customerId).firstOrNull;

    if (customer == null) {
      return Column(
        children: [
          _buildHeader(context, theme, null),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.person_off,
                    title: 'Customer not found',
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context, theme, customer),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: kScreenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section
                Center(
                  child: Column(
                    children: [
                      FAvatar.raw(
                        size: 80,
                        child: Text(customer.initials),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        customer.displayName,
                        style: theme.typography.xl.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer.email != null)
                        Text(
                          customer.email!,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (customer.enabled)
                            FBadge(child: const Text('Active'))
                          else
                            FBadge(
                              style: FBadgeStyle.outline(),
                              child: const Text('Disabled'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const FDivider(),
                const SizedBox(height: 24),

                // Details section
                Text(
                  'Account Information',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                _DetailRow(
                  label: 'User ID',
                  value: customer.id,
                ),
                if (customer.username != null)
                  _DetailRow(
                    label: 'Username',
                    value: customer.username!,
                  ),
                if (customer.firstName != null)
                  _DetailRow(
                    label: 'First Name',
                    value: customer.firstName!,
                  ),
                if (customer.lastName != null)
                  _DetailRow(
                    label: 'Last Name',
                    value: customer.lastName!,
                  ),
                if (customer.email != null)
                  _DetailRow(
                    label: 'Email',
                    value: customer.email!,
                  ),
                if (customer.createdAt != null)
                  _DetailRow(
                    label: 'Member Since',
                    value: dateFormat.format(customer.createdAt!),
                  ),

                const SizedBox(height: 24),
                const FDivider(),
                const SizedBox(height: 24),

                // Loyalty section placeholder
                Text(
                  'Loyalty Program',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loyalty program coming soon',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Orders section placeholder
                Text(
                  'Order History',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Order history coming soon',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, FThemeData theme, Customer? customer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/customers'),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            customer?.displayName ?? 'Customer Details',
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () =>
                ref.read(customersProvider.notifier).loadCustomers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
