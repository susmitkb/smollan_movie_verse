import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';
import 'package:smollan_movie_verse/providers/theme_provider.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Use the same cache manager from ShowCard
class TVShowCacheManager extends CacheManager {
  static const key = 'tvShowCache';

  static final TVShowCacheManager _instance = TVShowCacheManager._();
  factory TVShowCacheManager() => _instance;

  TVShowCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 500,
  ));
}

class ShowDetailsScreen extends StatefulWidget {
  final TVShow show;

  const ShowDetailsScreen({super.key, required this.show});

  @override
  State<ShowDetailsScreen> createState() => _ShowDetailsScreenState();
}

class _ShowDetailsScreenState extends State<ShowDetailsScreen> {
  File? _cachedImageFile;
  bool _checkingCache = false;

  @override
  void initState() {
    super.initState();
    _checkImageCache();
  }

  Future<void> _checkImageCache() async {
    if (widget.show.imageUrl == null) return;

    setState(() {
      _checkingCache = true;
    });

    try {
      final file = await TVShowCacheManager().getSingleFile(widget.show.imageUrl!);
      if (await file.exists()) {
        setState(() {
          _cachedImageFile = file;
        });
      }
    } catch (e) {
      // Ignore errors, we'll use the placeholder
    } finally {
      setState(() {
        _checkingCache = false;
      });
    }
  }

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
            return const Icon(Icons.movie, size: 100, color: Colors.grey);
          },
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_checkingCache) {
      return _buildImagePlaceholder();
    }

    if (widget.show.imageUrl == null) {
      return _buildImagePlaceholder();
    }

    // If we have a cached file, use it for offline viewing
    if (_cachedImageFile != null) {
      return Image.file(
        _cachedImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Otherwise use CachedNetworkImage with proper error handling
    return CachedNetworkImage(
      cacheManager: TVShowCacheManager(),
      imageUrl: widget.show.imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildImagePlaceholder(),
      errorWidget: (context, url, error) {
        // Try to get the cached file as a fallback
        return FutureBuilder<File>(
          future: TVShowCacheManager().getSingleFile(widget.show.imageUrl!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildImagePlaceholder();
            }

            if (snapshot.hasData && snapshot.data!.existsSync()) {
              return Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }

            return _buildImagePlaceholder();
          },
        );
      },
    );
  }

  void _showRemoveConfirmationDialog(BuildContext context, FavoritesProvider favoritesProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 30,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Remove from Favorites?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Are you sure you want to remove "${widget.show.name}" from your favorites?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Remove Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          favoritesProvider.removeFromFavorites(widget.show.id);
                          Navigator.of(context).pop();

                          // Show a snackbar confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${widget.show.name}" from favorites'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'show-${widget.show.id}',
                child: _buildImageWidget(), // Use the same image widget as ShowCard
              ),
              title: Text(
                widget.show.name,
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
              Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  final isFavorite = favoritesProvider.isFavorite(widget.show.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      if (isFavorite) {
                        // Show confirmation dialog for removal
                        _showRemoveConfirmationDialog(context, favoritesProvider);
                      } else {
                        // Just add to favorites without confirmation
                        favoritesProvider.addToFavorites(widget.show);

                        // Show a snackbar confirmation for adding
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${widget.show.name}" to favorites'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
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
                          '⭐ ${widget.show.rating}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...widget.show.genres.take(3).map((genre) {
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
                    _parseHtmlString(widget.show.summary),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  if (widget.show.genres.isNotEmpty)
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
                          children: widget.show.genres.map((genre) {
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