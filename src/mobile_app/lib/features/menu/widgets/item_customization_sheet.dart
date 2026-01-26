import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/theme/app_theme.dart';
import '../models/menu_item.dart';
import '../models/user_preference.dart';
import '../services/menu_service.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/services/cart_service.dart';

/// Bottom sheet for customizing menu item
class ItemCustomizationSheet extends ConsumerStatefulWidget {
  final MenuItem item;

  const ItemCustomizationSheet({super.key, required this.item});

  @override
  ConsumerState<ItemCustomizationSheet> createState() =>
      _ItemCustomizationSheetState();
}

class _ItemCustomizationSheetState
    extends ConsumerState<ItemCustomizationSheet> {
  final Map<int, List<int>> _selectedOptions = {}; // customizationId -> optionIds
  final TextEditingController _instructionsController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Pre-select default options first
    _initializeWithDefaults();
    // Then load saved preferences
    _loadSavedPreferences();
  }

  void _initializeWithDefaults() {
    for (final customization in widget.item.customizations) {
      final defaults = customization.options
          .where((o) => o.isDefault)
          .map((o) => o.id)
          .toList();
      if (defaults.isNotEmpty) {
        _selectedOptions[customization.id] = defaults;
      } else if (customization.isRequired && customization.options.isNotEmpty) {
        _selectedOptions[customization.id] = [customization.options.first.id];
      }
    }
  }

  Future<void> _loadSavedPreferences() async {
    final service = ref.read(menuServiceProvider);
    final preference = await service.getUserPreference(widget.item.id);

    if (preference != null && mounted) {
      _applyPreference(preference);
    }
  }

  void _applyPreference(UserItemPreference preference) {
    // Group saved options by customization ID
    final savedByCustomization = <int, List<int>>{};
    for (final option in preference.selectedOptions) {
      savedByCustomization
          .putIfAbsent(option.customizationId, () => [])
          .add(option.optionId);
    }

    // Apply saved preferences, validating they still exist
    for (final customization in widget.item.customizations) {
      final savedOptions = savedByCustomization[customization.id];
      if (savedOptions != null && savedOptions.isNotEmpty) {
        // Filter to only options that still exist in the catalog
        final validOptions = savedOptions
            .where((optionId) =>
                customization.options.any((o) => o.id == optionId))
            .toList();

        if (validOptions.isNotEmpty) {
          _selectedOptions[customization.id] = validOptions;
        }
      }
    }

    // Ensure required customizations have a selection
    for (final customization in widget.item.customizations) {
      if (customization.isRequired) {
        final selected = _selectedOptions[customization.id] ?? [];
        if (selected.isEmpty && customization.options.isNotEmpty) {
          _selectedOptions[customization.id] = [customization.options.first.id];
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = widget.item.price;
    for (final entry in _selectedOptions.entries) {
      final customization = widget.item.customizations
          .firstWhere((c) => c.id == entry.key);
      for (final optionId in entry.value) {
        final option = customization.options.firstWhere((o) => o.id == optionId);
        total += option.priceAdjustment;
      }
    }
    return total * _quantity;
  }

  bool get _canAddToCart {
    for (final customization in widget.item.customizations) {
      if (customization.isRequired) {
        final selected = _selectedOptions[customization.id] ?? [];
        if (selected.isEmpty) return false;
      }
    }
    return true;
  }

  void _addToCart() {
    final selectedCustomizations = <SelectedCustomization>[];

    for (final entry in _selectedOptions.entries) {
      final customization = widget.item.customizations
          .firstWhere((c) => c.id == entry.key);
      for (final optionId in entry.value) {
        final option = customization.options.firstWhere((o) => o.id == optionId);
        selectedCustomizations.add(SelectedCustomization(
          customizationId: customization.id,
          customizationName: customization.name,
          optionId: option.id,
          optionName: option.name,
          priceAdjustment: option.priceAdjustment,
        ));
      }
    }

    final cartItem = CartItem.fromMenuItem(
      widget.item,
      customizations: selectedCustomizations,
      instructions: _instructionsController.text.isNotEmpty
          ? _instructionsController.text
          : null,
    );
    cartItem.quantity = _quantity;

    ref.read(cartProvider.notifier).addItem(cartItem);
    Navigator.pop(context);

    showFToast(
      context: context,
      title: Text('${widget.item.name} added to cart'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item header with close button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(FIcons.x, size: 24, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (widget.item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.item.description,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Base price: £${widget.item.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Customizations
                  ...widget.item.customizations.map((customization) =>
                    _buildCustomizationSection(customization)),

                  // Special instructions
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FTextField.multiline(
                    control: FTextFieldControl.managed(controller: _instructionsController),
                    hint: 'Any special requests?',
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FButton.icon(
                        onPress: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        child: const Icon(FIcons.minus),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FButton.icon(
                        onPress: () => setState(() => _quantity++),
                        child: const Icon(FIcons.plus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Add to cart button
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canAddToCart ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canAddToCart ? AppTheme.primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '£${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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

  Widget _buildCustomizationSection(ItemCustomization customization) {
    final selectedIds = _selectedOptions[customization.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              customization.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (customization.isRequired) ...[
              const Spacer(),
              FBadge(
                style: FBadgeStyle.destructive(),
                child: const Text('Required'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: customization.options.map((option) {
            final isSelected = selectedIds.contains(option.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (customization.allowMultiple) {
                    final current = List<int>.from(selectedIds);
                    if (isSelected) {
                      current.remove(option.id);
                    } else {
                      current.add(option.id);
                    }
                    _selectedOptions[customization.id] = current;
                  } else {
                    if (isSelected && !customization.isRequired) {
                      _selectedOptions.remove(customization.id);
                    } else {
                      _selectedOptions[customization.id] = [option.id];
                    }
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                  ),
                ),
                child: Text(
                  option.priceAdjustment > 0
                      ? '${option.name} (+£${option.priceAdjustment.toStringAsFixed(2)})'
                      : option.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
