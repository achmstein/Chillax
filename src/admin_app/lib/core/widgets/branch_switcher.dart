import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../models/branch.dart';
import '../models/localized_text.dart';
import '../providers/branch_provider.dart';
import '../../l10n/app_localizations.dart';
import 'app_text.dart';
import 'toast_helpers.dart';

/// Branch switcher chip for the admin app bar
class BranchSwitcher extends ConsumerWidget {
  const BranchSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    final selectedBranch = branchState.selectedBranch;
    if (selectedBranch == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, top: 8),
      child: Row(
        children: [
          // Branch name (+ picker if multiple)
          GestureDetector(
            onTap: branchState.branches.length > 1
                ? () => _showBranchPicker(context, ref, branchState.branches, selectedBranch)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FIcons.mapPin, size: 14, color: theme.colors.foreground),
                const SizedBox(width: 4),
                AppText(
                  selectedBranch.name.localized(context),
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (branchState.branches.length > 1) ...[
                  const SizedBox(width: 2),
                  Icon(FIcons.chevronDown, size: 18, color: theme.colors.mutedForeground),
                ],
              ],
            ),
          ),
          const Spacer(),
          // Quick toggles
          _SettingToggle(
            icon: FIcons.shoppingCart,
            isEnabled: selectedBranch.isOrderingEnabled,
            tooltip: selectedBranch.isOrderingEnabled ? l10n.orderingEnabled : l10n.orderingDisabled,
            onTap: () => _toggleOrdering(context, ref, selectedBranch),
          ),
          const SizedBox(width: 8),
          _SettingToggle(
            icon: FIcons.gamepad2,
            isEnabled: selectedBranch.isReservationsEnabled,
            tooltip: selectedBranch.isReservationsEnabled ? l10n.reservationsEnabled : l10n.reservationsDisabled,
            onTap: () => _toggleReservations(context, ref, selectedBranch),
          ),
        ],
      ),
    );
  }

  void _toggleOrdering(BuildContext context, WidgetRef ref, Branch branch) async {
    final l10n = AppLocalizations.of(context)!;
    final newValue = !branch.isOrderingEnabled;
    final success = await ref.read(branchProvider.notifier).updateBranchSettings(
      branch.id,
      {'isOrderingEnabled': newValue},
    );
    if (context.mounted && success) {
      showSuccessToast(context, newValue ? l10n.orderingEnabled : l10n.orderingDisabled);
    }
  }

  void _toggleReservations(BuildContext context, WidgetRef ref, Branch branch) async {
    final l10n = AppLocalizations.of(context)!;
    final newValue = !branch.isReservationsEnabled;
    final success = await ref.read(branchProvider.notifier).updateBranchSettings(
      branch.id,
      {'isReservationsEnabled': newValue},
    );
    if (context.mounted && success) {
      showSuccessToast(context, newValue ? l10n.reservationsEnabled : l10n.reservationsDisabled);
    }
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
                    ? Icon(Icons.check, size: 16, color: theme.colors.primary)
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

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final String tooltip;
  final VoidCallback onTap;

  const _SettingToggle({
    required this.icon,
    required this.isEnabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = isEnabled ? Colors.green : theme.colors.mutedForeground;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.green.withValues(alpha: 0.1)
                : theme.colors.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
