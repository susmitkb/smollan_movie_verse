import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Add this import
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
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _initialLoadComplete = false;
  bool _isSwitchingFilter = false;
  ShowFilter? _loadingFilter;

  @override
  void initState() {
    super.initState();

    // Use Future.microtask to run after the build is complete
    Future.microtask(() {
      final provider = Provider.of<TVShowProvider>(context, listen: false);
      if (provider.shows.isEmpty) {
        provider.fetchShows(ShowFilter.trending, loadMore: false);
      } else {
        // If we already have data, mark initial load as complete
        _initialLoadComplete = true;
      }
    });

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final provider = Provider.of<TVShowProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        provider.hasMoreShows &&
        provider.state != UIState.loading) {

      // Load more shows
      _loadMoreShows();
    }
  }

  Future<void> _loadMoreShows() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final provider = Provider.of<TVShowProvider>(context, listen: false);
    try {
      await provider.fetchShows(provider.currentFilter, loadMore: true);
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
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

  void _handleFilterChange(ShowFilter filter, TVShowProvider provider) {
    if (provider.currentFilter == filter) return;

    setState(() {
      _isSwitchingFilter = true;
      _loadingFilter = filter;
    });

    provider.fetchShows(filter, loadMore: false).then((_) {
      setState(() {
        _isSwitchingFilter = false;
        _loadingFilter = null;
      });
    });
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
          // Check if we're switching filters and the target filter is loading
          final bool isTargetFilterLoading = _isSwitchingFilter &&
              _loadingFilter != null &&
              provider.currentFilter == _loadingFilter &&
              provider.state == UIState.loading;

          // Handle initial loading state or filter switching loading state
          if ((!_initialLoadComplete && provider.state == UIState.loading && provider.shows.isEmpty) ||
              isTargetFilterLoading) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        label: const Text('Trending'),
                        selected: provider.currentFilter == ShowFilter.trending,
                        onSelected: (_) => _handleFilterChange(ShowFilter.trending, provider),
                      ),
                      FilterChip(
                        label: const Text('Popular'),
                        selected: provider.currentFilter == ShowFilter.popular,
                        onSelected: (_) => _handleFilterChange(ShowFilter.popular, provider),
                      ),
                      FilterChip(
                        label: const Text('Upcoming'),
                        selected: provider.currentFilter == ShowFilter.upcoming,
                        onSelected: (_) => _handleFilterChange(ShowFilter.upcoming, provider),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Lottie.asset(
                      'assets/lottie/movie_loading.json', // Replace with your Lottie file path
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          }

          if (provider.state == UIState.error && provider.shows.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingIndicator.netwrokError(errorMessage: "Network Connection Error!"),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => provider.fetchShows(provider.currentFilter, loadMore: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'If the problem persists, check your internet connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.state == UIState.empty) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        label: const Text('Trending'),
                        selected: provider.currentFilter == ShowFilter.trending,
                        onSelected: (_) => _handleFilterChange(ShowFilter.trending, provider),
                      ),
                      FilterChip(
                        label: const Text('Popular'),
                        selected: provider.currentFilter == ShowFilter.popular,
                        onSelected: (_) => _handleFilterChange(ShowFilter.popular, provider),
                      ),
                      FilterChip(
                        label: const Text('Upcoming'),
                        selected: provider.currentFilter == ShowFilter.upcoming,
                        onSelected: (_) => _handleFilterChange(ShowFilter.upcoming, provider),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingIndicator.searchEmpty(),
                        const SizedBox(height: 16),
                        Text(
                          'No shows found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Mark initial load as complete once we have data
          if (!_initialLoadComplete) {
            Future.microtask(() {
              setState(() {
                _initialLoadComplete = true;
              });
            });
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterChip(
                      label: const Text('Trending'),
                      selected: provider.currentFilter == ShowFilter.trending,
                      onSelected: (_) => _handleFilterChange(ShowFilter.trending, provider),
                    ),
                    FilterChip(
                      label: const Text('Popular'),
                      selected: provider.currentFilter == ShowFilter.popular,
                      onSelected: (_) => _handleFilterChange(ShowFilter.popular, provider),
                    ),
                    FilterChip(
                      label: const Text('Upcoming'),
                      selected: provider.currentFilter == ShowFilter.upcoming,
                      onSelected: (_) => _handleFilterChange(ShowFilter.upcoming, provider),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo is ScrollEndNotification &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                        !_isLoadingMore &&
                        provider.hasMoreShows &&
                        provider.state != UIState.loading) {
                      _loadMoreShows();
                    }
                    return false;
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
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
                      if (_isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Lottie.asset(
                              'assets/lottie/movie_loading.json',                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      if (!provider.hasMoreShows && provider.shows.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No more shows to load',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}