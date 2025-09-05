import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/widgets/loadingIndicator.dart';
import 'package:smollan_movie_verse/constants/enums.dart';
import 'package:smollan_movie_verse/providers/tvShow_provider.dart';
import 'package:smollan_movie_verse/ui/widgets/show_card.dart';

import 'widgets/custom_appBar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late TVShowProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<TVShowProvider>(context, listen: false);
  }

  void _performSearch(String query) {
    if (query.length >= 2) {
      _provider.searchShows(query);
    } else if (query.isEmpty) {
      _provider.clearSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _provider.clearSearch();
  }

  Widget _buildSearchMessage(TVShowProvider provider) {
    if (provider.searchState == UIState.loading) {
      return const SizedBox.shrink(); // Hide message when loading
    }

    if (provider.searchState == UIState.success) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          '${provider.searchResults.length} ${provider.searchResults.length == 1 ? 'show' : 'shows'} found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (provider.searchState == UIState.empty && _searchController.text.isNotEmpty) {
      return const SizedBox.shrink(); // Hide message when no results (showing Lottie instead)
    }

    // Default message when no search or empty search
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        'Type at least 2 characters to start searching',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search Shows',
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Consumer<TVShowProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for TV shows...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  onChanged: _performSearch,
                ),
              ),

              // Dynamic search message
              _buildSearchMessage(provider),

              if (provider.searchState == UIState.loading)
                Expanded(child: LoadingIndicator.searchEmpty()),

              if (provider.searchState == UIState.error)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingIndicator.error(errorMessage: 'Error: ${provider.errorMessage}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _performSearch(_searchController.text),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),

              if (provider.searchState == UIState.empty && _searchController.text.isEmpty)
                Expanded(child: LoadingIndicator.searchEmpty()),

              if (provider.searchState == UIState.empty && _searchController.text.isNotEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingIndicator.noResults(),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'No shows found for "${_searchController.text}"',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

              if (provider.searchState == UIState.success)
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: provider.searchResults.length,
                    itemBuilder: (context, index) {
                      final show = provider.searchResults[index];
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}