import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/branches_provider.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(branchesManagementProvider.notifier).loadBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchesManagementProvider);
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
              AppText(
                l10n.branches,
                style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (state.branches.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppText(
                  '${state.branches.length}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => context.push('/branches/new'),
                tooltip: l10n.createBranch,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: DelayedShimmer(
            isLoading: state.isLoading && state.branches.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: state.branches.isEmpty
                ? EmptyState(
                    icon: Icons.store_outlined,
                    title: l10n.noBranchesFound,
                  )
                : RefreshIndicator(
                    color: theme.colors.primary,
                    backgroundColor: theme.colors.background,
                    onRefresh: () => ref.read(branchesManagementProvider.notifier).loadBranches(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.branches.length,
                      itemBuilder: (context, index) {
                        final branch = state.branches[index];
                        return _BranchTile(branch: branch, l10n: l10n);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _BranchTile extends StatelessWidget {
  final dynamic branch;
  final AppLocalizations l10n;

  const _BranchTile({required this.branch, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return InkWell(
      onTap: () => context.push('/branches/${branch.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.store_outlined,
                size: 20,
                color: theme.colors.secondaryForeground,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    (branch.name as LocalizedText).localized(context),
                    style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (branch.address != null) ...[
                    const SizedBox(height: 2),
                    AppText(
                      (branch.address as LocalizedText).localized(context),
                      style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Status
            if (!branch.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AppText(
                  l10n.inactive,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(FIcons.chevronRight, size: 16, color: theme.colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
