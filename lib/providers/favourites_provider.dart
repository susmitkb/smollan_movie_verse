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
    stalePeriod: const Duration(days: 365), // Keep cached images for 1 year
    maxNrOfCacheObjects: 500, // Store up to 500 images
  ));
}

class FavoritesProvider with ChangeNotifier {
  List<TVShow> _favorites = [];

  List<TVShow> get favorites => _favorites;

  FavoritesProvider() {
    _loadFavorites();
  }

  void _loadFavorites() {
    _favorites = HiveService.getFavorites();
    notifyListeners();
    _preCacheAllFavoriteImages(); // Pre-cache images when favorites are loaded
  }

  void refreshFavorites() {
    _loadFavorites();
  }

  bool isFavorite(int showId) {
    return HiveService.isFavorite(showId); // Use HiveService's method
  }

  void toggleFavorite(TVShow show) {
    if (isFavorite(show.id)) {
      removeFromFavorites(show.id);
    } else {
      addToFavorites(show);
    }
  }

  void addToFavorites(TVShow show) {
    if (!isFavorite(show.id)) {
      HiveService.addToFavorites(show); // Use HiveService to save
      _favorites.add(show); // Update local list
      preCacheFavoriteImage(show); // Pre-cache the image
      notifyListeners();
    }
  }

  void removeFromFavorites(int showId) {
    HiveService.removeFromFavorites(showId); // Use HiveService to remove
    _favorites.removeWhere((show) => show.id == showId); // Update local list
    notifyListeners();
  }

  void preCacheFavoriteImage(TVShow show) {
    if (show.imageUrl != null) {
      // Pre-cache the image for offline access
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
    final box = HiveService.getFavoritesBox();
    box.clear(); // Clear all data from the Hive box
    _favorites.clear(); // Clear local list
    notifyListeners();
  }
}