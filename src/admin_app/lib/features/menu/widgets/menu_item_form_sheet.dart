import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/localized_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';

/// Form sheet for creating or editing menu items
class MenuItemFormSheet extends ConsumerStatefulWidget {
  final MenuItem? item;

  const MenuItemFormSheet({super.key, this.item});

  bool get isEditing => item != null;

  @override
  ConsumerState<MenuItemFormSheet> createState() => _MenuItemFormSheetState();
}

class _MenuItemFormSheetState extends ConsumerState<MenuItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _priceController;
  late TextEditingController _prepTimeController;
  int? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.item?.name.en ?? '');
    _nameArController = TextEditingController(text: widget.item?.name.ar ?? '');
    _descriptionEnController =
        TextEditingController(text: widget.item?.description.en ?? '');
    _descriptionArController =
        TextEditingController(text: widget.item?.description.ar ?? '');
    _priceController = TextEditingController(
        text: widget.item?.price.toStringAsFixed(2) ?? '');
    _prepTimeController = TextEditingController(
        text: widget.item?.preparationTimeMinutes?.toString() ?? '');
    _selectedCategoryId = widget.item?.catalogTypeId;
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(menuProvider);

    return Container(
      width: 400,
      color: theme.colors.background,
      child: SafeArea(
        bottom: false,
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
                  AppText(
                    widget.isEditing ? l10n.editMenuItem : l10n.addMenuItem,
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
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
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
                        enHint: 'Enter item name',
                        arHint: 'اكتب اسم المنتج',
                      ),
                      const SizedBox(height: 16),

                      // Description field (bilingual)
                      LocalizedTextField(
                        label: l10n.description,
                        enController: _descriptionEnController,
                        arController: _descriptionArController,
                        enHint: 'Enter item description',
                        arHint: 'اكتب وصف المنتج',
                        isMultiline: true,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Price field
                      AppText(
                        '${l10n.price} *',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FTextField(
                        control: FTextFieldControl.managed(controller: _priceController),
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      AppText(
                        l10n.categoryRequired,
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _selectedCategoryId,
                        hint: AppText(
                          l10n.selectCategory,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        isExpanded: true,
                        items: state.categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: AppText(category.name.localized(context)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Preparation time field
                      AppText(
                        l10n.preparationTime,
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FTextField(
                        control: FTextFieldControl.managed(controller: _prepTimeController),
                        hint: l10n.prepTimeHint,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Availability toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            l10n.availableLabel,
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          FSwitch(
                            value: _isAvailable,
                            onChange: (value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                          ),
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
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
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
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText(l10n.pleaseSelectCategory)),
      );
      return;
    }

    if (_nameEnController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    final state = ref.read(menuProvider);
    final category = state.categories
        .firstWhere((c) => c.id == _selectedCategoryId);

    final item = MenuItem(
      id: widget.item?.id ?? 0,
      name: LocalizedTextControllers.getValue(_nameEnController, _nameArController),
      description: LocalizedTextControllers.getValue(
          _descriptionEnController, _descriptionArController),
      price: double.parse(_priceController.text),
      catalogTypeId: _selectedCategoryId!,
      catalogTypeName: category.name,
      isAvailable: _isAvailable,
      preparationTimeMinutes: _prepTimeController.text.isNotEmpty
          ? int.parse(_prepTimeController.text)
          : null,
      customizations: widget.item?.customizations ?? [],
    );

    bool success;
    if (widget.isEditing) {
      success = await ref.read(menuProvider.notifier).updateItem(item);
    } else {
      success = await ref.read(menuProvider.notifier).createItem(item);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
