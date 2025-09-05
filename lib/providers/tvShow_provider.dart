import 'package:flutter/foundation.dart';
import 'package:smollan_movie_verse/constants/enums.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/repository/tvShow_repo.dart';

class TVShowProvider with ChangeNotifier {
  final TVShowRepository _repository;

  TVShowProvider(this._repository);

  // Home screen states
  UIState _state = UIState.loading;
  UIState get state => _state;

  List<TVShow> _shows = [];
  List<TVShow> get shows => _shows;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  ShowFilter _currentFilter = ShowFilter.trending;
  ShowFilter get currentFilter => _currentFilter;

  // Search screen states
  UIState _searchState = UIState.empty;
  UIState get searchState => _searchState;

  List<TVShow> _searchResults = [];
  List<TVShow> get searchResults => _searchResults;

  Future<void> fetchShows(ShowFilter filter) async {
    _currentFilter = filter;
    _state = UIState.loading;
    notifyListeners();

    try {
      switch (filter) {
        case ShowFilter.trending:
          _shows = await _repository.getTrendingShows();
          break;
        case ShowFilter.popular:
          _shows = await _repository.getPopularShows();
          break;
        case ShowFilter.upcoming:
          _shows = await _repository.getUpcomingShows();
          break;
      }

      _state = _shows.isEmpty ? UIState.empty : UIState.success;
    } catch (e) {
      _state = UIState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> searchShows(String query) async {
    _searchState = UIState.loading;
    notifyListeners();

    try {
      _searchResults = await _repository.searchShows(query);
      _searchState = _searchResults.isEmpty ? UIState.empty : UIState.success;
    } catch (e) {
      _searchState = UIState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchResults.clear();
    _searchState = UIState.empty;
    notifyListeners();
  }
}