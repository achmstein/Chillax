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
import '../models/bundle_deal.dart';
import '../models/menu_item.dart';
import '../providers/bundle_deals_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/image_picker_sheet.dart';

/// Screen for creating/editing a bundle deal
class BundleDealEditScreen extends ConsumerStatefulWidget {
  final int? bundleId;

  const BundleDealEditScreen({super.key, this.bundleId});

  bool get isEditing => bundleId != null;

  @override
  ConsumerState<BundleDealEditScreen> createState() => _BundleDealEditScreenState();
}

class _BundleDealEditScreenState extends ConsumerState<BundleDealEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descEnController;
  late TextEditingController _descArController;
  late TextEditingController _priceController;
  bool _isActive = true;
  bool _isSubmitting = false;

  // Image state
  File? _selectedImageFile;
  String? _existingImageUri;
  bool _imageRemoved = false;

  // Selected items: catalogItemId -> quantity
  final Map<int, int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController();
    _nameArController = TextEditingController();
    _descEnController = TextEditingController();
    _descArController = TextEditingController();
    _priceController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    ref.read(menuProvider.notifier).loadMenu();

    if (widget.bundleId != null) {
      final bundle = ref.read(bundleDealsProvider).bundles
          .where((b) => b.id == widget.bundleId)
          .firstOrNull;
      if (bundle != null) {
        setState(() {
          _nameEnController.text = bundle.name.en;
          _nameArController.text = bundle.name.ar ?? '';
          _descEnController.text = bundle.description.en;
          _descArController.text = bundle.description.ar ?? '';
          _priceController.text = bundle.bundlePrice.toStringAsFixed(2);
          _isActive = bundle.isActive;
          _existingImageUri = bundle.pictureUri;
          for (final item in bundle.items) {
            _selectedItems[item.catalogItemId] = item.quantity;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descEnController.dispose();
    _descArController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final menuState = ref.watch(menuProvider);

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
                      widget.isEditing ? l10n.editBundle : l10n.createBundle,
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
                      // Name
                      LocalizedTextField(
                        label: l10n.name,
                        isRequired: true,
                        enController: _nameEnController,
                        arController: _nameArController,
                        enHint: 'Bundle name',
                        arHint: 'اسم العرض',
                      ),
                      const SizedBox(height: 16),

                      // Description
                      LocalizedTextField(
                        label: l10n.description,
                        enController: _descEnController,
                        arController: _descArController,
                        enHint: 'Bundle description',
                        arHint: 'وصف العرض',
                        isMultiline: true,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Image
                      _buildImageSection(context),
                      const SizedBox(height: 16),

                      // Bundle price
                      AppText(
                        '${l10n.bundlePrice} *',
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

                      // Active toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            l10n.bundleActive,
                            style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                          ),
                          FSwitch(
                            value: _isActive,
                            onChange: (value) => setState(() => _isActive = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Select items
                      AppText(
                        l10n.selectItems,
                        style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      ...menuState.items.map((item) => _ItemSelector(
                        item: item,
                        quantity: _selectedItems[item.id] ?? 0,
                        onChanged: (qty) {
                          setState(() {
                            if (qty <= 0) {
                              _selectedItems.remove(item.id);
                            } else {
                              _selectedItems[item.id] = qty;
                            }
                          });
                        },
                      )),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (_nameEnController.text.trim().isEmpty) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText(l10n.selectItems)),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(bundleDealsProvider.notifier);
    final items = _selectedItems.entries.map((e) => BundleDealItem(
      id: 0,
      catalogItemId: e.key,
      itemName: LocalizedText(en: ''),
      itemPrice: 0,
      quantity: e.value,
    )).toList();

    final bundle = BundleDeal(
      id: widget.bundleId ?? 0,
      name: LocalizedTextControllers.getValue(_nameEnController, _nameArController),
      description: LocalizedTextControllers.getValue(_descEnController, _descArController),
      bundlePrice: price,
      originalPrice: 0,
      isActive: _isActive,
      items: items,
    );

    bool success;
    int? bundleId;
    if (widget.isEditing) {
      success = await notifier.updateBundle(widget.bundleId!, bundle);
      bundleId = widget.bundleId;
    } else {
      bundleId = await notifier.createBundle(bundle);
      success = bundleId != null;
    }

    if (success && bundleId != null && mounted) {
      // Handle image changes
      if (_selectedImageFile != null) {
        await notifier.uploadBundleImage(bundleId, _selectedImageFile!);
      } else if (_imageRemoved) {
        await notifier.deleteBundleImage(bundleId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(l10n.itemSaved)),
        );
        context.pop();
      }
    }

    setState(() => _isSubmitting = false);
  }
}

class _ItemSelector extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ItemSelector({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context)!;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colors.primary.withValues(alpha: 0.05) : null,
        border: Border.all(
          color: isSelected ? theme.colors.primary : theme.colors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.name.localized(context),
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                ),
                AppText(
                  l10n.priceFormat(item.price.toStringAsFixed(2)),
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
          if (isSelected) ...[
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: () => onChanged(quantity - 1),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            AppText(
              '$quantity',
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => onChanged(quantity + 1),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => onChanged(1),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
