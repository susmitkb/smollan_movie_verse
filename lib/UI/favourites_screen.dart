import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/home_screen.dart';
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
          final favorites = favoritesProvider.favorites;

          return favorites.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animation for empty favorites
                LoadingIndicator.favouritesEmpty(),

                const SizedBox(height: 24),

                // Catchy message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Psst… add some favourites to bring this ghost to life!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Tap the heart icon on any show to add it here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Browse shows button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Browse Shows'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () async {
              favoritesProvider.refreshFavorites();
            },
            child: Column(
              children: [
                // Results count message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    '${favorites.length} ${favorites.length == 1 ? 'favorite' : 'favorites'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Favorites grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
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
}