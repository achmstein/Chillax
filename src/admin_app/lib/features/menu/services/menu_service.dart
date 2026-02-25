import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/models/localized_text.dart';
import '../../../core/network/api_client.dart';
import '../models/menu_item.dart';

/// Abstract repository defining all menu-related API operations.
abstract class MenuRepository {
  Future<({List<MenuItem> items, List<MenuCategory> categories})> loadMenu();

  Future<void> updateItemAvailability(int itemId, bool isAvailable);

  Future<void> createItem(MenuItem item);

  Future<void> updateItem(MenuItem item);

  Future<void> deleteItem(int itemId);

  Future<void> createCategory(LocalizedText name);

  Future<void> updateCategory(int id, LocalizedText name);

  Future<void> deleteCategory(int id);

  Future<String?> uploadItemImage(int itemId, File imageFile);

  Future<void> deleteItemImage(int itemId);

  Future<ItemCustomization?> createCustomization(
      int itemId, ItemCustomization customization);

  Future<ItemCustomization?> updateCustomization(
      int itemId, int customizationId, ItemCustomization customization);

  Future<void> deleteCustomization(int itemId, int customizationId);

  Future<void> saveReorderedCategories(List<Map<String, dynamic>> reorderItems);

  Future<void> saveReorderedItems(List<Map<String, dynamic>> reorderItems);

  Future<void> setItemOffer(int itemId, bool isOnOffer, double? offerPrice);

  Future<List<Map<String, dynamic>>> loadBundles({bool includeInactive = true});

  Future<Map<String, dynamic>> createBundle(Map<String, dynamic> data);

  Future<Map<String, dynamic>> updateBundle(int id, Map<String, dynamic> data);

  Future<void> deleteBundle(int id);

  Future<void> toggleBundleActive(int id, bool isActive);

  Future<String?> uploadBundleImage(int bundleId, File imageFile);

  Future<void> deleteBundleImage(int bundleId);
}

/// Concrete implementation of [MenuRepository] that communicates with the
/// Catalog API via [ApiClient].
class ApiMenuRepository implements MenuRepository {
  final ApiClient _api;

  ApiMenuRepository(this._api);

  @override
  Future<({List<MenuItem> items, List<MenuCategory> categories})>
      loadMenu() async {
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

    return (items: items, categories: categories);
  }

  @override
  Future<void> updateItemAvailability(int itemId, bool isAvailable) async {
    await _api.patch('items/$itemId/availability', data: {
      'isAvailable': isAvailable,
    });
  }

  @override
  Future<void> createItem(MenuItem item) async {
    await _api.post('items', data: item.toJson());
  }

  @override
  Future<void> updateItem(MenuItem item) async {
    await _api.put('items/${item.id}', data: item.toJson());
  }

  @override
  Future<void> deleteItem(int itemId) async {
    await _api.delete('items/$itemId');
  }

  @override
  Future<void> createCategory(LocalizedText name) async {
    await _api.post('categories', data: {
      'name': name.toJson(),
    });
  }

  @override
  Future<void> updateCategory(int id, LocalizedText name) async {
    await _api.put('categories/$id', data: {
      'name': name.toJson(),
    });
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _api.delete('categories/$id');
  }

  @override
  Future<String?> uploadItemImage(int itemId, File imageFile) async {
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
  }

  @override
  Future<void> deleteItemImage(int itemId) async {
    await _api.delete('items/$itemId/pic');
  }

  @override
  Future<ItemCustomization?> createCustomization(
      int itemId, ItemCustomization customization) async {
    final response = await _api.post(
      'items/$itemId/customizations',
      data: customization.toJson(),
    );
    return ItemCustomization.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ItemCustomization?> updateCustomization(
      int itemId, int customizationId, ItemCustomization customization) async {
    final response = await _api.put(
      'items/$itemId/customizations/$customizationId',
      data: customization.toJson(),
    );
    return ItemCustomization.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCustomization(int itemId, int customizationId) async {
    await _api.delete('items/$itemId/customizations/$customizationId');
  }

  @override
  Future<void> saveReorderedCategories(
      List<Map<String, dynamic>> reorderItems) async {
    await _api.put('categories/reorder', data: {'items': reorderItems});
  }

  @override
  Future<void> saveReorderedItems(
      List<Map<String, dynamic>> reorderItems) async {
    await _api.put('items/reorder', data: {'items': reorderItems});
  }

  @override
  Future<void> setItemOffer(int itemId, bool isOnOffer, double? offerPrice) async {
    await _api.patch('items/$itemId/offer', data: {
      'isOnOffer': isOnOffer,
      'offerPrice': offerPrice,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> loadBundles({bool includeInactive = true}) async {
    final response = await _api.get('bundles', queryParameters: {
      'includeInactive': includeInactive,
    });
    return (response.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createBundle(Map<String, dynamic> data) async {
    final response = await _api.post('bundles', data: data);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateBundle(int id, Map<String, dynamic> data) async {
    final response = await _api.put('bundles/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> deleteBundle(int id) async {
    await _api.delete('bundles/$id');
  }

  @override
  Future<void> toggleBundleActive(int id, bool isActive) async {
    await _api.patch('bundles/$id/active', data: {
      'isActive': isActive,
    });
  }

  @override
  Future<String?> uploadBundleImage(int bundleId, File imageFile) async {
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
      'bundles/$bundleId/pic',
      data: formData,
    );

    return response.data as String?;
  }

  @override
  Future<void> deleteBundleImage(int bundleId) async {
    await _api.delete('bundles/$bundleId/pic');
  }
}

/// Provider for the menu repository.
final menuRepositoryProvider = Provider<MenuRepository>(
    (ref) => ApiMenuRepository(ref.read(catalogApiProvider)));
