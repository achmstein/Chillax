import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/localized_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../widgets/customization_group_sheet.dart';
import '../widgets/image_picker_sheet.dart';

/// Full-page screen for adding/editing menu items with image and customizations
class MenuItemEditScreen extends ConsumerStatefulWidget {
  final int? itemId;

  const MenuItemEditScreen({super.key, this.itemId});

  bool get isEditing => itemId != null;

  @override
  ConsumerState<MenuItemEditScreen> createState() => _MenuItemEditScreenState();
}

class _MenuItemEditScreenState extends ConsumerState<MenuItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _priceController;
  int? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isPopular = false;
  bool _isSubmitting = false;

  // Image state
  File? _selectedImageFile;
  String? _existingImageUri;
  bool _imageRemoved = false;

  // Customizations
  List<ItemCustomization> _customizations = [];

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController();
    _nameArController = TextEditingController();
    _descriptionEnController = TextEditingController();
    _descriptionArController = TextEditingController();
    _priceController = TextEditingController();

    // Load existing item data if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItemData();
    });
  }

  void _loadItemData() {
    if (widget.itemId != null) {
      final item = ref.read(menuProvider).items.where((i) => i.id == widget.itemId).firstOrNull;
      if (item != null) {
        setState(() {
          _nameEnController.text = item.name.en;
          _nameArController.text = item.name.ar ?? '';
          _descriptionEnController.text = item.description.en;
          _descriptionArController.text = item.description.ar ?? '';
          _priceController.text = item.price.toStringAsFixed(2);
          _selectedCategoryId = item.catalogTypeId;
          _isAvailable = item.isAvailable;
          _isPopular = item.isPopular;
          _existingImageUri = item.pictureUri;
          _customizations = List.from(item.customizations);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(menuProvider);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colors.background,
                border: Border(bottom: BorderSide(color: theme.colors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      widget.isEditing ? l10n.editMenuItemPage : l10n.addMenuItemPage,
                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : _save,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section
                      _buildImageSection(context),
                      const SizedBox(height: 24),

                      // Basic info section
                      _buildBasicInfoSection(context, state),
                      const SizedBox(height: 24),

                      // Customizations section
                      _buildCustomizationsSection(context),
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

  Widget _buildImageSection(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    final hasImage = _selectedImageFile != null || (_existingImageUri != null && !_imageRemoved);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          l10n.itemImage,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        FTappable(
          onPress: () => _pickImage(context),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colors.border),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImageFile != null
                        ? Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 180,
                          )
                        : CachedNetworkImage(
                            imageUrl: _existingImageUri!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 180,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: theme.colors.primary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        l10n.tapToAddImage,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, MenuState state) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field (bilingual)
        LocalizedTextField(
          label: l10n.name,
          isRequired: true,
          enController: _nameEnController,
          arController: _nameArController,
          enHint: 'Enter item name',
          arHint: 'اكتب اسم الصنف',
        ),
        const SizedBox(height: 16),

        // Description field (bilingual)
        LocalizedTextField(
          label: l10n.description,
          enController: _descriptionEnController,
          arController: _descriptionArController,
          enHint: 'Enter item description',
          arHint: 'اكتب وصف الصنف',
          isMultiline: true,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Price field
        AppText(
          '${l10n.price} *',
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        FTextField(
          control: FTextFieldControl.managed(controller: _priceController),
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 16),

        // Category dropdown
        AppText(
          l10n.categoryRequired,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: _selectedCategoryId,
            hint: AppText(
              l10n.selectCategory,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            items: state.categories.map((category) {
              return DropdownMenuItem<int>(
                value: category.id,
                child: AppText(category.name.localized(context)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
          ),
        ),
        const SizedBox(height: 16),

        // Availability toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              l10n.availableLabel,
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
            ),
            FSwitch(
              value: _isAvailable,
              onChange: (value) => setState(() => _isAvailable = value),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Popular toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              l10n.popular,
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
            ),
            FSwitch(
              value: _isPopular,
              onChange: (value) => setState(() => _isPopular = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationsSection(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              l10n.customizations,
              style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addOrEditCustomization(context),
              tooltip: l10n.addCustomization,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Customizations list
        if (_customizations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.tune_outlined,
                    size: 32,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    l10n.noCustomizations,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    l10n.addCustomizationsHint,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _customizations.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _customizations.removeAt(oldIndex);
                  _customizations.insert(newIndex, item);
                });
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: theme.colors.background,
                  elevation: 2,
                  shadowColor: theme.colors.border,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final customization = _customizations[index];
                return _CustomizationTile(
                  key: ObjectKey(customization),
                  customization: customization,
                  index: index,
                  onTap: () => _addOrEditCustomization(context, customization: customization, index: index),
                  onDelete: () => _deleteCustomization(context, index),
                  showDivider: index < _customizations.length - 1,
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final hasExisting = _existingImageUri != null && !_imageRemoved;
    final result = await showImagePickerSheet(
      context,
      hasExistingImage: hasExisting || _selectedImageFile != null,
    );

    if (result == 'remove') {
      setState(() {
        _selectedImageFile = null;
        _imageRemoved = true;
      });
    } else if (result is File) {
      setState(() {
        _selectedImageFile = result;
        _imageRemoved = false;
      });
    }
  }

  Future<void> _addOrEditCustomization(
    BuildContext context, {
    ItemCustomization? customization,
    int? index,
  }) async {
    final result = await showCustomizationGroupSheet(
      context,
      customization: customization,
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _customizations[index] = result;
        } else {
          _customizations.add(result);
        }
      });
    }
  }

  Future<void> _deleteCustomization(BuildContext context, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: AppText(l10n.delete),
        body: AppText(l10n.deleteCustomizationConfirm),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            child: AppText(l10n.cancel),
            onPress: () => Navigator.of(context).pop(false),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            child: AppText(l10n.delete),
            onPress: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _customizations.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText(l10n.pleaseSelectCategory)),
      );
      return;
    }

    if (_nameEnController.text.trim().isEmpty) return;

    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final state = ref.read(menuProvider);
    final category = state.categories.firstWhere((c) => c.id == _selectedCategoryId);
    final notifier = ref.read(menuProvider.notifier);

    // Assign displayOrder from list position
    _customizations = _customizations.asMap().entries.map(
      (e) => e.value.copyWith(displayOrder: e.key),
    ).toList();

    // Build the item
    final item = MenuItem(
      id: widget.itemId ?? 0,
      name: LocalizedTextControllers.getValue(_nameEnController, _nameArController),
      description: LocalizedTextControllers.getValue(_descriptionEnController, _descriptionArController),
      price: price,
      catalogTypeId: _selectedCategoryId!,
      catalogTypeName: category.name,
      isAvailable: _isAvailable,
      isPopular: _isPopular,
      preparationTimeMinutes: null,
      customizations: _customizations,
    );

    bool success;
    int itemId;

    if (widget.isEditing) {
      success = await notifier.updateItem(item);
      itemId = widget.itemId!;
    } else {
      success = await notifier.createItem(item);
      // Get the newly created item's ID from the refreshed state
      await notifier.loadMenu();
      final newItem = ref.read(menuProvider).items
          .where((i) => i.name.en == item.name.en)
          .firstOrNull;
      itemId = newItem?.id ?? 0;
    }

    if (success && mounted) {
      // Handle image changes
      if (_selectedImageFile != null && itemId > 0) {
        await notifier.uploadItemImage(itemId, _selectedImageFile!);
        await notifier.loadMenu();
      } else if (_imageRemoved && itemId > 0) {
        await notifier.deleteItemImage(itemId);
      }

      // Save customizations
      // For editing, we need to sync customizations with the server
      if (widget.isEditing && itemId > 0) {
        await _syncCustomizations(itemId);
      } else if (!widget.isEditing && itemId > 0) {
        // For new items, create all customizations
        for (final customization in _customizations) {
          await notifier.createCustomization(itemId, customization);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(l10n.itemSaved)),
        );
        context.pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText(l10n.failedToSaveItem)),
      );
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> _syncCustomizations(int itemId) async {
    final notifier = ref.read(menuProvider.notifier);
    final originalItem = ref.read(menuProvider).items.where((i) => i.id == itemId).firstOrNull;
    final originalCustomizations = originalItem?.customizations ?? [];

    // Find customizations to delete (in original but not in current)
    for (final original in originalCustomizations) {
      if (!_customizations.any((c) => c.id == original.id && c.id != 0)) {
        await notifier.deleteCustomization(itemId, original.id);
      }
    }

    // Update or create customizations
    for (final customization in _customizations) {
      if (customization.id != 0 && originalCustomizations.any((c) => c.id == customization.id)) {
        // Update existing
        await notifier.updateCustomization(itemId, customization.id, customization);
      } else {
        // Create new
        await notifier.createCustomization(itemId, customization);
      }
    }
  }
}

class _CustomizationTile extends StatelessWidget {
  final ItemCustomization customization;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDivider;

  const _CustomizationTile({
    super.key,
    required this.customization,
    required this.index,
    required this.onTap,
    required this.onDelete,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppText(
                            customization.name.localized(context),
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (customization.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: AppText(
                                l10n.required,
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        l10n.optionsCount(customization.options.length),
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, indent: 12, endIndent: 12, color: theme.colors.border),
        ],
      ),
    );
  }
}
