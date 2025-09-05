import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smollan_movie_verse/UI/home_screen.dart';
import 'package:smollan_movie_verse/models/tvShow_adapter.dart';
import 'package:smollan_movie_verse/providers/favourites_provider.dart';
import 'package:smollan_movie_verse/providers/theme_provider.dart';
import 'package:smollan_movie_verse/providers/tvShow_provider.dart';
import 'package:smollan_movie_verse/repository/tvShow_repo.dart';
import 'package:smollan_movie_verse/services/hive_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TVShowAdapter());
  await HiveService.init();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => TVShowProvider(TVShowRepository()),

        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
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
          );
        },
      ),
    );
  }
}