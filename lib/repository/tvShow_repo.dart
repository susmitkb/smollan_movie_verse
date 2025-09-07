import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class TVShowException implements Exception {
  final String message;
  final bool isNetworkError;

  TVShowException(this.message, {this.isNetworkError = false});

  @override
  String toString() => message;
}

class TVShowRepository {
  static const String baseUrl = 'https://api.tvmaze.com';
  static const int itemsPerPage = 20;
  List<TVShow>? _allShowsCache;

  Future<List<TVShow>> _getAllShows() async {
    if (_allShowsCache != null) {
      developer.log('📦 Using cached all shows (${_allShowsCache!.length} items)',
          name: 'TVShowRepository');
      return _allShowsCache!;
    }

    developer.log('🌐 Fetching all shows from API', name: 'TVShowRepository');

    try {
      final response = await http.get(Uri.parse('$baseUrl/shows'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allShowsCache = data.map((json) => TVShow.fromJson(json)).toList();

        developer.log('✅ Successfully loaded ${_allShowsCache!.length} shows',
            name: 'TVShowRepository');
        return _allShowsCache!;
      } else {
        developer.log('❌ HTTP Error ${response.statusCode} while loading all shows',
            name: 'TVShowRepository', error: response.body);
        throw TVShowException('Failed to load shows: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      developer.log('🌐 Network error while loading all shows',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Network error: ${e.message}', isNetworkError: true);
    } on FormatException catch (e) {
      developer.log('📄 Format error while parsing all shows',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Data format error: ${e.message}');
    } on Exception catch (e) {
      developer.log('⚡ Unexpected error while loading all shows',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<TVShow>> getTrendingShows({int page = 1}) async {
    developer.log('🎬 Getting TRENDING shows - Page $page', name: 'TVShowRepository');

    try {
      final allShows = await _getAllShows();
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex >= allShows.length) {
        developer.log('📭 No more trending shows available', name: 'TVShowRepository');
        return [];
      }

      final trendingShows = allShows.sublist(
        startIndex,
        endIndex < allShows.length ? endIndex : allShows.length,
      );

      developer.log('📊 Trending page $page: ${trendingShows.length} shows (${startIndex + 1}-${endIndex.clamp(1, allShows.length)} of ${allShows.length})',
          name: 'TVShowRepository');

      return trendingShows;
    } catch (e) {
      developer.log('❌ Error getting trending shows page $page',
          name: 'TVShowRepository', error: e);
      rethrow;
    }
  }

  Future<List<TVShow>> getPopularShows({int page = 1}) async {
    developer.log('🔥 Getting POPULAR shows - Page $page', name: 'TVShowRepository');

    try {
      final allShows = await _getAllShows();

      // Create a copy to avoid modifying the cached list
      final sortedShows = List<TVShow>.from(allShows);
      sortedShows.sort((a, b) => b.rating.compareTo(a.rating));

      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex >= sortedShows.length) {
        developer.log('📭 No more popular shows available', name: 'TVShowRepository');
        return [];
      }

      final popularShows = sortedShows.sublist(
        startIndex,
        endIndex < sortedShows.length ? endIndex : sortedShows.length,
      );

      developer.log('📊 Popular page $page: ${popularShows.length} shows (sorted by rating)',
          name: 'TVShowRepository');
      developer.log('⭐ Top 3 popular shows ratings: ${popularShows.take(3).map((s) => s.rating).toList()}',
          name: 'TVShowRepository');

      return popularShows;
    } catch (e) {
      developer.log('❌ Error getting popular shows page $page',
          name: 'TVShowRepository', error: e);
      rethrow;
    }
  }

  Future<List<TVShow>> getUpcomingShows({int page = 1}) async {
    developer.log('📅 Getting UPCOMING shows - Page $page', name: 'TVShowRepository');

    try {
      final response = await http.get(Uri.parse('$baseUrl/schedule'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final showIds = <int>{};
        final List<TVShow> allUpcomingShows = [];

        for (var item in data) {
          final show = item['show'];
          final showId = show['id'];

          if (!showIds.contains(showId)) {
            showIds.add(showId);
            allUpcomingShows.add(TVShow.fromJson(show));
          }
        }

        final startIndex = (page - 1) * itemsPerPage;
        final endIndex = startIndex + itemsPerPage;

        if (startIndex >= allUpcomingShows.length) {
          developer.log('📭 No more upcoming shows available', name: 'TVShowRepository');
          return [];
        }

        final upcomingShows = allUpcomingShows.sublist(
          startIndex,
          endIndex < allUpcomingShows.length ? endIndex : allUpcomingShows.length,
        );

        developer.log('📊 Upcoming page $page: ${upcomingShows.length} shows (unique: ${showIds.length})',
            name: 'TVShowRepository');

        return upcomingShows;
      } else {
        developer.log('❌ HTTP Error ${response.statusCode} while loading upcoming shows',
            name: 'TVShowRepository', error: response.body);
        throw TVShowException('Failed to load upcoming shows: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      developer.log('🌐 Network error while loading upcoming shows',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Network error: ${e.message}', isNetworkError: true);
    } on FormatException catch (e) {
      developer.log('📄 Format error while parsing upcoming shows',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Data format error: ${e.message}');
    } on Exception catch (e) {
      developer.log('⚡ Unexpected error while loading upcoming shows',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<TVShow>> searchShows(String query, {int page = 1}) async {
    developer.log('🔍 SEARCHING for: "$query" - Page $page', name: 'TVShowRepository');

    try {
      final response = await http.get(Uri.parse('$baseUrl/search/shows?q=$query'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allSearchResults = data.map((item) => TVShow.fromJson(item['show'])).toList();

        final startIndex = (page - 1) * itemsPerPage;
        final endIndex = startIndex + itemsPerPage;

        if (startIndex >= allSearchResults.length) {
          developer.log('📭 No more search results for "$query"', name: 'TVShowRepository');
          return [];
        }

        final searchResults = allSearchResults.sublist(
          startIndex,
          endIndex < allSearchResults.length ? endIndex : allSearchResults.length,
        );

        developer.log('✅ Search "$query" page $page: ${searchResults.length} results (total: ${allSearchResults.length})',
            name: 'TVShowRepository');

        return searchResults;
      } else {
        developer.log('❌ HTTP Error ${response.statusCode} while searching "$query"',
            name: 'TVShowRepository', error: response.body);
        throw TVShowException('Failed to search shows: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      developer.log('🌐 Network error while searching "$query"',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Network error: ${e.message}', isNetworkError: true);
    } on FormatException catch (e) {
      developer.log('📄 Format error while parsing search results for "$query"',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Data format error: ${e.message}');
    } on Exception catch (e) {
      developer.log('⚡ Unexpected error while searching "$query"',
          name: 'TVShowRepository', error: e);
      throw TVShowException('Unexpected error: ${e.toString()}');
    }
  }

  void clearCache() {
    developer.log('🧹 Clearing TV show cache', name: 'TVShowRepository');
    _allShowsCache = null;
  }
  void debugCache() {
    if (_allShowsCache == null) {
      developer.log('📦 Cache: EMPTY', name: 'TVShowRepository');
    } else {
      developer.log('📦 Cache: ${_allShowsCache!.length} shows', name: 'TVShowRepository');
      developer.log('⭐ Top 5 cached shows: ${_allShowsCache!.take(5).map((s) => '${s.name} (${s.rating})').toList()}',
          name: 'TVShowRepository');
    }
  }
}