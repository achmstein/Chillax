import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/bundle_deal.dart';
import '../providers/bundle_deals_provider.dart';

/// Screen showing all bundle deals with toggle and CRUD
class BundleDealsScreen extends ConsumerWidget {
  const BundleDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(bundleDealsProvider);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AppText(
                    l10n.bundleDeals,
                    style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => context.go('/bundles/new'),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: state.isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.colors.primary))
                  : RefreshIndicator(
                      color: theme.colors.primary,
                      backgroundColor: theme.colors.background,
                      onRefresh: () => ref.read(bundleDealsProvider.notifier).loadBundles(),
                      child: state.bundles.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                Icon(Icons.local_offer_outlined, size: 48, color: theme.colors.mutedForeground),
                                const SizedBox(height: 16),
                                Center(
                                  child: AppText(
                                    l10n.noBundleDeals,
                                    style: theme.typography.base.copyWith(color: theme.colors.mutedForeground),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.bundles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final bundle = state.bundles[index];
                                return _BundleTile(bundle: bundle);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundleTile extends ConsumerWidget {
  final BundleDeal bundle;

  const _BundleTile({required this.bundle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.go('/bundles/${bundle.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colors.background,
          border: Border.all(color: theme.colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 48,
                child: bundle.pictureUri != null
                    ? CachedNetworkImage(
                        imageUrl: bundle.pictureUri!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colors.muted,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colors.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colors.muted,
                          child: Icon(Icons.local_offer_outlined, size: 20, color: theme.colors.mutedForeground),
                        ),
                      )
                    : Container(
                        color: theme.colors.muted,
                        child: Icon(Icons.local_offer_outlined, size: 20, color: theme.colors.mutedForeground),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    bundle.name.localized(context),
                    style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    '${l10n.priceFormat(bundle.bundlePrice.toStringAsFixed(2))} (${l10n.originalPrice}: ${l10n.priceFormat(bundle.originalPrice.toStringAsFixed(2))})',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${bundle.items.length} ${l10n.items.toLowerCase()}',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),
            FSwitch(
              value: bundle.isActive,
              onChange: (value) {
                ref.read(bundleDealsProvider.notifier).toggleActive(bundle.id, value);
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final confirmed = await showAdaptiveDialog<bool>(
                  context: context,
                  builder: (context) => FDialog(
                    direction: Axis.horizontal,
                    title: AppText(l10n.delete),
                    body: AppText(l10n.deleteBundleConfirm),
                    actions: [
                      FButton(
                        variant: FButtonVariant.outline,
                        child: AppText(l10n.cancel),
                        onPress: () => Navigator.of(context).pop(false),
                      ),
                      FButton(
                        variant: FButtonVariant.destructive,
                        child: AppText(l10n.delete),
                        onPress: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(bundleDealsProvider.notifier).deleteBundle(bundle.id);
                }
              },
              child: Icon(Icons.delete_outline, size: 20, color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
