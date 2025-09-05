import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/showDetails_screen.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShowCard extends StatelessWidget {
  final TVShow show;

  const ShowCard({super.key, required this.show});

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
                              favoritesProvider.toggleFavorite(show);
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