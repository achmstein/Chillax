import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../models/branch.dart';
import '../models/localized_text.dart';
import '../providers/branch_provider.dart';
import 'app_text.dart';

/// Thin bar that shows the branch switcher chip, hidden when only one branch
class BranchSwitcherBar extends ConsumerWidget {
  const BranchSwitcherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);
    if (branchState.branches.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: const BranchSwitcher(),
    );
  }
}

/// Compact branch switcher chip for use in app bars
class BranchSwitcher extends ConsumerWidget {
  const BranchSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);
    final theme = context.theme;

    if (branchState.branches.length <= 1) {
      return const SizedBox.shrink();
    }

    final selectedBranch = branchState.selectedBranch;
    if (selectedBranch == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showBranchPicker(context, ref, branchState.branches, selectedBranch),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FIcons.mapPin, size: 14, color: theme.colors.secondaryForeground),
            const SizedBox(width: 4),
            AppText(
              selectedBranch.name.localized(context),
              style: theme.typography.xs.copyWith(
                color: theme.colors.secondaryForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(FIcons.chevronDown, size: 12, color: theme.colors.secondaryForeground),
          ],
        ),
      ),
    );
  }

  void _showBranchPicker(BuildContext context, WidgetRef ref, List<Branch> branches, Branch current) {
    final theme = context.theme;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: theme.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ...branches.map((branch) {
              final isSelected = branch.id == current.id;
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(
                  FIcons.mapPin,
                  size: 20,
                  color: isSelected ? theme.colors.primary : theme.colors.foreground,
                ),
                title: AppText(
                  branch.name.localized(context),
                  style: theme.typography.sm.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? theme.colors.primary : theme.colors.foreground,
                  ),
                ),
                trailing: isSelected
                    ? Icon(FIcons.check, size: 16, color: theme.colors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isSelected) {
                    ref.read(branchProvider.notifier).selectBranch(branch.id);
                  }
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
