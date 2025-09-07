import 'package:flutter/foundation.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/services/hive_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Create a custom cache manager with persistent storage
class TVShowCacheManager extends CacheManager {
  static const key = 'tvShowCache';

  static final TVShowCacheManager _instance = TVShowCacheManager._();
  factory TVShowCacheManager() => _instance;

  TVShowCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 500,
  ));
}

class FavoritesProvider with ChangeNotifier {
  List<TVShow> _favorites = [];
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false;

  List<TVShow> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isReady => _hasInitialized && !_isLoading;

  FavoritesProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_hasInitialized) return;
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure Hive is initialized
      if (!HiveService.isReady) {
        await HiveService.init();
      }

      _favorites = HiveService.getFavorites();

      if (kDebugMode) {
        print('✅ Loaded ${_favorites.length} favorites from Hive');
      }

      await _preCacheAllFavoriteImages();
      _hasInitialized = true;

    } catch (e, stackTrace) {
      _error = 'Failed to load favorites: ${e.toString()}';
      if (kDebugMode) {
        print('❌ Error loading favorites: $e');
        print('Stack trace: $stackTrace');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  bool isFavorite(int showId) {
    if (!HiveService.isReady) {
      if (kDebugMode) {
        print('⚠️ HiveService not ready when checking favorite status');
      }
      return false;
    }

    try {
      return HiveService.isFavorite(showId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking favorite status: $e');
      }
      return false;
    }
  }

  Future<void> toggleFavorite(TVShow show) async {
    try {
      if (isFavorite(show.id)) {
        await removeFromFavorites(show.id);
      } else {
        await addToFavorites(show);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling favorite: $e');
      }
      rethrow;
    }
  }

  Future<void> addToFavorites(TVShow show) async {
    if (!HiveService.isReady) {
      throw Exception('HiveService not ready, cannot add favorite');
    }

    if (!isFavorite(show.id)) {
      try {
        HiveService.addToFavorites(show);
        _favorites.add(show);
        await _preCacheFavoriteImage(show);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error adding to favorites: $e');
        }
        rethrow;
      }
    }
  }

  Future<void> removeFromFavorites(int showId) async {
    if (!HiveService.isReady) {
      throw Exception('HiveService not ready, cannot remove favorite');
    }

    try {
      HiveService.removeFromFavorites(showId);
      _favorites.removeWhere((show) => show.id == showId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing from favorites: $e');
      }
      rethrow;
    }
  }

  Future<void> _preCacheFavoriteImage(TVShow show) async {
    if (show.imageUrl != null && show.imageUrl!.isNotEmpty) {
      try {
        await TVShowCacheManager().downloadFile(show.imageUrl!);
        if (kDebugMode) {
          print('✅ Pre-cached image for ${show.name}');
        }
      } catch (error) {
        if (kDebugMode) {
          print('❌ Failed to pre-cache image for ${show.name}: $error');
        }
        // Don't rethrow - image caching is non-critical
      }
    }
  }

  Future<void> _preCacheAllFavoriteImages() async {
    final futures = <Future>[];

    for (final show in _favorites) {
      futures.add(_preCacheFavoriteImage(show));
    }

    await Future.wait(futures, eagerError: false);
  }

  Future<void> clearAllFavorites() async {
    if (!HiveService.isReady) {
      throw Exception('HiveService not ready, cannot clear favorites');
    }

    try {
      final box = HiveService.getFavoritesBox();
      await box.clear();
      _favorites.clear();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing favorites: $e');
      }
      rethrow;
    }
  }

  // Utility method to clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method to retry failed operations
  Future<void> retry() async {
    if (hasError) {
      await _loadFavorites();
    }
  }
}