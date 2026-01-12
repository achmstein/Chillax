import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/menu_item.dart';
import '../models/user_preference.dart';

/// Menu service for catalog API
class MenuService {
  final ApiClient _apiClient;

  MenuService(this._apiClient);

  /// Get all menu items
  Future<List<MenuItem>> getMenuItems({int? categoryId}) async {
    final queryParams = <String, dynamic>{};
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }

    final response = await _apiClient.get<List<dynamic>>(
      'items',
      queryParameters: queryParams,
    );

    return (response.data ?? [])
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .where((item) => item.isAvailable)
        .toList();
  }

  /// Get menu item by ID
  Future<MenuItem> getMenuItem(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'items/$id',
    );

    return MenuItem.fromJson(response.data!);
  }

  /// Get all categories
  Future<List<MenuCategory>> getCategories() async {
    final response = await _apiClient.get<List<dynamic>>(
      'categories',
    );

    return (response.data ?? [])
        .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get user's preference for a specific item
  Future<UserItemPreference?> getUserPreference(int catalogItemId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'preferences/$catalogItemId',
      );

      if (response.data != null) {
        return UserItemPreference.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      // Return null if no preference found (404) or any error
      return null;
    }
  }

  /// Get user's preferences for multiple items
  Future<List<UserItemPreference>> getUserPreferences(List<int> catalogItemIds) async {
    if (catalogItemIds.isEmpty) return [];

    try {
      final response = await _apiClient.post<List<dynamic>>(
        'preferences/batch',
        data: catalogItemIds,
      );

      return (response.data ?? [])
          .map((e) => UserItemPreference.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save user's preferences after successful order
  Future<void> saveUserPreferences(SaveUserPreferencesRequest request) async {
    await _apiClient.post(
      'preferences',
      data: request.toJson(),
    );
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

/// Provider for user's preference for a specific item
final userPreferenceProvider = FutureProvider.family<UserItemPreference?, int>(
  (ref, catalogItemId) async {
    final service = ref.watch(menuServiceProvider);
    return service.getUserPreference(catalogItemId);
  },
);
