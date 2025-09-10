import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Add this
import 'package:smollan_movie_verse/UI/screens/favourites_screen.dart';
import 'package:smollan_movie_verse/UI/screens/search_screen.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<TVShowProvider>(context, listen: false);
      if (provider.shows.isEmpty) {
        provider.fetchShows(ShowFilter.trending, loadMore: false);
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
        !provider.isLoadingMore &&
        provider.hasMoreShows &&
        provider.state != UIState.loading) {
      _loadMoreShows();
    }
  }

  Future<void> _loadMoreShows() async {
    final provider = Provider.of<TVShowProvider>(context, listen: false);
    await provider.fetchShows(provider.currentFilter, loadMore: true);
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

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.r), // Use .r for responsive radius
      child: GestureDetector(
        onTap: _navigateToSearchScreen,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), // .w and .h for responsive sizing
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey, size: 20.w), // Responsive icon size
              SizedBox(width: 12.w),
              Expanded( // Added Expanded to prevent text overflow
                child: Text(
                  'Search for TV shows...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16.sp, // Use .sp for responsive font size
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(TVShowProvider provider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap( // Changed from Row to Wrap for better responsiveness
        spacing: 8.w,
        runSpacing: 8.h,
        alignment: WrapAlignment.center,
        children: [
          FilterChip(
            label: Text('Trending', style: TextStyle(fontSize: 12.sp)),
            selected: provider.currentFilter == ShowFilter.trending,
            onSelected: (_) => provider.fetchShows(ShowFilter.trending, loadMore: false),
          ),
          FilterChip(
            label: Text('Popular', style: TextStyle(fontSize: 12.sp)),
            selected: provider.currentFilter == ShowFilter.popular,
            onSelected: (_) => provider.fetchShows(ShowFilter.popular, loadMore: false),
          ),
          FilterChip(
            label: Text('Upcoming', style: TextStyle(fontSize: 12.sp)),
            selected: provider.currentFilter == ShowFilter.upcoming,
            onSelected: (_) => provider.fetchShows(ShowFilter.upcoming, loadMore: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(Provider.of<TVShowProvider>(context)),
        Expanded(
          child: Center(
            child: Lottie.asset(
              'assets/lottie/movie_loading.json',
              width: 200.w,
              height: 200.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(TVShowProvider provider) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicator.networkError(errorMessage: "Network Connection Error!"),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => provider.fetchShows(provider.currentFilter, loadMore: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 3,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20.w),
                      SizedBox(width: 12.w),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'If the problem persists, check your internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TVShowProvider provider) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(provider),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingIndicator.searchEmpty(),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'No shows found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(TVShowProvider provider) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(provider),
        SizedBox(height: 16.h),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollEndNotification &&
                  scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                  !provider.isLoadingMore &&
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
                    padding: EdgeInsets.all(8.r),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context), // Responsive cross axis count
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                    ),
                    itemCount: provider.shows.length,
                    itemBuilder: (context, index) {
                      final show = provider.shows[index];
                      return ShowCard(show: show);
                    },
                  ),
                ),
                if (provider.isLoadingMore)
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Center(
                      child: Lottie.asset(
                        'assets/lottie/movie_loading.json',
                        width: 100.w,
                        height: 100.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                if (!provider.hasMoreShows && provider.shows.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Text(
                      'No more shows to load',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to determine responsive grid columns
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 4; // Tablet
    if (width > 400) return 3; // Large phone
    return 2; // Small phone
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TVShowProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Smollan Movie Verse',
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, size: 24.w),
            onPressed: _navigateToFavoritesScreen,
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(TVShowProvider provider) {
    switch (provider.state) {
      case UIState.loading:
        return _buildLoadingState();
      case UIState.error:
        return _buildErrorState(provider);
      case UIState.empty:
        return _buildEmptyState(provider);
      case UIState.success:
        return _buildSuccessState(provider);
      default:
        return _buildLoadingState();
    }
  }
}