import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final String? lottieAsset;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.lottieAsset,
    this.size = 150,
  });

  // Regular loading
  factory LoadingIndicator.regular() {
    return const LoadingIndicator(
      lottieAsset: 'assets/lottie/movie_loading.json',
    );
  }

  // Search loading
  factory LoadingIndicator.searching() {
    return const LoadingIndicator(
      lottieAsset: 'assets/lottie/movie_loading.json',
    );
  }

  // Search empty (before any search)
  factory LoadingIndicator.searchEmpty() {
    return const LoadingIndicator(
      lottieAsset: 'assets/lottie/search.json',
      size: 300,
    );
  }

  // No results found
  factory LoadingIndicator.noResults() {
    return const LoadingIndicator(
      lottieAsset: 'assets/lottie/movie_empty.json',
      size: 250,
    );
  }

  // Movies empty (no movies available)
  factory LoadingIndicator.moviesEmpty() {
    return const LoadingIndicator(
      lottieAsset: 'assets/lottie/movie_empty.json',
      message: 'No movies available',
      size: 250,
    );
  }
  factory LoadingIndicator.favouritesEmpty() {
    return const LoadingIndicator(
      lottieAsset: 'assets/lottie/empty_fav.json',
      size: 250,
    );
  }

  // Error state
  factory LoadingIndicator.error({String? errorMessage}) {
    return LoadingIndicator(
      lottieAsset: 'assets/lottie/error_animation.json',
      message: errorMessage ?? 'Something went wrong',
      size: 600,
    );
  }
  factory LoadingIndicator.networkError({String? errorMessage}) {
    return LoadingIndicator(
      lottieAsset: 'assets/lottie/no_internet_animation.json',
      message: errorMessage ?? 'Something went wrong',
      size: 490,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lottieAsset != null
              ? Lottie.asset(
            lottieAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icons if Lottie files are missing
              if (lottieAsset?.contains('search_empty') == true) {
                return const Icon(Icons.search, size: 64, color: Colors.grey);
              } else if (lottieAsset?.contains('movie_empty') == true) {
                return const Icon(Icons.movie, size: 64, color: Colors.grey);
              } else if (lottieAsset?.contains('error') == true) {
                return const Icon(Icons.error_outline, size: 64, color: Colors.red);
              } else {
                return const CircularProgressIndicator();
              }
            },
          )
              : Lottie.asset(
            'assets/lottie/movie_loading.json',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator();
            },
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}