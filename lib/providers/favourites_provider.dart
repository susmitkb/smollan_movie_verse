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

  List<TVShow> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FavoritesProvider() {
    _loadFavorites();
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

      _preCacheAllFavoriteImages();
    } catch (e) {
      _error = 'Failed to load favorites: $e';
      if (kDebugMode) {
        print('❌ Error loading favorites: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FIXED: Changed to async and added await
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  bool isFavorite(int showId) {
    if (!HiveService.isReady) return false;
    return HiveService.isFavorite(showId);
  }

  void toggleFavorite(TVShow show) {
    if (isFavorite(show.id)) {
      removeFromFavorites(show.id);
    } else {
      addToFavorites(show);
    }
  }

  void addToFavorites(TVShow show) {
    if (!HiveService.isReady) {
      if (kDebugMode) {
        print('❌ HiveService not ready, cannot add favorite');
      }
      return;
    }

    if (!isFavorite(show.id)) {
      HiveService.addToFavorites(show);
      _favorites.add(show);
      preCacheFavoriteImage(show);
      notifyListeners();
    }
  }

  void removeFromFavorites(int showId) {
    if (!HiveService.isReady) {
      if (kDebugMode) {
        print('❌ HiveService not ready, cannot remove favorite');
      }
      return;
    }

    HiveService.removeFromFavorites(showId);
    _favorites.removeWhere((show) => show.id == showId);
    notifyListeners();
  }

  void preCacheFavoriteImage(TVShow show) {
    if (show.imageUrl != null) {
      TVShowCacheManager().downloadFile(show.imageUrl!).then((file) {
        if (kDebugMode) {
          print('✅ Pre-cached image for ${show.name}');
        }
      }).catchError((error) {
        if (kDebugMode) {
          print('❌ Failed to pre-cache image for ${show.name}: $error');
        }
      });
    }
  }

  void _preCacheAllFavoriteImages() {
    for (final show in _favorites) {
      preCacheFavoriteImage(show);
    }
  }

  void clearAllFavorites() {
    if (!HiveService.isReady) return;

    final box = HiveService.getFavoritesBox();
    box.clear();
    _favorites.clear();
    notifyListeners();
  }
}