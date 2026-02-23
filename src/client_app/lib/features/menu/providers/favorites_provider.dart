import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/menu_service.dart';

/// State for favorites
class FavoritesState {
  final Set<int> favoriteIds;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favoriteIds = const {},
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    Set<int>? favoriteIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing favorites
class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() {
    // Load favorites when the notifier is created
    _loadFavorites();
    return const FavoritesState(isLoading: true);
  }

  MenuRepository get _service => ref.read(menuRepositoryProvider);

  /// Load favorites from the backend
  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await _service.getFavorites();
      state = state.copyWith(
        favoriteIds: favoriteIds.toSet(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Reload favorites from the backend
  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadFavorites();
  }

  /// Toggle favorite status for an item
  Future<void> toggleFavorite(int itemId) async {
    final isFavorite = state.favoriteIds.contains(itemId);

    // Optimistic update
    final newFavorites = Set<int>.from(state.favoriteIds);
    if (isFavorite) {
      newFavorites.remove(itemId);
    } else {
      newFavorites.add(itemId);
    }
    state = state.copyWith(favoriteIds: newFavorites);

    try {
      if (isFavorite) {
        await _service.removeFavorite(itemId);
      } else {
        await _service.addFavorite(itemId);
      }
    } catch (e) {
      // Revert on error
      final revertedFavorites = Set<int>.from(state.favoriteIds);
      if (isFavorite) {
        revertedFavorites.add(itemId);
      } else {
        revertedFavorites.remove(itemId);
      }
      state = state.copyWith(
        favoriteIds: revertedFavorites,
        error: e.toString(),
      );
    }
  }

  /// Check if an item is a favorite
  bool isFavorite(int itemId) => state.favoriteIds.contains(itemId);
}

/// Provider for favorites
final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);
