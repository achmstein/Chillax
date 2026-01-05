import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/menu_item.dart';

/// Menu service for catalog API
class MenuService {
  final ApiClient _apiClient;

  MenuService(this._apiClient);

  /// Get all menu items
  Future<List<MenuItem>> getMenuItems({int? categoryId}) async {
    final queryParams = <String, dynamic>{};
    if (categoryId != null) {
      queryParams['catalogTypeId'] = categoryId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/catalog/items',
      queryParameters: queryParams,
    );

    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .where((item) => item.isAvailable)
        .toList();
  }

  /// Get menu item by ID
  Future<MenuItem> getMenuItem(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/catalog/items/$id',
    );

    return MenuItem.fromJson(response.data!);
  }

  /// Get all categories
  Future<List<MenuCategory>> getCategories() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/catalog/catalogtypes',
    );

    return (response.data ?? [])
        .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Provider for menu service
final menuServiceProvider = Provider<MenuService>((ref) {
  final apiClient = ref.watch(catalogApiProvider);
  return MenuService(apiClient);
});

/// Provider for menu items
final menuItemsProvider = FutureProvider.family<List<MenuItem>, int?>(
  (ref, categoryId) async {
    final service = ref.watch(menuServiceProvider);
    return service.getMenuItems(categoryId: categoryId);
  },
);

/// Provider for categories
final categoriesProvider = FutureProvider<List<MenuCategory>>((ref) async {
  final service = ref.watch(menuServiceProvider);
  return service.getCategories();
});

/// Provider for selected category
final selectedCategoryProvider = StateProvider<int?>((ref) => null);
