import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/providers/theme_provider.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart'; // Add this import
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' as html_parser;

class ShowDetailsScreen extends StatelessWidget {
  final TVShow show;

  const ShowDetailsScreen({super.key, required this.show});

  String _parseHtmlString(String htmlString) {
    final document = html_parser.parse(htmlString);
    final String parsedString = document.body?.text ?? '';
    return parsedString;
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Image.asset(
          'assets/images/movie_placeholder.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // If the asset doesn't exist, fallback to icon
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.movie, size: 100, color: Colors.grey);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false); // Add this

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'show-${show.id}',
                child: show.imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: show.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildImagePlaceholder(),
                  errorWidget: (context, url, error) => _buildImagePlaceholder(),
                )
                    : _buildImagePlaceholder(),
              ),
              title: Text(
                show.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              // Use Consumer to listen to favorites changes
              Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  final isFavorite = favoritesProvider.isFavorite(show.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      favoritesProvider.toggleFavorite(show); // Use provider instead of HiveService directly
                    },
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        label: Text(
                          '⭐ ${show.rating}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...show.genres.take(3).map((genre) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(genre),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _parseHtmlString(show.summary),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  if (show.genres.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genres',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: show.genres.map((genre) {
                            return Chip(
                              label: Text(genre),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          themeProvider.toggleTheme();
        },
        child: Icon(
          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        ),
      ),
    );
  }
}