import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Add this
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/screens/home_screen.dart';
import 'package:smollan_movie_verse/UI/widgets/custom_appBar.dart';
import 'package:smollan_movie_verse/UI/widgets/loadingIndicator.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
import 'package:smollan_movie_verse/ui/widgets/show_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Favorites'),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(), // Responsive size
            );
          }
          if (favoritesProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: Colors.red), // Responsive
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading favorites',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16.sp),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      favoritesProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      favoritesProvider.refreshFavorites();
                    },
                    child: Text('Try Again', style: TextStyle(fontSize: 14.sp)),
                  ),
                ],
              ),
            );
          }

          final favorites = favoritesProvider.favorites;

          return favorites.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingIndicator.favouritesEmpty(),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    'Psst… add some favourites to bring this ghost to life!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    'Tap the heart icon on any show to add it here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  icon: Icon(Icons.explore, size: 20.w),
                  label: Text('Browse Shows', style: TextStyle(fontSize: 14.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () async {
              await favoritesProvider.refreshFavorites();
            },
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Text(
                    '${favorites.length} ${favorites.length == 1 ? 'favorite' : 'favorites'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(8.r),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context), // Use same responsive logic
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                    ),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final show = favorites[index];
                      return ShowCard(show: show);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Add the same responsive grid logic as HomeScreen
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 4; // Tablet
    if (width > 400) return 3; // Large phone
    return 2; // Small phone
  }
}