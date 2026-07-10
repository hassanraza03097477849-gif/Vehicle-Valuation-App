import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/metadata_service.dart';
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valuation Pro',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.displayLarge),
          displayMedium: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.displayMedium),
          displaySmall: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.displaySmall),
          headlineLarge: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.headlineLarge),
          headlineMedium: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.headlineMedium),
          headlineSmall: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.headlineSmall),
          titleLarge: GoogleFonts.outfit(textStyle: Theme.of(context).textTheme.titleLarge),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004AAF),
          surface: const Color(0xFFFAF8FF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFC6C6CD), width: 2.0),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFC6C6CD), width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: Color(0xFF004AAF), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.token == null && !auth.isAuthenticated) {
            return const LoginScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
