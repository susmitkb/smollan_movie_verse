import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/favourites_screen.dart';
import 'package:smollan_movie_verse/UI/search_screen.dart';
import 'package:smollan_movie_verse/UI/widgets/custom_appBar.dart';
import 'package:smollan_movie_verse/UI/widgets/loadingIndicator.dart';
import 'package:smollan_movie_verse/UI/widgets/show_card.dart';
import 'package:smollan_movie_verse/constants/enums.dart';
import 'package:smollan_movie_verse/providers/tvShow_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TVShowProvider>(context, listen: false);
    provider.fetchShows(ShowFilter.trending);
  }

  void _navigateToFavoritesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesScreen(),
      ),
    );
  }

  void _navigateToSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Smollan Movie Verse',
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: _navigateToFavoritesScreen,
          ),
        ],
      ),
      body: Consumer<TVShowProvider>(
        builder: (context, provider, child) {
          if (provider.state == UIState.loading) {
            return const LoadingIndicator();
          }

          if (provider.state == UIState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchShows(provider.currentFilter),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.state == UIState.empty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No shows found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Bar at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: _navigateToSearchScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          'Search for TV shows...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterChip(
                      label: const Text('Trending'),
                      selected: provider.currentFilter == ShowFilter.trending,
                      onSelected: (_) => provider.fetchShows(ShowFilter.trending),
                    ),
                    FilterChip(
                      label: const Text('Popular'),
                      selected: provider.currentFilter == ShowFilter.popular,
                      onSelected: (_) => provider.fetchShows(ShowFilter.popular),
                    ),
                    FilterChip(
                      label: const Text('Upcoming'),
                      selected: provider.currentFilter == ShowFilter.upcoming,
                      onSelected: (_) => provider.fetchShows(ShowFilter.upcoming),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Shows Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.shows.length,
                  itemBuilder: (context, index) {
                    final show = provider.shows[index];
                    return ShowCard(show: show);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}