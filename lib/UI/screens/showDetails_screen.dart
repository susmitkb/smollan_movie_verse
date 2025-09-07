import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/providers/imageCache_provider.dart';
import 'package:smollan_movie_verse/providers/theme_provider.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
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
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.movie, size: 100.w, color: Colors.grey);
          },
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    final imageCacheProvider = Provider.of<ImageCacheProvider>(context, listen: true);
    final cachedFile = imageCacheProvider.getCachedImage(show.imageUrl ?? '');
    final isLoading = imageCacheProvider.isLoading(show.imageUrl ?? '');

    if (isLoading) {
      return _buildImagePlaceholder();
    }

    if (show.imageUrl == null) {
      return _buildImagePlaceholder();
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
      imageUrl: show.imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildImagePlaceholder(),
      errorWidget: (context, url, error) => _buildImagePlaceholder(),
    );
  }

  void _showRemoveConfirmationDialog(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
            ),
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 30.w,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),

                SizedBox(height: 20.h),

                Text(
                  'Remove from Favorites?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                Text(
                  'Are you sure you want to remove "${show.name}" from your favorites?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          favoritesProvider.removeFromFavorites(show.id);
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${show.name}" from favorites'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Remove',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: true);
    final isFavorite = favoritesProvider.isFavorite(show.id);

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.white,
        size: 24.w,
      ),
      onPressed: () {
        if (isFavorite) {
          _showRemoveConfirmationDialog(context);
        } else {
          favoritesProvider.addToFavorites(show);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${show.name}" to favorites'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Pre-cache image when screen is built
    if (show.imageUrl != null) {
      final imageCacheProvider = Provider.of<ImageCacheProvider>(context, listen: false);
      imageCacheProvider.cacheImage(show.imageUrl!);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'show-${show.id}',
                child: _buildImageWidget(context),
              ),
              title: Text(
                show.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            actions: [_buildFavoriteButton(context)],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      Chip(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        label: Text(
                          '⭐ ${show.rating}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      ...show.genres.take(3).map((genre) {
                        return Chip(
                          label: Text(
                            genre,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _parseHtmlString(show.summary),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 24.h),
                  if (show.genres.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genres',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 4.h,
                          children: show.genres.map((genre) {
                            return Chip(
                              label: Text(
                                genre,
                                style: TextStyle(fontSize: 12.sp),
                              ),
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
        onPressed: () => themeProvider.toggleTheme(),
        child: Icon(
          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          size: 24.w,
        ),
      ),
    );
  }
}