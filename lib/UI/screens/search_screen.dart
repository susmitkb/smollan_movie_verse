import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smollan_movie_verse/UI/widgets/loadingIndicator.dart';
import 'package:smollan_movie_verse/constants/enums.dart';
import 'package:smollan_movie_verse/providers/tvShow_provider.dart';
import 'package:smollan_movie_verse/ui/widgets/show_card.dart';
import '../widgets/custom_appBar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchSearchState();
}

class _SearchSearchState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late TVShowProvider _provider;
  final FocusNode _focusNode = FocusNode();

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
    _focusNode.unfocus(); // Hide keyboard when clearing search
  }

  Widget _buildSearchMessage(TVShowProvider provider) {
    if (provider.searchState == UIState.loading) {
      return const SizedBox.shrink();
    }

    if (provider.searchState == UIState.success) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Text(
          '${provider.searchResults.length} ${provider.searchResults.length == 1 ? 'show' : 'shows'} found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    if (provider.searchState == UIState.empty && _searchController.text.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        'Type at least 2 characters to start searching',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search Shows',
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, size: 24.w),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Consumer<TVShowProvider>(
        builder: (context, provider, child) {
          return GestureDetector(
            onTap: () {
              // Hide keyboard when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView( // Wrap with SingleChildScrollView
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search for TV shows...',
                          prefixIcon: Icon(Icons.search, size: 24.w),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, size: 20.w),
                            onPressed: _clearSearch,
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                        ),
                        onChanged: _performSearch,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),

                    _buildSearchMessage(provider),

                    // Use Expanded only when we have content that needs to fill space
                    if (provider.searchState == UIState.loading)
                      SizedBox(
                        height: 300.h, // Fixed height instead of Expanded
                        child: LoadingIndicator.searchEmpty(),
                      ),

                    if (provider.searchState == UIState.error)
                      SizedBox(
                        height: 300.h, // Fixed height
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LoadingIndicator.error(errorMessage: 'Error: ${provider.errorMessage}'),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () => _performSearch(_searchController.text),
                              child: Text('Try Again', style: TextStyle(fontSize: 14.sp)),
                            ),
                          ],
                        ),
                      ),

                    if (provider.searchState == UIState.empty && _searchController.text.isEmpty)
                      SizedBox(
                        height: 300.h, // Fixed height
                        child: LoadingIndicator.searchEmpty(),
                      ),

                    if (provider.searchState == UIState.empty && _searchController.text.isNotEmpty)
                      SizedBox(
                        height: 300.h, // Fixed height
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LoadingIndicator.noResults(),
                            SizedBox(height: 8.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                'No shows found for "${_searchController.text}"',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (provider.searchState == UIState.success)
                      GridView.builder(
                        padding: EdgeInsets.all(8.r),
                        shrinkWrap: true, // Important: use shrinkWrap instead of Expanded
                        physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                        ),
                        itemCount: provider.searchResults.length,
                        itemBuilder: (context, index) {
                          final show = provider.searchResults[index];
                          return ShowCard(show: show);
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}