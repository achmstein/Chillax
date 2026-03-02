import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/services/branch_service.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../users/models/admin_user.dart';
import '../../users/services/users_service.dart';
import '../providers/branches_provider.dart';

class BranchDetailScreen extends ConsumerStatefulWidget {
  final int branchId;

  const BranchDetailScreen({super.key, required this.branchId});

  @override
  ConsumerState<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends ConsumerState<BranchDetailScreen> {
  List<AdminUser>? _allAdmins;
  List<AdminUser>? _assignedAdmins;
  bool _isLoadingAdmins = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoadingAdmins = true);
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final allAdmins = await usersRepo.getUsers(role: 'Admin', max: 100);

      // Get branches for each admin to find who's assigned to this branch
      final repo = ref.read(branchRepositoryProvider);
      final assignedAdmins = <AdminUser>[];

      for (final admin in allAdmins) {
        try {
          final adminBranches = await repo.getAdminBranches(admin.id);
          if (adminBranches.any((b) => b.id == widget.branchId)) {
            assignedAdmins.add(admin);
          }
        } catch (_) {
          // Skip if can't fetch branches for this admin
        }
      }

      if (mounted) {
        setState(() {
          _allAdmins = allAdmins;
          _assignedAdmins = assignedAdmins;
          _isLoadingAdmins = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdmins = false);
      }
    }
  }

  Branch? get _branch {
    final state = ref.watch(branchesManagementProvider);
    return state.branches.where((b) => b.id == widget.branchId).firstOrNull;
  }

  Future<void> _assignAdmin() async {
    if (_allAdmins == null) return;

    final assignedIds = _assignedAdmins?.map((a) => a.id).toSet() ?? {};
    final available = _allAdmins!.where((a) => !assignedIds.contains(a.id)).toList();

    if (available.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final theme = context.theme;

    final selected = await showModalBottomSheet<AdminUser>(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppText(
                  l10n.selectAdmin,
                  style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ...available.map((admin) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colors.secondary,
                    child: AppText(
                      admin.initials,
                      style: theme.typography.xs.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: AppText(
                    admin.displayName,
                    style: theme.typography.sm,
                  ),
                  subtitle: admin.email != null
                      ? AppText(
                          admin.email!,
                          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, admin),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null) {
      final success = await ref
          .read(branchesManagementProvider.notifier)
          .assignAdmin(widget.branchId, selected.id);
      if (success && mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminAssigned)),
        );
        _loadAdmins();
      }
    }
  }

  Future<void> _removeAdmin(AdminUser admin) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.removeAdmin),
        body: AppText(l10n.confirmRemoveAdmin),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            child: AppText(l10n.removeAdmin),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(branchesManagementProvider.notifier)
          .removeAdmin(widget.branchId, admin.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminRemoved)),
        );
        _loadAdmins();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final branch = _branch;

    if (branch == null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(FIcons.arrowLeft),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(FIcons.arrowLeft),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppText(
                  branch.name.localized(context),
                  style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(FIcons.pencil, size: 20),
                onPressed: () => context.push('/branches/${branch.id}/edit'),
                tooltip: l10n.editBranch,
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch info
                FTileGroup(
                  label: AppText(l10n.branchDetails),
                  children: [
                    FTile(
                      prefix: const Icon(FIcons.building),
                      title: AppText(l10n.branchName),
                      subtitle: AppText(branch.name.localized(context)),
                    ),
                    if (branch.address != null)
                      FTile(
                        prefix: const Icon(FIcons.mapPin),
                        title: AppText(l10n.branchAddress),
                        subtitle: AppText(branch.address!.localized(context)),
                      ),
                    if (branch.phone != null)
                      FTile(
                        prefix: const Icon(FIcons.phone),
                        title: AppText(l10n.branchPhone),
                        subtitle: AppText(branch.phone!),
                      ),
                    FTile(
                      prefix: Icon(
                        branch.isActive ? FIcons.circleCheck : FIcons.circleX,
                        color: branch.isActive ? Colors.green : theme.colors.mutedForeground,
                      ),
                      title: AppText(branch.isActive ? l10n.active : l10n.inactive),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Assigned admins
                Row(
                  children: [
                    AppText(
                      l10n.assignedAdmins,
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.person_add_outlined, size: 20),
                      onPressed: _assignAdmin,
                      tooltip: l10n.assignAdmin,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_isLoadingAdmins)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_assignedAdmins == null || _assignedAdmins!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: AppText(
                        l10n.noAdminsAssigned,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  )
                else
                  ...(_assignedAdmins!.map((admin) => _AdminTile(
                        admin: admin,
                        onRemove: () => _removeAdmin(admin),
                      ))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final AdminUser admin;
  final VoidCallback onRemove;

  const _AdminTile({required this.admin, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colors.secondary,
            child: AppText(
              admin.initials,
              style: theme.typography.xs.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  admin.displayName,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                ),
                if (admin.email != null)
                  AppText(
                    admin.email!,
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.person_remove_outlined,
              size: 18,
              color: theme.colors.destructive,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
