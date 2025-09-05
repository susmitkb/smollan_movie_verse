import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class TVShowRepository {
  static const String baseUrl = 'https://api.tvmaze.com';

  Future<List<TVShow>> getTrendingShows() async {
    final response = await http.get(Uri.parse('$baseUrl/shows'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TVShow.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trending shows');
    }
  }

  Future<List<TVShow>> getPopularShows() async {
    final response = await http.get(Uri.parse('$baseUrl/shows'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<TVShow> shows = data.map((json) => TVShow.fromJson(json)).toList();
      shows.sort((a, b) => b.rating.compareTo(a.rating));
      return shows.take(20).toList();
    } else {
      throw Exception('Failed to load popular shows');
    }
  }

  Future<List<TVShow>> getUpcomingShows() async {
    final response = await http.get(Uri.parse('$baseUrl/schedule'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final showIds = <int>{};
      final List<TVShow> shows = [];

      for (var item in data) {
        final show = item['show'];
        final showId = show['id'];

        if (!showIds.contains(showId)) {
          showIds.add(showId);
          shows.add(TVShow.fromJson(show));
        }
      }

      return shows;
    } else {
      throw Exception('Failed to load upcoming shows');
    }
  }

  Future<List<TVShow>> searchShows(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search/shows?q=$query'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => TVShow.fromJson(item['show'])).toList();
    } else {
      throw Exception('Failed to search shows');
    }
  }
}