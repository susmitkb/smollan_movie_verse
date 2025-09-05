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
      if (!_hasMoreShows || _isLoadingMore) {
        print('🛑 Skipping loadMore - hasMore: $_hasMoreShows, isLoading: $_isLoadingMore');
        return;
      }
      _isLoadingMore = true;
      _currentPage++;
      print('⬇️ Loading more shows for $filter - Page $_currentPage');
    } else {
      _currentFilter = filter;
      _currentPage = 1;
      _hasMoreShows = true;
      _state = UIState.loading;
      print('🔄 Loading initial shows for $filter - Page 1');
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
        print('📥 Adding ${newShows.length} shows to existing ${_shows.length}');
        _shows.addAll(newShows);
      } else {
        print('📥 Setting ${newShows.length} shows');
        _shows = newShows;
      }

      // Check if we have more shows to load
      _hasMoreShows = newShows.length >= 20;
      print(_hasMoreShows ? "✅ More shows available" : "⏹️ No more shows available");

      _state = _shows.isEmpty ? UIState.empty : UIState.success;
      print('📊 Total shows now: ${_shows.length}, State: $_state');
    } catch (e) {
      if (loadMore) {
        _currentPage--; // Revert page increment on error
        print('↩️ Reverting to page $_currentPage due to error');
      }
      _state = UIState.error;
      _errorMessage = e.toString();
      print('❌ Error loading shows: $e');
    } finally {
      _isLoadingMore = false;
    }

    notifyListeners();
  }

  Future<void> searchShows(String query) async {
    print('🔍 Starting search for: "$query"');
    _searchState = UIState.loading;
    notifyListeners();

    try {
      _searchResults = await _repository.searchShows(query);
      _searchState = _searchResults.isEmpty ? UIState.empty : UIState.success;
      print('✅ Search completed: ${_searchResults.length} results found');
    } catch (e) {
      _searchState = UIState.error;
      _errorMessage = e.toString();
      print('❌ Search error: $e');
    }

    notifyListeners();
  }

  void clearSearch() {
    print('🧹 Clearing search results');
    _searchResults.clear();
    _searchState = UIState.empty;
    notifyListeners();
  }
}