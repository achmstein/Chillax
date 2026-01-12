import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/menu_item.dart';

/// Menu state
class MenuState {
  final bool isLoading;
  final String? error;
  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final int? selectedCategoryId;

  const MenuState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.categories = const [],
    this.selectedCategoryId,
  });

  MenuState copyWith({
    bool? isLoading,
    String? error,
    List<MenuItem>? items,
    List<MenuCategory>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }

  List<MenuItem> get filteredItems {
    if (selectedCategoryId == null) return items;
    return items.where((i) => i.catalogTypeId == selectedCategoryId).toList();
  }
}

/// Menu provider
class MenuNotifier extends StateNotifier<MenuState> {
  final ApiClient _api;

  MenuNotifier(this._api) : super(const MenuState());

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _api.get('/api/catalog/items'),
        _api.get('/api/catalog/catalogtypes'),
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
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load menu: $e',
      );
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
      await _api.patch('/api/catalog/items/$itemId', data: {
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
      state = state.copyWith(error: 'Failed to update item: $e');
      return false;
    }
  }

  Future<bool> createItem(MenuItem item) async {
    try {
      await _api.post('/api/catalog/items', data: item.toJson());
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create item: $e');
      return false;
    }
  }

  Future<bool> updateItem(MenuItem item) async {
    try {
      await _api.put('/api/catalog/items/${item.id}', data: item.toJson());
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update item: $e');
      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      await _api.delete('/api/catalog/items/$itemId');
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete item: $e');
      return false;
    }
  }

  // Category CRUD operations
  Future<bool> createCategory(String name) async {
    try {
      await _api.post('/api/catalog/categories', data: {'type': name});
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    try {
      await _api.put('/api/catalog/categories/$id', data: {'type': name});
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _api.delete('/api/catalog/categories/$id');
      await loadMenu();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete category: $e');
      return false;
    }
  }

  int getItemCountForCategory(int categoryId) {
    return state.items.where((i) => i.catalogTypeId == categoryId).length;
  }
}

/// Menu provider
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final api = ref.read(catalogApiProvider);
  return MenuNotifier(api);
});
