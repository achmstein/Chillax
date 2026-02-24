import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/localized_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/room.dart';
import '../providers/rooms_provider.dart';

/// Sheet for creating or editing rooms
class RoomFormSheet extends ConsumerStatefulWidget {
  final Room? room;

  const RoomFormSheet({super.key, this.room});

  bool get isEditing => room != null;

  @override
  ConsumerState<RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends ConsumerState<RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _hourlyRateController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.room?.name.en ?? '');
    _nameArController = TextEditingController(text: widget.room?.name.ar ?? '');
    _descriptionEnController =
        TextEditingController(text: widget.room?.description?.en ?? '');
    _descriptionArController =
        TextEditingController(text: widget.room?.description?.ar ?? '');
    _hourlyRateController = TextEditingController(
        text: widget.room?.hourlyRate.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      widget.isEditing ? l10n.editRoom : l10n.addRoom,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field (bilingual)
                      LocalizedTextField(
                        label: l10n.name,
                        isRequired: true,
                        enController: _nameEnController,
                        arController: _nameArController,
                        enHint: 'e.g. PlayStation Room 1',
                        arHint: 'مثال: غرفة بلايستيشن ١',
                      ),
                      const SizedBox(height: 16),

                      // Description field (bilingual)
                      LocalizedTextField(
                        label: l10n.description,
                        enController: _descriptionEnController,
                        arController: _descriptionArController,
                        enHint: 'Optional description',
                        arHint: 'وصف اختياري',
                        isMultiline: true,
                        maxLines: 4,
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: () => Navigator.of(context).pop(),
                      child: AppText(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : AppText(widget.isEditing ? l10n.update : l10n.create),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameEnController.text.trim().isEmpty) {
      return;
    }

    final hourlyRate = double.tryParse(_hourlyRateController.text);
    if (hourlyRate == null || hourlyRate <= 0) {
      return;
    }

    setState(() => _isSubmitting = true);

    final room = Room(
      id: widget.room?.id ?? 0,
      name: LocalizedTextControllers.getValue(_nameEnController, _nameArController),
      description: LocalizedTextControllers.getValueOrNull(
          _descriptionEnController, _descriptionArController),
      status: widget.room?.status ?? RoomStatus.available,
      hourlyRate: hourlyRate,
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
