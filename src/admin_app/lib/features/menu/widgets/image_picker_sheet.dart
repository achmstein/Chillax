import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet for picking an image from camera or gallery
class ImagePickerSheet extends StatelessWidget {
  final bool hasExistingImage;

  const ImagePickerSheet({
    super.key,
    this.hasExistingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Take photo option
            _ImageOptionTile(
              icon: Icons.camera_alt_outlined,
              label: l10n.takePhoto,
              onTap: () async {
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 85,
                );
                if (file != null && context.mounted) {
                  Navigator.of(context).pop(File(file.path));
                }
              },
            ),

            const SizedBox(height: 8),

            // Choose from gallery option
            _ImageOptionTile(
              icon: Icons.photo_library_outlined,
              label: l10n.chooseFromGallery,
              onTap: () async {
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 85,
                );
                if (file != null && context.mounted) {
                  Navigator.of(context).pop(File(file.path));
                }
              },
            ),

            if (hasExistingImage) ...[
              const SizedBox(height: 8),
              const FDivider(),
              const SizedBox(height: 8),

              // Remove image option
              _ImageOptionTile(
                icon: Icons.delete_outline,
                label: l10n.removeImage,
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop('remove');
                },
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ImageOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ImageOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = isDestructive ? theme.colors.destructive : theme.colors.foreground;

    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            AppText(
              label,
              style: theme.typography.base.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the image picker sheet and returns the selected file or 'remove' string
Future<dynamic> showImagePickerSheet(BuildContext context, {bool hasExistingImage = false}) {
  return showModalBottomSheet<dynamic>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => ImagePickerSheet(hasExistingImage: hasExistingImage),
  );
}
