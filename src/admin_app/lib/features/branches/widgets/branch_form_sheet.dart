import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/localized_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/branches_provider.dart';

class BranchFormSheet extends ConsumerStatefulWidget {
  final Branch? branch;

  const BranchFormSheet({super.key, this.branch});

  bool get isEditing => branch != null;

  @override
  ConsumerState<BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends ConsumerState<BranchFormSheet> {
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _addressEnController;
  late final TextEditingController _addressArController;
  late final TextEditingController _phoneController;
  late final TextEditingController _displayOrderController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _nameEnController = TextEditingController(text: branch?.name.en ?? '');
    _nameArController = TextEditingController(text: branch?.name.ar ?? '');
    _addressEnController = TextEditingController(text: branch?.address?.en ?? '');
    _addressArController = TextEditingController(text: branch?.address?.ar ?? '');
    _phoneController = TextEditingController(text: branch?.phone ?? '');
    _displayOrderController = TextEditingController(text: (branch?.displayOrder ?? 0).toString());
    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _addressEnController.dispose();
    _addressArController.dispose();
    _phoneController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nameEn = _nameEnController.text.trim();
    if (nameEn.isEmpty) return;

    setState(() => _isSaving = true);

    final name = LocalizedTextControllers.getValue(_nameEnController, _nameArController);
    final address = LocalizedTextControllers.getValueOrNull(_addressEnController, _addressArController);

    final data = <String, dynamic>{
      'name': name.toJson(),
      'address': address?.toJson(),
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'isActive': _isActive,
      'displayOrder': int.tryParse(_displayOrderController.text.trim()) ?? 0,
    };

    final notifier = ref.read(branchesManagementProvider.notifier);
    bool success;

    if (widget.isEditing) {
      success = await notifier.updateBranch(widget.branch!.id, data);
    } else {
      success = await notifier.createBranch(data);
    }

    if (success && mounted) {
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? l10n.branchUpdatedSuccess : l10n.branchCreatedSuccess),
        ),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
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
                      widget.isEditing ? l10n.editBranch : l10n.createBranch,
                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    LocalizedTextField(
                      label: l10n.branchName,
                      enController: _nameEnController,
                      arController: _nameArController,
                      enHint: 'Branch name in English',
                      arHint: 'اسم الفرع بالعربي',
                      isRequired: true,
                    ),

                    const SizedBox(height: 16),

                    // Address
                    LocalizedTextField(
                      label: l10n.branchAddress,
                      enController: _addressEnController,
                      arController: _addressArController,
                      enHint: 'Address in English',
                      arHint: 'العنوان بالعربي',
                    ),

                    const SizedBox(height: 16),

                    // Phone
                    AppText(
                      l10n.branchPhone,
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(controller: _phoneController),
                      hint: '01XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                    ),

                    const SizedBox(height: 16),

                    // Display Order
                    AppText(
                      l10n.displayOrder,
                      style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: FTextField(
                        control: FTextFieldControl.managed(controller: _displayOrderController),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textDirection: TextDirection.ltr,
                      ),
                    ),

                    // Active toggle (edit only)
                    if (widget.isEditing) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            _isActive ? FIcons.circleCheck : FIcons.circleX,
                            color: _isActive ? Colors.green : theme.colors.mutedForeground,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText(
                              l10n.branchActive,
                              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          FSwitch(
                            value: _isActive,
                            onChange: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save button - stays at bottom
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: _isSaving ? null : _save,
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colors.primaryForeground,
                          ),
                        )
                      : AppText(widget.isEditing ? l10n.update : l10n.create),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
