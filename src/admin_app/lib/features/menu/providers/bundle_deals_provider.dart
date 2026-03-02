import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bundle_deal.dart';
import '../services/menu_service.dart';

class BundleDealsState {
  final bool isLoading;
  final List<BundleDeal> bundles;

  const BundleDealsState({
    this.isLoading = false,
    this.bundles = const [],
  });

  BundleDealsState copyWith({
    bool? isLoading,
    List<BundleDeal>? bundles,
  }) {
    return BundleDealsState(
      isLoading: isLoading ?? this.isLoading,
      bundles: bundles ?? this.bundles,
    );
  }
}

class BundleDealsNotifier extends Notifier<BundleDealsState> {
  late MenuRepository _repository;

  @override
  BundleDealsState build() {
    _repository = ref.read(menuRepositoryProvider);
    // Auto-load bundles when the provider is first read
    Future.microtask(() => loadBundles());
    return const BundleDealsState(isLoading: true);
  }

  Future<void> loadBundles() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.loadBundles(includeInactive: true);
      final bundles = data.map((e) => BundleDeal.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, bundles: bundles);
    } catch (e) {
      debugPrint('Failed to load bundles: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Creates a bundle and returns the new bundle's ID, or null on failure.
  Future<int?> createBundle(BundleDeal bundle) async {
    try {
      final data = await _repository.createBundle(bundle.toRequestJson());
      await loadBundles();
      return data['id'] as int?;
    } catch (e) {
      debugPrint('Failed to create bundle: $e');
      return null;
    }
  }

  Future<bool> updateBundle(int id, BundleDeal bundle) async {
    try {
      await _repository.updateBundle(id, bundle.toRequestJson());
      await loadBundles();
      return true;
    } catch (e) {
      debugPrint('Failed to update bundle: $e');
      return false;
    }
  }

  Future<bool> deleteBundle(int id) async {
    try {
      await _repository.deleteBundle(id);
      await loadBundles();
      return true;
    } catch (e) {
      debugPrint('Failed to delete bundle: $e');
      return false;
    }
  }

  Future<bool> uploadBundleImage(int bundleId, File imageFile) async {
    try {
      await _repository.uploadBundleImage(bundleId, imageFile);
      await loadBundles();
      return true;
    } catch (e) {
      debugPrint('Failed to upload bundle image: $e');
      return false;
    }
  }

  Future<bool> deleteBundleImage(int bundleId) async {
    try {
      await _repository.deleteBundleImage(bundleId);
      await loadBundles();
      return true;
    } catch (e) {
      debugPrint('Failed to delete bundle image: $e');
      return false;
    }
  }

  Future<bool> toggleActive(int id, bool isActive) async {
    // Optimistic update
    final previous = state.bundles;
    state = state.copyWith(
      bundles: state.bundles.map((b) {
        if (b.id == id) {
          return BundleDeal(
            id: b.id,
            name: b.name,
            description: b.description,
            bundlePrice: b.bundlePrice,
            originalPrice: b.originalPrice,
            pictureUri: b.pictureUri,
            isActive: isActive,
            displayOrder: b.displayOrder,
            items: b.items,
          );
        }
        return b;
      }).toList(),
    );

    try {
      await _repository.toggleBundleActive(id, isActive);
      return true;
    } catch (e) {
      debugPrint('Failed to toggle bundle active: $e');
      state = state.copyWith(bundles: previous);
      return false;
    }
  }
}

final bundleDealsProvider =
    NotifierProvider<BundleDealsNotifier, BundleDealsState>(BundleDealsNotifier.new);
