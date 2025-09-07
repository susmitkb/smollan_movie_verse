import 'package:hive/hive.dart';
import 'package:smollan_movie_verse/models/tvShow_adapter.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class HiveService {
  static const String favoritesBox = 'favorites';
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // REMOVED: Adapter registration (already done in main.dart)
      // Just open the box - adapter is already registered
      await Hive.openBox<TVShow>(favoritesBox);
      _isInitialized = true;

      print('✅ HiveService initialized successfully');

      // Debug: Check if box exists and has data
      final box = Hive.box<TVShow>(favoritesBox);
      print('📦 Favorites box contains ${box.length} items');

    } catch (e) {
      print('❌ Error initializing HiveService: $e');
      // Re-throw to handle in main.dart
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
    print('💾 Saved "${show.name}" to favorites (ID: ${show.id})');
  }

  static void removeFromFavorites(int showId) {
    final box = getFavoritesBox();
    box.delete(showId);
    print('🗑️ Removed show ID $showId from favorites');
  }

  static bool isFavorite(int showId) {
    final box = getFavoritesBox();
    return box.containsKey(showId);
  }

  static List<TVShow> getFavorites() {
    final box = getFavoritesBox();
    final favorites = box.values.toList();
    print('📋 Retrieved ${favorites.length} favorites from Hive');
    return favorites;
  }

  // Add a method to check if Hive is ready
  static bool get isReady => _isInitialized;

  // Add debug method to check storage
  static void debugStorage() {
    if (!_isInitialized) return;

    final box = getFavoritesBox();
    print('=== HIVE DEBUG INFO ===');
    print('Box name: $favoritesBox');
    print('Total items: ${box.length}');
    print('Keys: ${box.keys.toList()}');
    print('=======================');
  }
}