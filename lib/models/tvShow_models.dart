import 'package:hive/hive.dart';


@HiveType(typeId: 0) // Add Hive annotations
class TVShow {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? imageUrl;

  @HiveField(3)
  final double rating;

  @HiveField(4)
  final List<String> genres;

  @HiveField(5)
  final String summary;

  TVShow({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
    required this.genres,
    required this.summary,
  });

  factory TVShow.fromJson(Map<String, dynamic> json) {
    return TVShow(
      id: json['id'],
      name: json['name'],
      // FIXED: Make sure this matches what Hive expects
      imageUrl: json['imageUrl'] ?? (json['image'] != null ? json['image']['medium'] : null),
      rating: json['rating'] is Map
          ? (json['rating']['average'] != null ? (json['rating']['average'] as num).toDouble() : 0.0)
          : (json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0),
      genres: List<String>.from(json['genres'] ?? []),
      summary: json['summary'] ?? 'No summary available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'genres': genres,
      'summary': summary,
    };
  }

  // Add copyWith method for easier updates
  TVShow copyWith({
    int? id,
    String? name,
    String? imageUrl,
    double? rating,
    List<String>? genres,
    String? summary,
  }) {
    return TVShow(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      summary: summary ?? this.summary,
    );
  }
}