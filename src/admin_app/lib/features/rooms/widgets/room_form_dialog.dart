import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../l10n/app_localizations.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';

/// Dialog for creating or editing rooms
class RoomFormDialog extends ConsumerStatefulWidget {
  final Room? room;

  const RoomFormDialog({super.key, this.room});

  bool get isEditing => room != null;

  @override
  ConsumerState<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _hourlyRateController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name.en ?? '');
    _descriptionController =
        TextEditingController(text: widget.room?.description?.en ?? '');
    _hourlyRateController = TextEditingController(
        text: widget.room?.hourlyRate.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return FDialog(
      direction: Axis.vertical,
      title: AppText(widget.isEditing ? l10n.editRoom : l10n.addRoom),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            AppText(
              l10n.nameRequired,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FTextField(
              control: FTextFieldControl.managed(controller: _nameController),
              hint: l10n.roomNameHint,
            ),
            const SizedBox(height: 16),

            // Description field
            AppText(
              l10n.description,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FTextField.multiline(
              control: FTextFieldControl.managed(controller: _descriptionController),
              hint: l10n.optionalDescription,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Hourly rate field
            AppText(
              l10n.hourlyRate,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FTextField(
              control: FTextFieldControl.managed(controller: _hourlyRateController),
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.of(context).pop(),
          child: AppText(l10n.cancel),
        ),
        FButton(
          onPress: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : AppText(widget.isEditing ? l10n.update : l10n.create),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final room = Room(
      id: widget.room?.id ?? 0,
      name: LocalizedText(
        en: _nameController.text.trim(),
        ar: widget.room?.name.ar,
      ),
      description: _descriptionController.text.trim().isNotEmpty
          ? LocalizedText(
              en: _descriptionController.text.trim(),
              ar: widget.room?.description?.ar,
            )
          : null,
      status: widget.room?.status ?? RoomStatus.available,
      hourlyRate: double.parse(_hourlyRateController.text),
      pictureUri: widget.room?.pictureUri,
    );

    bool success;
    if (widget.isEditing) {
      success = await ref.read(roomsProvider.notifier).updateRoom(room);
    } else {
      success = await ref.read(roomsProvider.notifier).createRoom(room);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
