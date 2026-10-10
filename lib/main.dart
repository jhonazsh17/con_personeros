import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'core/theme/app_colors.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<bool> _featureEnabled;

  @override
  void initState() {
    super.initState();
    _featureEnabled = ApiService.isNewVotingSystemEnabled().catchError(
      (_) => false,
    );
  }

  ThemeData get _theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _featureEnabled,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'Con Personeros',
            debugShowCheckedModeBanner: false,
            theme: _theme,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            ),
          );
        }

        if (snapshot.data != true) {
          return MaterialApp(
            title: 'Con Personeros',
            debugShowCheckedModeBanner: false,
            theme: _theme,
            home: const AppUnavailableScreen(),
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const AppUnavailableScreen(),
            ),
          );
        }

        return MaterialApp(
          title: 'Con Personeros',
          debugShowCheckedModeBanner: false,
          theme: _theme,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}

class AppUnavailableScreen extends StatelessWidget {
  const AppUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'La aplicación no está disponible',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
