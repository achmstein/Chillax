import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';

/// Customer detail sheet
class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Container(
      width: 400,
      color: theme.colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Details',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    // Profile section
                    Center(
                      child: Column(
                        children: [
                          FAvatar(
                            fallback: Text(customer.initials),
                            size: 80,
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
        ),
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
