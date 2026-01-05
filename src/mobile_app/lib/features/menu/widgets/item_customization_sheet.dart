import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/menu_item.dart';
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
    // Pre-select default options
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Item header
                    Text(
                      widget.item.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                      'Base price: \$${widget.item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                    TextField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        hintText: 'Any special requests?',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // Space for button
                  ],
                ),
              ),

              // Add to cart button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _canAddToCart ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      'Add to Cart - \$${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 10,
                  ),
                ),
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
            return ChoiceChip(
              label: Text(
                option.priceAdjustment > 0
                    ? '${option.name} (+\$${option.priceAdjustment.toStringAsFixed(2)})'
                    : option.name,
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (customization.allowMultiple) {
                    // Toggle selection
                    final current = List<int>.from(selectedIds);
                    if (selected) {
                      current.add(option.id);
                    } else {
                      current.remove(option.id);
                    }
                    _selectedOptions[customization.id] = current;
                  } else {
                    // Single selection
                    if (selected) {
                      _selectedOptions[customization.id] = [option.id];
                    } else if (!customization.isRequired) {
                      _selectedOptions.remove(customization.id);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
