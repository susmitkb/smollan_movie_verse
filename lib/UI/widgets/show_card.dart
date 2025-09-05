import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/showDetails_screen.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Create a custom cache manager with persistent storage
class TVShowCacheManager extends CacheManager {
  static const key = 'tvShowCache';

  static final TVShowCacheManager _instance = TVShowCacheManager._();
  factory TVShowCacheManager() => _instance;

  TVShowCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 365), // Keep cached images for 1 year
    maxNrOfCacheObjects: 500, // Store up to 500 images
  ));
}

class ShowCard extends StatelessWidget {
  final TVShow show;

  const ShowCard({super.key, required this.show});

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowDetailsScreen(show: show),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Hero(
                  tag: 'show-${show.id}',
                  child: show.imageUrl != null
                      ? CachedNetworkImage(
                    cacheManager: TVShowCacheManager(), // Use persistent cache
                    imageUrl: show.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                      : _buildPlaceholder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(show.rating.toString()),
                      const Spacer(),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final isFavorite = favoritesProvider.isFavorite(show.id);
                          return IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              final wasFavorite = favoritesProvider.isFavorite(show.id);
                              favoritesProvider.toggleFavorite(show);

                              // Show snackbar based on action
                              if (wasFavorite) {
                                _showSnackBar(
                                  context,
                                  'Removed "${show.name}" from favorites',
                                  Theme.of(context).colorScheme.error,
                                );
                              } else {
                                _showSnackBar(
                                  context,
                                  'Added "${show.name}" to favorites',
                                  Theme.of(context).colorScheme.primary,
                                );
                              }
                            },
                            iconSize: 20,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Image.asset(
          'assets/images/movie_placeholder.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.movie, size: 60, color: Colors.grey);
          },
        ),
      ),
    );
  }
}