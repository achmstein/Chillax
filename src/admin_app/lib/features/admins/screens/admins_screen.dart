import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/admin_user.dart';
import '../providers/admins_provider.dart';
import '../widgets/add_admin_sheet.dart';

/// Admins management screen
class AdminsScreen extends ConsumerStatefulWidget {
  const AdminsScreen({super.key});

  @override
  ConsumerState<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends ConsumerState<AdminsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminsProvider.notifier).loadAdmins();
    });
    _searchController.addListener(_onSearchChanged);

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/admins' && previous != '/admins' && previous != null) {
        ref.read(adminsProvider.notifier).loadAdmins();
      }
    });
  }

  void _onSearchChanged() {
    ref.read(adminsProvider.notifier).setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAdminSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const AddAdminSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminsProvider);
    final notifier = ref.read(adminsProvider.notifier);
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 8),
          child: Row(
            children: [
              AppText(
                l10n.adminsManagement,
                style: theme.typography.lg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (state.totalCount > 0) ...[
                const SizedBox(width: 8),
                AppText(
                  '${state.totalCount}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 22),
                onPressed: _showAddAdminSheet,
                tooltip: l10n.addAdmin,
              ),
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
            isLoading: state.isLoading && state.admins.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: state.admins.isEmpty
                ? EmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    title: l10n.noAdminsFound,
                  )
                : RefreshIndicator(
                    color: theme.colors.primary,
                    backgroundColor: theme.colors.background,
                    onRefresh: () => notifier.loadAdmins(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.admins.length,
                      itemBuilder: (context, index) {
                        final admin = state.admins[index];
                        return GestureDetector(
                          onTap: () => context.push('/admins/${admin.id}'),
                          behavior: HitTestBehavior.opaque,
                          child: _AdminTile(admin: admin, l10n: l10n),
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

/// Admin tile widget
class _AdminTile extends StatelessWidget {
  final AdminUser admin;
  final AppLocalizations l10n;

  const _AdminTile({required this.admin, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
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
                admin.initials,
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
                  admin.displayName,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (admin.email != null) ...[
                  const SizedBox(height: 2),
                  AppText(
                    admin.email!,
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Status indicator
          if (!admin.enabled) ...[
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
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
