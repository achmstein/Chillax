import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shimmer/shimmer.dart';

/// Standard screen padding for all screens
const kScreenPadding = EdgeInsets.all(16);

/// Shimmer loading list - replaces FProgress/CircularProgressIndicator for list loading states
class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool showLeadingCircle;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
    this.showLeadingCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final baseColor = theme.colors.secondary;
    final highlightColor = theme.colors.background;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: kScreenPadding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => ShimmerListTile(
          height: itemHeight,
          showLeadingCircle: showLeadingCircle,
        ),
      ),
    );
  }
}

/// Individual shimmer placeholder tile
class ShimmerListTile extends StatelessWidget {
  final double height;
  final bool showLeadingCircle;

  const ShimmerListTile({
    super.key,
    this.height = 72,
    this.showLeadingCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (showLeadingCircle) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized empty state widget
/// - Icon: 48px
/// - Title: typography.base
/// - Subtitle: typography.sm
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.typography.base.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent section header with optional count badge and action
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Text(
          title,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.typography.xs.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const Spacer(),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText!,
              style: theme.typography.sm.copyWith(color: theme.colors.primary),
            ),
          ),
      ],
    );
  }
}
