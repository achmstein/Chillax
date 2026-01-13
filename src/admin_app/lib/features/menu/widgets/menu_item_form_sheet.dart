import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _prepTimeController;
  int? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(
        text: widget.item?.price.toStringAsFixed(2) ?? '');
    _prepTimeController = TextEditingController(
        text: widget.item?.preparationTimeMinutes?.toString() ?? '');
    _selectedCategoryId = widget.item?.catalogTypeId;
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final state = ref.watch(menuProvider);

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
                    widget.isEditing ? 'Edit Menu Item' : 'Add Menu Item',
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
                        hint: 'Enter item name',
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
                        hint: 'Enter item description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Price field
                      Text(
                        'Price *',
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
                      Text(
                        'Category *',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _selectedCategoryId,
                        hint: Text(
                          'Select category',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        isExpanded: true,
                        items: state.categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
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
                      Text(
                        'Preparation Time (minutes)',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FTextField(
                        control: FTextFieldControl.managed(controller: _prepTimeController),
                        hint: 'e.g. 10',
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
                          Text(
                            'Available',
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final state = ref.read(menuProvider);
    final categoryName = state.categories
        .firstWhere((c) => c.id == _selectedCategoryId)
        .name;

    final item = MenuItem(
      id: widget.item?.id ?? 0,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      catalogTypeId: _selectedCategoryId!,
      catalogTypeName: categoryName,
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
