import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// Displays a session access code with copy-to-clipboard functionality
class AccessCodeDisplay extends StatelessWidget {
  final String code;
  final bool compact;

  const AccessCodeDisplay({
    super.key,
    required this.code,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FTappable(
      onPress: () => _copyToClipboard(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.key,
              size: compact ? 14 : 16,
              color: theme.colors.primary,
            ),
            SizedBox(width: compact ? 6 : 8),
            Text(
              code,
              style: (compact ? theme.typography.sm : theme.typography.base).copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            Icon(
              Icons.copy,
              size: compact ? 14 : 16,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    showFToast(
      context: context,
      title: const Text('Access code copied!'),
    );
  }
}
