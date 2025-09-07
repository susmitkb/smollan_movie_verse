import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smollan_movie_verse/UI/screens/home_screen.dart';
import 'package:smollan_movie_verse/models/tvShow_adapter.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
import 'package:smollan_movie_verse/providers/imageCache_provider.dart';
import 'package:smollan_movie_verse/providers/theme_provider.dart';
import 'package:smollan_movie_verse/providers/tvShow_provider.dart';
import 'package:smollan_movie_verse/repository/tvShow_repo.dart';
import 'package:smollan_movie_verse/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Error handling for Hive initialization
  try {
    // Initialize Hive with Flutter
    await Hive.initFlutter();

    // Register adapter (ONLY ONCE)
    Hive.registerAdapter(TVShowAdapter());

    // Initialize HiveService
    await HiveService.init();

    log('🎯 Hive initialization successful', name: 'main');

  } catch (e, stackTrace) {
    log('💥 CRITICAL: Hive initialization failed: $e',
        name: 'main',
        error: e,
        stackTrace: stackTrace);
    // You might want to show an error screen or use fallback storage
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Standard mobile size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) => TVShowProvider(TVShowRepository()),
            ),
            ChangeNotifierProvider(create: (_) => FavoritesProvider()),
            ChangeNotifierProvider(create: (_) => ImageCacheProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Smollan Movie Verse',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                  brightness: Brightness.dark,
                ),
                themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                home: const HomeScreen(),
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  return MediaQuery(
                    // Prevent font scaling issues
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                    child: child!,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}