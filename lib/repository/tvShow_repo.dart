import 'dart:convert';
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
      return _allShowsCache!;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/shows'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allShowsCache = data.map((json) => TVShow.fromJson(json)).toList();
        return _allShowsCache!;
      } else {
        throw TVShowException('Failed to load shows: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw TVShowException('Network error: ${e.message}', isNetworkError: true);
    } on FormatException catch (e) {
      throw TVShowException('Data format error: ${e.message}');
    } on Exception catch (e) {
      throw TVShowException('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<TVShow>> getTrendingShows({int page = 1}) async {
    try {
      final allShows = await _getAllShows();
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex >= allShows.length) {
        return [];
      }
      return allShows.sublist(
        startIndex,
        endIndex < allShows.length ? endIndex : allShows.length,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TVShow>> getPopularShows({int page = 1}) async {
    try {
      final allShows = await _getAllShows();
      allShows.sort((a, b) => b.rating.compareTo(a.rating));

      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex >= allShows.length) {
        return [];
      }
      return allShows.sublist(
        startIndex,
        endIndex < allShows.length ? endIndex : allShows.length,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TVShow>> getUpcomingShows({int page = 1}) async {
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
          return [];
        }

        return allUpcomingShows.sublist(
          startIndex,
          endIndex < allUpcomingShows.length ? endIndex : allUpcomingShows.length,
        );
      } else {
        throw TVShowException('Failed to load upcoming shows: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw TVShowException('Network error: ${e.message}', isNetworkError: true);
    } on FormatException catch (e) {
      throw TVShowException('Data format error: ${e.message}');
    } on Exception catch (e) {
      throw TVShowException('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<TVShow>> searchShows(String query, {int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search/shows?q=$query'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allSearchResults = data.map((item) => TVShow.fromJson(item['show'])).toList();

        final startIndex = (page - 1) * itemsPerPage;
        final endIndex = startIndex + itemsPerPage;

        if (startIndex >= allSearchResults.length) {
          return [];
        }

        return allSearchResults.sublist(
          startIndex,
          endIndex < allSearchResults.length ? endIndex : allSearchResults.length,
        );
      } else {
        throw TVShowException('Failed to search shows: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw TVShowException('Network error: ${e.message}', isNetworkError: true);
    } on FormatException catch (e) {
      throw TVShowException('Data format error: ${e.message}');
    } on Exception catch (e) {
      throw TVShowException('Unexpected error: ${e.toString()}');
    }
  }

  void clearCache() {
    _allShowsCache = null;
  }
}