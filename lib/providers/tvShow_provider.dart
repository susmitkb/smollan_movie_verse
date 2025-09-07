import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:smollan_movie_verse/constants/enums.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/repository/tvShow_repo.dart';

class TVShowProvider with ChangeNotifier {
  final TVShowRepository _repository;
  bool get isLoadingMore => _isLoadingMore;

  TVShowProvider(this._repository);

  final Map<ShowFilter, List<TVShow>> _showsCache = {
    ShowFilter.trending: [],
    ShowFilter.popular: [],
    ShowFilter.upcoming: [],
  };

  final Map<ShowFilter, int> _pages = {
    ShowFilter.trending: 0,
    ShowFilter.popular: 0,
    ShowFilter.upcoming: 0,
  };

  final Map<ShowFilter, bool> _hasMore = {
    ShowFilter.trending: true,
    ShowFilter.popular: true,
    ShowFilter.upcoming: true,
  };

  final Map<ShowFilter, UIState> _states = {
    ShowFilter.trending: UIState.loading,
    ShowFilter.popular: UIState.loading,
    ShowFilter.upcoming: UIState.loading,
  };

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  ShowFilter _currentFilter = ShowFilter.trending;
  ShowFilter get currentFilter => _currentFilter;

  bool _isLoadingMore = false;

  UIState get state => _states[_currentFilter] ?? UIState.loading;
  List<TVShow> get shows => _showsCache[_currentFilter] ?? [];
  bool get hasMoreShows => _hasMore[_currentFilter] ?? false;

  Future<void> fetchShows(ShowFilter filter, {bool loadMore = false}) async {
    log('🎬 fetchShows called - Filter: $filter, LoadMore: $loadMore', name: 'TVShowProvider');

    if (loadMore) {
      if (!_hasMore[filter]! || _isLoadingMore) {
        log('⏩ Skipping load more - hasMore: ${_hasMore[filter]}, isLoadingMore: $_isLoadingMore', name: 'TVShowProvider');
        return;
      }
      _isLoadingMore = true;
      _pages[filter] = (_pages[filter]! + 1);
      log('📄 Loading page ${_pages[filter]} for $filter', name: 'TVShowProvider');
    } else {
      _currentFilter = filter;
      if (_showsCache[filter]!.isEmpty) {
        _pages[filter] = 1;
        _states[filter] = UIState.loading;
        log('🔄 First load for $filter', name: 'TVShowProvider');
        notifyListeners();
      } else {
        log('📊 Using cached data for $filter (${_showsCache[filter]!.length} items)', name: 'TVShowProvider');
        notifyListeners();
        return;
      }
    }

    try {
      List<TVShow> newShows;
      switch (filter) {
        case ShowFilter.trending:
          newShows = await _repository.getTrendingShows(page: _pages[filter]!);
          break;
        case ShowFilter.popular:
          newShows = await _repository.getPopularShows(page: _pages[filter]!);
          break;
        case ShowFilter.upcoming:
          newShows = await _repository.getUpcomingShows(page: _pages[filter]!);
          break;
      }

      if (loadMore) {
        _showsCache[filter]!.addAll(newShows);
        log('📈 Added ${newShows.length} shows to $filter cache (total: ${_showsCache[filter]!.length})', name: 'TVShowProvider');
      } else {
        _showsCache[filter] = newShows;
        log('💾 Cached ${newShows.length} shows for $filter', name: 'TVShowProvider');
      }

      _hasMore[filter] = newShows.isNotEmpty;
      _states[filter] = _showsCache[filter]!.isEmpty ? UIState.empty : UIState.success;

      log('✅ $filter fetch successful - Total: ${_showsCache[filter]!.length}, HasMore: ${_hasMore[filter]}', name: 'TVShowProvider');

    } catch (e) {
      if (loadMore) {
        _pages[filter] = (_pages[filter]! - 1).clamp(1, 9999);
        log('↩️ Reverted page to ${_pages[filter]} due to error', name: 'TVShowProvider');
      }
      _states[filter] = UIState.error;
      _errorMessage = e.toString();
      log('❌ Error fetching $filter: $e', name: 'TVShowProvider');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
      log('📢 Notified listeners for $filter', name: 'TVShowProvider');
    }
  }

  // Search functionality remains the same
  UIState _searchState = UIState.empty;
  UIState get searchState => _searchState;

  List<TVShow> _searchResults = [];
  List<TVShow> get searchResults => _searchResults;

  Future<void> searchShows(String query) async {
    log('🔎 Search initiated: "$query"', name: 'TVShowProvider');
    _searchState = UIState.loading;
    if (_searchResults.isNotEmpty) notifyListeners();

    try {
      _searchResults = await _repository.searchShows(query);
      _searchState = _searchResults.isEmpty ? UIState.empty : UIState.success;
      log('✅ Search completed: ${_searchResults.length} results', name: 'TVShowProvider');
    } catch (e) {
      _searchState = UIState.error;
      _errorMessage = e.toString();
      log('❌ Search failed: $e', name: 'TVShowProvider');
    }

    notifyListeners();
  }

  void clearSearch() {
    log('🧹 Clearing search results', name: 'TVShowProvider');
    _searchResults.clear();
    _searchState = UIState.empty;
    notifyListeners();
  }
}