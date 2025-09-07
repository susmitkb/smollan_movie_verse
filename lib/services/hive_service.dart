import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:smollan_movie_verse/models/tvShow_adapter.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class HiveService {
  static const String favoritesBox = 'favorites';
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox<TVShow>(favoritesBox);
      _isInitialized = true;

      log('✅ HiveService initialized successfully', name: 'HiveService');

      final box = Hive.box<TVShow>(favoritesBox);
      log('📦 Favorites box contains ${box.length} items', name: 'HiveService');

    } catch (e) {
      log('❌ Error initializing HiveService: $e', name: 'HiveService');
      throw e;
    }
  }

  static Box<TVShow> getFavoritesBox() {
    if (!_isInitialized) {
      throw Exception('HiveService not initialized. Call HiveService.init() first.');
    }
    return Hive.box<TVShow>(favoritesBox);
  }

  static void addToFavorites(TVShow show) {
    final box = getFavoritesBox();
    box.put(show.id, show);
    log('💾 Saved "${show.name}" to favorites (ID: ${show.id})', name: 'HiveService');
  }

  static void removeFromFavorites(int showId) {
    final box = getFavoritesBox();
    box.delete(showId);
    log('🗑️ Removed show ID $showId from favorites', name: 'HiveService');
  }

  static bool isFavorite(int showId) {
    final box = getFavoritesBox();
    return box.containsKey(showId);
  }

  static List<TVShow> getFavorites() {
    final box = getFavoritesBox();
    final favorites = box.values.toList();
    log('📋 Retrieved ${favorites.length} favorites from Hive', name: 'HiveService');
    return favorites;
  }

  static bool get isReady => _isInitialized;

  static void debugStorage() {
    if (!_isInitialized) return;

    final box = getFavoritesBox();
    log('=== HIVE DEBUG INFO ===', name: 'HiveService');
    log('Box name: $favoritesBox', name: 'HiveService');
    log('Total items: ${box.length}', name: 'HiveService');
    log('Keys: ${box.keys.toList()}', name: 'HiveService');
    log('=======================', name: 'HiveService');
  }
}