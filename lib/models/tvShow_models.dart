class TVShow {
  final int id;
  final String name;
  final String? imageUrl;
  final double rating;
  final List<String> genres;
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
      imageUrl: json['image'] != null ? json['image']['medium'] : null,
      rating: json['rating']['average'] != null
          ? (json['rating']['average'] as num).toDouble()
          : 0.0,
      genres: List<String>.from(json['genres']),
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
}