import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/models/localized_text.dart';
import '../../../core/network/api_client.dart';
import '../models/menu_item.dart';

/// Menu state
class MenuState {
  final bool isLoading;
  final String? error;
  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final int? selectedCategoryId;
  final bool isReorderingCategories;
  final bool isReorderingItems;

  const MenuState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.isReorderingCategories = false,
    this.isReorderingItems = false,
  });

  MenuState copyWith({
    bool? isLoading,
    String? error,
    List<MenuItem>? items,
    List<MenuCategory>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    bool? isReorderingCategories,
    bool? isReorderingItems,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      isReorderingCategories: isReorderingCategories ?? this.isReorderingCategories,
      isReorderingItems: isReorderingItems ?? this.isReorderingItems,
    );
  }

  List<MenuItem> get filteredItems {
    if (selectedCategoryId == null) return items;
    return items.where((i) => i.catalogTypeId == selectedCategoryId).toList();
  }
}

/// Menu provider
class MenuNotifier extends Notifier<MenuState> {
  late final ApiClient _api;

  @override
  MenuState build() {
    _api = ref.read(catalogApiProvider);
    return const MenuState();
  }

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _api.get('items'),
        _api.get('categories'),
      ]);

      final itemsData = results[0].data as List<dynamic>;
      final categoriesData = results[1].data as List<dynamic>;

      final items = itemsData
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final categories = categoriesData
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        items: items,
        categories: categories,
      );
    } catch (e) {
      debugPrint('Failed to load menu: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void selectCategory(int? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  Future<bool> updateItemAvailability(int itemId, bool isAvailable) async {
    try {
      await _api.patch('items/$itemId', data: {
        'isAvailable': isAvailable,
      });

      // Update local state
      final items = state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isAvailable: isAvailable);
        }
        return item;
      }).toList();

      state = state.copyWith(items: items);
      return true;
    } catch (e) {
      debugPrint('Failed to update item: $e');
      return false;
    }
  }

  Future<bool> createItem(MenuItem item) async {
    try {
      await _api.post('items', data: item.toJson());
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to create item: $e');
      return false;
    }
  }

  Future<bool> updateItem(MenuItem item) async {
    try {
      await _api.put('items/${item.id}', data: item.toJson());
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to update item: $e');
      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      await _api.delete('items/$itemId');
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to delete item: $e');
      return false;
    }
  }

  // Category CRUD operations
  Future<bool> createCategory(LocalizedText name) async {
    try {
      await _api.post('categories', data: {
        'name': name.toJson(),
      });
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to create category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(int id, LocalizedText name) async {
    try {
      await _api.put('categories/$id', data: {
        'name': name.toJson(),
      });
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to update category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _api.delete('categories/$id');
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to delete category: $e');
      return false;
    }
  }

  int getItemCountForCategory(int categoryId) {
    return state.items.where((i) => i.catalogTypeId == categoryId).length;
  }

  // Image upload
  Future<String?> uploadItemImage(int itemId, File imageFile) async {
    try {
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await _api.post(
        'items/$itemId/pic',
        data: formData,
      );
      return response.data as String?;
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      return null;
    }
  }

  // Delete item image
  Future<bool> deleteItemImage(int itemId) async {
    try {
      await _api.delete('items/$itemId/pic');
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      return false;
    }
  }

  // Customization CRUD
  Future<ItemCustomization?> createCustomization(int itemId, ItemCustomization customization) async {
    try {
      final response = await _api.post(
        'items/$itemId/customizations',
        data: customization.toJson(),
      );
      await loadMenu();
      return ItemCustomization.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to create customization: $e');
      return null;
    }
  }

  Future<ItemCustomization?> updateCustomization(int itemId, int customizationId, ItemCustomization customization) async {
    try {
      final response = await _api.put(
        'items/$itemId/customizations/$customizationId',
        data: customization.toJson(),
      );
      await loadMenu();
      return ItemCustomization.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to update customization: $e');
      return null;
    }
  }

  Future<bool> deleteCustomization(int itemId, int customizationId) async {
    try {
      await _api.delete('items/$itemId/customizations/$customizationId');
      await loadMenu();
      return true;
    } catch (e) {
      debugPrint('Failed to delete customization: $e');
      return false;
    }
  }

  /// Get a single item by ID
  MenuItem? getItem(int itemId) {
    return state.items.where((i) => i.id == itemId).firstOrNull;
  }

  // Reorder mode methods
  void toggleCategoryReorderMode() {
    state = state.copyWith(isReorderingCategories: !state.isReorderingCategories);
  }

  void toggleItemReorderMode() {
    state = state.copyWith(isReorderingItems: !state.isReorderingItems);
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final categories = List<MenuCategory>.from(state.categories);
    final item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);
    state = state.copyWith(categories: categories);
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    if (state.selectedCategoryId != null) {
      // Reorder within the filtered list, then map back to the full list
      final filtered = List<MenuItem>.from(state.filteredItems);
      final movedItem = filtered.removeAt(oldIndex);
      filtered.insert(newIndex, movedItem);

      // Rebuild full items list: replace items in the filtered category with new order
      final allItems = List<MenuItem>.from(state.items);
      final filteredIds = filtered.map((i) => i.id).toSet();
      allItems.removeWhere((i) => filteredIds.contains(i.id));

      // Find insertion point (index of first item from this category, or end)
      int insertAt = allItems.length;
      for (int i = 0; i < allItems.length; i++) {
        if (allItems[i].catalogTypeId == state.selectedCategoryId) {
          insertAt = i;
          break;
        }
      }
      allItems.insertAll(insertAt, filtered);
      state = state.copyWith(items: allItems);
    } else {
      final items = List<MenuItem>.from(state.items);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      state = state.copyWith(items: items);
    }
  }

  Future<bool> saveReorderedCategories() async {
    try {
      final reorderItems = state.categories.asMap().entries.map((e) => {
        'id': e.value.id,
        'displayOrder': e.key,
      }).toList();

      await _api.put('categories/reorder', data: {'items': reorderItems});
      state = state.copyWith(isReorderingCategories: false);
      return true;
    } catch (e) {
      debugPrint('Failed to save category order: $e');
      return false;
    }
  }

  Future<bool> saveReorderedItems() async {
    try {
      final itemsToReorder = state.selectedCategoryId != null
          ? state.filteredItems
          : state.items;

      final reorderItems = itemsToReorder.asMap().entries.map((e) => {
        'id': e.value.id,
        'displayOrder': e.key,
      }).toList();

      await _api.put('items/reorder', data: {'items': reorderItems});
      state = state.copyWith(isReorderingItems: false);
      return true;
    } catch (e) {
      debugPrint('Failed to save item order: $e');
      return false;
    }
  }

  Future<void> cancelCategoryReorder() async {
    state = state.copyWith(isReorderingCategories: false);
    await loadMenu();
  }

  Future<void> cancelItemReorder() async {
    state = state.copyWith(isReorderingItems: false);
    await loadMenu();
  }
}

/// Menu provider
final menuProvider = NotifierProvider<MenuNotifier, MenuState>(MenuNotifier.new);
