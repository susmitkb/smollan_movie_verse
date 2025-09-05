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

  // Pagination properties
  int _currentPage = 1;
  bool _hasMoreShows = true;
  bool get hasMoreShows => _hasMoreShows;
  bool _isLoadingMore = false;

  // Search screen states
  UIState _searchState = UIState.empty;
  UIState get searchState => _searchState;

  List<TVShow> _searchResults = [];
  List<TVShow> get searchResults => _searchResults;

  Future<void> fetchShows(ShowFilter filter, {bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMoreShows || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _currentFilter = filter;
      _currentPage = 1;
      _hasMoreShows = true;
      _state = UIState.loading;
    }

    notifyListeners();

    try {
      List<TVShow> newShows;
      switch (filter) {
        case ShowFilter.trending:
          newShows = await _repository.getTrendingShows(page: _currentPage);
          break;
        case ShowFilter.popular:
          newShows = await _repository.getPopularShows(page: _currentPage);
          break;
        case ShowFilter.upcoming:
          newShows = await _repository.getUpcomingShows(page: _currentPage);
          break;
      }

      if (loadMore) {
        _shows.addAll(newShows);
      } else {
        _shows = newShows;
      }

      // Check if we have more shows to load (assuming 20 items per page)
      _hasMoreShows = newShows.length >= 20;

      _state = _shows.isEmpty ? UIState.empty : UIState.success;
    } catch (e) {
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }
      _state = UIState.error;
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
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