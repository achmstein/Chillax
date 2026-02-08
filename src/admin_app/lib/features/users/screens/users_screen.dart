import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/widgets/admin_scaffold.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/ui_components.dart';
import '../../../l10n/app_localizations.dart';
import '../models/admin_user.dart';
import '../providers/users_provider.dart';
import '../widgets/add_admin_sheet.dart';

/// Users management screen - matches customers screen design
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
    });
    _searchController.addListener(_onSearchChanged);

    // Listen to route changes and refresh when navigating to this screen
    ref.listenManual(currentRouteProvider, (previous, next) {
      if (next == '/users' && previous != '/users' && previous != null) {
        ref.read(usersProvider.notifier).loadUsers();
      }
    });
  }

  void _onSearchChanged() {
    ref.read(usersProvider.notifier).setSearchQuery(_searchController.text);
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
    final state = ref.watch(usersProvider);
    final notifier = ref.read(usersProvider.notifier);
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
                l10n.usersManagement,
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
            isLoading: state.isLoading && state.users.isEmpty,
            shimmer: const ShimmerLoadingList(),
            child: state.users.isEmpty
                ? EmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    title: l10n.noUsersFound,
                  )
                : RefreshIndicator(
                    onRefresh: () => notifier.loadUsers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return _UserTile(user: user, l10n: l10n);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// User tile widget - matches customer tile design
class _UserTile extends StatelessWidget {
  final AdminUser user;
  final AppLocalizations l10n;

  const _UserTile({required this.user, required this.l10n});

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
                user.initials,
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
                  user.displayName,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 2),
                  AppText(
                    user.email!,
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Status indicator
          if (!user.enabled)
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
    );
  }
}
