import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/localized_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/menu_item.dart';

/// Bottom sheet for adding/editing a customization group with options
class CustomizationGroupSheet extends StatefulWidget {
  final ItemCustomization? customization;

  const CustomizationGroupSheet({super.key, this.customization});

  bool get isEditing => customization != null;

  @override
  State<CustomizationGroupSheet> createState() => _CustomizationGroupSheetState();
}

class _CustomizationGroupSheetState extends State<CustomizationGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  bool _isRequired = false;
  bool _allowMultiple = false;
  late List<_EditableOption> _options;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.customization?.name.en ?? '');
    _nameArController = TextEditingController(text: widget.customization?.name.ar ?? '');
    _isRequired = widget.customization?.isRequired ?? false;
    _allowMultiple = widget.customization?.allowMultiple ?? false;
    _options = widget.customization?.options.map((o) => _EditableOption.fromOption(o)).toList() ?? [];
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Drag handle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          widget.isEditing ? l10n.editCustomization : l10n.addCustomization,
                          style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  FButton(
                    onPress: _save,
                    child: AppText(l10n.save),
                  ),
                ],
              ),
            ),
            const FDivider(),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field (bilingual)
                      LocalizedTextField(
                        label: l10n.customizationName,
                        isRequired: true,
                        enController: _nameEnController,
                        arController: _nameArController,
                        enHint: l10n.customizationNameHint,
                        arHint: l10n.customizationNameHint,
                      ),
                      const SizedBox(height: 16),

                      // Required toggle
                      _SwitchTile(
                        title: l10n.required,
                        value: _isRequired,
                        onChanged: (value) => setState(() => _isRequired = value),
                      ),
                      const SizedBox(height: 12),

                      // Allow Multiple toggle
                      _SwitchTile(
                        title: l10n.allowMultiple,
                        value: _allowMultiple,
                        onChanged: (value) => setState(() => _allowMultiple = value),
                      ),
                      const SizedBox(height: 24),

                      // Options header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            l10n.options,
                            style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 22),
                            onPressed: _addOption,
                            tooltip: l10n.addOption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Options list
                      if (_options.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: AppText(
                              l10n.optionRequired,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return _OptionCard(
                            key: ValueKey(option.id),
                            option: option,
                            index: index,
                            onDelete: () => _removeOption(index),
                            onSetDefault: () => _setDefaultOption(index),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    setState(() {
      _options.add(_EditableOption());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options[index].dispose();
      _options.removeAt(index);
    });
  }

  void _setDefaultOption(int index) {
    setState(() {
      for (int i = 0; i < _options.length; i++) {
        _options[i].isDefault = i == index;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_nameEnController.text.trim().isEmpty) return;

    final options = _options
        .where((o) => o.nameEnController.text.trim().isNotEmpty)
        .toList();

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText(AppLocalizations.of(context)!.optionRequired)),
      );
      return;
    }

    final customization = ItemCustomization(
      id: widget.customization?.id ?? 0,
      name: LocalizedTextControllers.getValue(_nameEnController, _nameArController),
      isRequired: _isRequired,
      allowMultiple: _allowMultiple,
      displayOrder: widget.customization?.displayOrder ?? 0,
      options: options.asMap().entries.map((entry) {
        final index = entry.key;
        final opt = entry.value;
        final priceText = opt.priceController.text.trim();
        final price = priceText.isEmpty ? 0.0 : double.tryParse(priceText) ?? 0.0;

        return CustomizationOption(
          id: opt.originalId ?? 0,
          name: LocalizedTextControllers.getValue(opt.nameEnController, opt.nameArController),
          priceAdjustment: price,
          isDefault: opt.isDefault,
          displayOrder: index,
        );
      }).toList(),
    );

    Navigator.of(context).pop(customization);
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            title,
            style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
          ),
          FSwitch(
            value: value,
            onChange: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EditableOption {
  final String id;
  final int? originalId;
  final TextEditingController nameEnController;
  final TextEditingController nameArController;
  final TextEditingController priceController;
  bool isDefault;

  _EditableOption({
    String? id,
    this.originalId,
    String nameEn = '',
    String nameAr = '',
    String price = '',
    this.isDefault = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nameEnController = TextEditingController(text: nameEn),
        nameArController = TextEditingController(text: nameAr),
        priceController = TextEditingController(text: price);

  factory _EditableOption.fromOption(CustomizationOption option) {
    return _EditableOption(
      id: option.id.toString(),
      originalId: option.id,
      nameEn: option.name.en,
      nameAr: option.name.ar ?? '',
      price: option.priceAdjustment != 0 ? option.priceAdjustment.toString() : '',
      isDefault: option.isDefault,
    );
  }

  void dispose() {
    nameEnController.dispose();
    nameArController.dispose();
    priceController.dispose();
  }
}

class _OptionCard extends StatelessWidget {
  final _EditableOption option;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _OptionCard({
    super.key,
    required this.option,
    required this.index,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: option.isDefault
            ? Border.all(color: theme.colors.primary, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN field
          _CompactTextField(
            controller: option.nameEnController,
            label: 'EN',
            hint: l10n.optionNameHint,
          ),
          const SizedBox(height: 8),

          // AR field
          _CompactTextField(
            controller: option.nameArController,
            label: 'AR',
            hint: l10n.optionNameHint,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),

          // Price and actions row
          Row(
            children: [
              // Price field
              SizedBox(
                width: 100,
                child: _CompactTextField(
                  controller: option.priceController,
                  label: '+/-',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                ),
              ),
              const Spacer(),

              // Default toggle
              FTappable(
                onPress: onSetDefault,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: option.isDefault
                        ? theme.colors.primary
                        : theme.colors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AppText(
                    l10n.defaultOption,
                    style: theme.typography.xs.copyWith(
                      color: option.isDefault
                          ? theme.colors.primaryForeground
                          : theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colors.destructive,
                  size: 20,
                ),
                onPressed: onDelete,
                tooltip: l10n.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _CompactTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.textDirection,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Container(
          width: 28,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: AppText(
              label,
              style: theme.typography.xs.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FTextField(
            control: FTextFieldControl.managed(controller: controller),
            hint: hint,
            textDirection: textDirection,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
          ),
        ),
      ],
    );
  }
}

/// Shows the customization group sheet and returns the customization or null
Future<ItemCustomization?> showCustomizationGroupSheet(
  BuildContext context, {
  ItemCustomization? customization,
}) {
  return showModalBottomSheet<ItemCustomization>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomizationGroupSheet(customization: customization),
  );
}
