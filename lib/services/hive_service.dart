import 'package:hive/hive.dart';
import 'package:smollan_movie_verse/models/tvShow_adapter.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class HiveService {
  static const String favoritesBox = 'favorites';

  static Future<void> init() async {
    // Register the manual adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TVShowAdapter());
    }
    await Hive.openBox<TVShow>(favoritesBox);
  }

  static Box<TVShow> getFavoritesBox() {
    return Hive.box<TVShow>(favoritesBox);
  }

  static void addToFavorites(TVShow show) {
    final box = getFavoritesBox();
    box.put(show.id, show);
  }

  static void removeFromFavorites(int showId) {
    final box = getFavoritesBox();
    box.delete(showId);
  }

  static bool isFavorite(int showId) {
    final box = getFavoritesBox();
    return box.containsKey(showId);
  }

  static List<TVShow> getFavorites() {
    final box = getFavoritesBox();
    return box.values.toList();
  }
}