import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/metadata_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('surveyQueue');
  await Hive.openBox('imageQueue');
  await Hive.openBox('metadata');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => MetadataService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          title: 'Valuation Pro',
          themeMode: themeService.themeMode,
          theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Pure white for bright sun
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.displayLarge),
          displayMedium: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.displayMedium),
          displaySmall: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.displaySmall),
          headlineLarge: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.headlineLarge),
          headlineMedium: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.headlineMedium),
          headlineSmall: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.headlineSmall),
          titleLarge: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.titleLarge),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0052FF), // Vivid Electric Blue
          onPrimary: Colors.white,
          surface: Color(0xFFF9FAFB),
          onSurface: Color(0xFF000000), // Pure black text for contrast
          background: Color(0xFFFFFFFF),
          onBackground: Color(0xFF000000),
          outline: Color(0xFF000000), // Black outlines for bold shapes
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF000000), width: 2.0), // High contrast border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF000000), width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF0052FF), width: 3.0), // Extra thick when focused
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          labelStyle: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
          hintStyle: const TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // OLED Black for dark night
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.displayLarge),
          displayMedium: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.displayMedium),
          displaySmall: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.displaySmall),
          headlineLarge: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.headlineLarge),
          headlineMedium: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.headlineMedium),
          headlineSmall: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.headlineSmall),
          titleLarge: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.titleLarge),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2E90FA), // Brighter blue for dark mode
          onPrimary: Colors.white,
          surface: Color(0xFF121212), // Elevated dark grey
          onSurface: Color(0xFFFFFFFF), // Pure white text
          background: Color(0xFF000000),
          onBackground: Color(0xFFFFFFFF),
          outline: Color(0xFFFFFFFF), // White outlines for bold shapes
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121212),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF2E90FA), width: 3.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          labelStyle: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E90FA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.token == null && !auth.isAuthenticated) {
            return const LoginScreen();
          }
          return const HomeScreen();
        },
      ),
    );
    },
    );
  }
}
