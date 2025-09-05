import 'package:flutter/foundation.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/services/hive_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<TVShow> _favorites = [];

  List<TVShow> get favorites => _favorites;

  FavoritesProvider() {
    _loadFavorites();
  }

  void _loadFavorites() {
    _favorites = HiveService.getFavorites();
    notifyListeners();
  }

  void refreshFavorites() {
    _loadFavorites();
  }

  void addToFavorites(TVShow show) {
    HiveService.addToFavorites(show);
    _loadFavorites();
  }

  void removeFromFavorites(int showId) {
    HiveService.removeFromFavorites(showId);
    _loadFavorites();
  }

  bool isFavorite(int showId) {
    return HiveService.isFavorite(showId);
  }

  void toggleFavorite(TVShow show) {
    if (isFavorite(show.id)) {
      removeFromFavorites(show.id);
    } else {
      addToFavorites(show);
    }
  }
}