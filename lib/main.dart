import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/expensesincomelist.dart';
import 'screens/budgetplanner.dart';
import 'screens/inflationTracker.dart';
import 'screens/smartSuggestions.dart';
import 'screens/analyticsReport.dart';
import 'screens/settings.dart';
import 'screens/predictions_screen.dart';
import 'widgets/notifications.dart';
import 'utils/route_transitions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Budget',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          // Primary colors
          primary: const Color(0xFF4A90E2), // Blue - Primary buttons / highlights
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF5DADE2), // Light Blue - Neutral / info
          onPrimaryContainer: Colors.white,
          
          // Secondary colors
          secondary: const Color(0xFF27AE60), // Green - Positive balance / success
          onSecondary: Colors.white,
          
          // Tertiary colors
          tertiary: const Color(0xFFF39C12), // Orange - Warning / Budget overspend
          onTertiary: Colors.white,
          
          // Error colors
          error: const Color(0xFFE74C3C), // Red - Negative balance / expense alerts
          onError: Colors.white,
          
          // Surface colors
          surface: const Color(0xFFFAFAFA), // Off-White - Main background
          onSurface: const Color(0xFF003366), // Dark Blue - Headers / Top bar
          surfaceContainerHighest: const Color(0xFFF2F2F2), // Light Grey - Cards / containers
          onSurfaceVariant: const Color(0xFF7F8C8D), // Grey - Secondary text
          
          // Background
          background: const Color(0xFFFAFAFA), // Off-White
          onBackground: const Color(0xFF003366), // Dark Blue
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Off-White - Main background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A90E2), // Primary Blue
          foregroundColor: Colors.black, // Black text
          iconTheme: IconThemeData(color: Colors.white), // White icons
          elevation: 0, // No shadow/divider
          surfaceTintColor: Colors.transparent, // Remove Material 3 tint
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          // Primary colors
          primary: const Color(0xFF4A90E2), // Blue
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF5DADE2), // Light Blue
          onPrimaryContainer: Colors.white,
          
          // Secondary colors
          secondary: const Color(0xFF27AE60), // Green
          onSecondary: Colors.white,
          
          // Tertiary colors
          tertiary: const Color(0xFFF39C12), // Orange
          onTertiary: Colors.white,
          
          // Error colors
          error: const Color(0xFFE74C3C), // Red
          onError: Colors.white,
          
          // Surface colors
          surface: const Color(0xFF121212), // Dark Grey - Dark mode background
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF1E1E1E), // Darker grey for cards
          onSurfaceVariant: const Color(0xFFB0B0B0), // Lighter grey for secondary text
          
          // Background
          background: const Color(0xFF121212), // Dark Grey
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // Dark Grey - Dark mode background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A90E2), // Primary Blue
          foregroundColor: Colors.black, // Black text
          iconTheme: IconThemeData(color: Colors.white), // White icons
          elevation: 0, // No shadow/divider
          surfaceTintColor: Colors.transparent, // Remove Material 3 tint
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        // Handle replacement routes (like login, onboarding, splash)
        final isReplacement = settings.name == '/onboarding' || 
                             settings.name == '/login' || 
                             settings.name == '/home';

        switch (settings.name) {
          case '/onboarding':
            return ImmersivePageRoute(
              child: const OnboardingScreen(),
              isReplacement: true,
            );
          case '/login':
            return ImmersivePageRoute(
              child: const LoginScreen(),
              isReplacement: isReplacement,
            );
          case '/home':
            return ImmersivePageRoute(
              child: const HomeScreen(),
              isReplacement: isReplacement,
            );
          case '/transactions':
            return SlideRightPageRoute(
              child: const ExpensesIncomeListScreen(),
            );
          case '/budget-planner':
            return SlideRightPageRoute(
              child: const BudgetPlannerScreen(),
            );
          case '/inflation-tracker':
            return SlideRightPageRoute(
              child: const InflationTrackerScreen(),
            );
          case '/predictions':
            return SlideRightPageRoute(
              child: const PredictionsScreen(),
            );
          case '/smart-suggestions':
            return SlideRightPageRoute(
              child: const SmartSuggestionsScreen(),
            );
          case '/analytics-report':
            return SlideRightPageRoute(
              child: const AnalyticsReportScreen(),
            );
          case '/settings':
            return SlideRightPageRoute(
              child: const SettingsScreen(),
            );
          case '/notifications':
            return SlideRightPageRoute(
              child: const NotificationsScreen(),
            );
          default:
            return ImmersivePageRoute(
              child: const HomeScreen(),
            );
        }
      },
    );
  }
}

