import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _hourlyRateController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.room?.description ?? '');
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

    return Container(
      width: 400,
      color: theme.colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEditing ? 'Edit Room' : 'Add Room',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const FDivider(),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      Text(
                        'Name *',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FTextField(
                        control: FTextFieldControl.managed(controller: _nameController),
                        hint: 'e.g. PlayStation Room 1',
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      Text(
                        'Description',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FTextField.multiline(
                        control: FTextFieldControl.managed(controller: _descriptionController),
                        hint: 'Optional description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Hourly rate field
                      Text(
                        'Hourly Rate (\$) *',
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
              ),
            ),

            // Actions
            const FDivider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
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
                          : Text(widget.isEditing ? 'Update' : 'Create'),
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
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final hourlyRate = double.tryParse(_hourlyRateController.text);
    if (hourlyRate == null || hourlyRate <= 0) {
      return;
    }

    setState(() => _isSubmitting = true);

    final room = Room(
      id: widget.room?.id ?? 0,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
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
