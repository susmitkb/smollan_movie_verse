import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/screens/showDetails_screen.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart' hide TVShowCacheManager;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smollan_movie_verse/providers/imageCache_provider.dart';

class ShowCard extends StatelessWidget {
  final TVShow show;

  const ShowCard({super.key, required this.show});

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        margin: EdgeInsets.all(16.r),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final imageCacheProvider = Provider.of<ImageCacheProvider>(context);

    // Pre-cache image when card is built
    if (show.imageUrl != null) {
      imageCacheProvider.cacheImage(show.imageUrl!);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: Hero(
                  tag: 'show-${show.id}',
                  child: _buildImageWidget(context, imageCacheProvider),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        show.rating.toString(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      const Spacer(),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final isFavorite = favoritesProvider.isFavorite(show.id);
                          return IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                              size: 20.w,
                            ),
                            onPressed: () {
                              final wasFavorite = favoritesProvider.isFavorite(show.id);
                              favoritesProvider.toggleFavorite(show);

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

  Widget _buildImageWidget(BuildContext context, ImageCacheProvider imageCacheProvider) {
    if (show.imageUrl == null) {
      return _buildPlaceholder();
    }

    return Consumer<ImageCacheProvider>(
      builder: (context, imageCache, child) {
        final cachedFile = imageCache.getCachedImage(show.imageUrl!);
        final isLoading = imageCache.isLoading(show.imageUrl!);

        if (isLoading) {
          return _buildPlaceholder();
        }

        if (cachedFile != null) {
          return Image.file(
            cachedFile,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }

        return CachedNetworkImage(
          cacheManager: TVShowCacheManager(),
          imageUrl: show.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        );
      },
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
            return Icon(Icons.movie, size: 60.w, color: Colors.grey);
          },
        ),
      ),
    );
  }
}