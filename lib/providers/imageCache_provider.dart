import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

class ImageCacheProvider with ChangeNotifier {
  final Map<String, File?> _cachedImages = {};
  final Map<String, bool> _loadingStates = {};

  File? getCachedImage(String imageUrl) => _cachedImages[imageUrl];
  bool isLoading(String imageUrl) => _loadingStates[imageUrl] ?? false;

  Future<void> cacheImage(String imageUrl) async {
    if (_cachedImages.containsKey(imageUrl) || _loadingStates[imageUrl] == true) {
      return;
    }

    // Don't notify listeners here - it's called during build
    _loadingStates[imageUrl] = true;

    try {
      final file = await TVShowCacheManager().getSingleFile(imageUrl);
      if (await file.exists()) {
        _cachedImages[imageUrl] = file;
        log(' Image cached: $imageUrl', name: 'ImageCacheProvider');

        if (!_loadingStates[imageUrl]!) { // Check if still in loading state
          notifyListeners();
        }
      }
    } catch (e) {
      log(' Failed to cache image: $imageUrl - $e', name: 'ImageCacheProvider');
    } finally {
      _loadingStates[imageUrl] = false;
      notifyListeners();
    }
  }
  Future<void> cacheImageSafe(String imageUrl) async {
    if (_cachedImages.containsKey(imageUrl) || _loadingStates[imageUrl] == true) {
      return;
    }

    _loadingStates[imageUrl] = true;

    // Use Future.microtask to schedule notification after build
    Future.microtask(() => notifyListeners());

    try {
      final file = await TVShowCacheManager().getSingleFile(imageUrl);
      if (await file.exists()) {
        _cachedImages[imageUrl] = file;
        log(' Image cached: $imageUrl', name: 'ImageCacheProvider');
      }
    } catch (e) {
      log(' Failed to cache image: $imageUrl - $e', name: 'ImageCacheProvider');
    } finally {
      _loadingStates[imageUrl] = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<File?> getImage(String imageUrl) async {
    if (_cachedImages.containsKey(imageUrl)) {
      return _cachedImages[imageUrl];
    }

    await cacheImageSafe(imageUrl);
    return _cachedImages[imageUrl];
  }

  void clearCache() {
    _cachedImages.clear();
    _loadingStates.clear();
    notifyListeners();
  }
}