import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class TVShowRepository {
  static const String baseUrl = 'https://api.tvmaze.com';
  static const int itemsPerPage = 20;

  // Cache for all shows to avoid multiple API calls
  List<TVShow>? _allShowsCache;

  Future<List<TVShow>> _getAllShows() async {
    if (_allShowsCache != null) {
      print('📦 Using cached shows (${_allShowsCache!.length} total)');
      return _allShowsCache!;
    }

    print('🌐 Fetching all shows from API...');
    final response = await http.get(Uri.parse('$baseUrl/shows'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _allShowsCache = data.map((json) => TVShow.fromJson(json)).toList();
      print('✅ Successfully fetched ${_allShowsCache!.length} shows from API');
      return _allShowsCache!;
    } else {
      print('❌ Failed to load shows: HTTP ${response.statusCode}');
      throw Exception('Failed to load shows');
    }
  }

  Future<List<TVShow>> getTrendingShows({int page = 1}) async {
    print('📺 Getting trending shows - Page $page');
    final allShows = await _getAllShows();

    // Calculate start and end indices for pagination
    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    if (startIndex >= allShows.length) {
      print('⏹️ No more trending shows to load (startIndex: $startIndex, total: ${allShows.length})');
      return [];
    }

    final paginatedShows = allShows.sublist(
      startIndex,
      endIndex < allShows.length ? endIndex : allShows.length,
    );

    print('📊 Trending page $page: Showing ${paginatedShows.length} shows (${startIndex + 1}-${startIndex + paginatedShows.length} of ${allShows.length})');
    return paginatedShows;
  }

  Future<List<TVShow>> getPopularShows({int page = 1}) async {
    print('🔥 Getting popular shows - Page $page');
    final allShows = await _getAllShows();

    // Sort by rating (highest first)
    print('⭐ Sorting shows by rating...');
    allShows.sort((a, b) => b.rating.compareTo(a.rating));

    // Calculate start and end indices for pagination
    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    if (startIndex >= allShows.length) {
      print('⏹️ No more popular shows to load (startIndex: $startIndex, total: ${allShows.length})');
      return [];
    }

    final paginatedShows = allShows.sublist(
      startIndex,
      endIndex < allShows.length ? endIndex : allShows.length,
    );

    print('📊 Popular page $page: Showing ${paginatedShows.length} shows (${startIndex + 1}-${startIndex + paginatedShows.length} of ${allShows.length})');

    // Log top 3 shows for this page (for verification)
    if (paginatedShows.isNotEmpty) {
      print('🏆 Top 3 shows on this page:');
      for (int i = 0; i < (paginatedShows.length > 3 ? 3 : paginatedShows.length); i++) {
        print('   ${i + 1}. ${paginatedShows[i].name} - ⭐ ${paginatedShows[i].rating}');
      }
    }

    return paginatedShows;
  }

  Future<List<TVShow>> getUpcomingShows({int page = 1}) async {
    print('📅 Getting upcoming shows - Page $page');
    final response = await http.get(Uri.parse('$baseUrl/schedule'));

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

      print('✅ Found ${allUpcomingShows.length} unique upcoming shows');

      // Calculate start and end indices for pagination
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex >= allUpcomingShows.length) {
        print('⏹️ No more upcoming shows to load (startIndex: $startIndex, total: ${allUpcomingShows.length})');
        return [];
      }

      final paginatedShows = allUpcomingShows.sublist(
        startIndex,
        endIndex < allUpcomingShows.length ? endIndex : allUpcomingShows.length,
      );

      print('📊 Upcoming page $page: Showing ${paginatedShows.length} shows (${startIndex + 1}-${startIndex + paginatedShows.length} of ${allUpcomingShows.length})');
      return paginatedShows;
    } else {
      print('❌ Failed to load upcoming shows: HTTP ${response.statusCode}');
      throw Exception('Failed to load upcoming shows');
    }
  }

  Future<List<TVShow>> searchShows(String query, {int page = 1}) async {
    print('🔍 Searching shows for "$query" - Page $page');
    final response = await http.get(Uri.parse('$baseUrl/search/shows?q=$query'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final allSearchResults = data.map((item) => TVShow.fromJson(item['show'])).toList();

      print('✅ Found ${allSearchResults.length} search results for "$query"');

      // Calculate start and end indices for pagination
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex >= allSearchResults.length) {
        print('⏹️ No more search results to load for "$query" (startIndex: $startIndex, total: ${allSearchResults.length})');
        return [];
      }

      final paginatedResults = allSearchResults.sublist(
        startIndex,
        endIndex < allSearchResults.length ? endIndex : allSearchResults.length,
      );

      print('📊 Search page $page for "$query": Showing ${paginatedResults.length} results (${startIndex + 1}-${startIndex + paginatedResults.length} of ${allSearchResults.length})');
      return paginatedResults;
    } else {
      print('❌ Failed to search shows: HTTP ${response.statusCode}');
      throw Exception('Failed to search shows');
    }
  }

  // Clear cache when needed (e.g., when user pulls to refresh)
  void clearCache() {
    print('🗑️ Clearing shows cache');
    _allShowsCache = null;
  }
}