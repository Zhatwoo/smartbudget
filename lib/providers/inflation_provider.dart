import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/inflation_service.dart';
import '../services/inflation_api_service.dart';
import '../models/inflation_item_model.dart';
import 'auth_provider.dart';

/// Inflation Service Provider
final inflationServiceProvider = Provider<InflationService>((ref) {
  return InflationService();
});

/// Inflation Items Stream Provider
/// Streams all inflation items for the current user
/// Used by Dashboard, Inflation Tracker, Smart Suggestions
/// Reactive to auth state changes - will update when user logs in/out
/// Automatically initializes default items if user has none
final inflationItemsProvider = StreamProvider<List<InflationItemModel>>((ref) {
  final inflationService = ref.watch(inflationServiceProvider);
  // Watch auth state to rebuild stream when user logs in/out
  final authState = ref.watch(authStateProvider);
  
  // If auth state is loading, return empty stream temporarily
  if (authState.isLoading) {
    return Stream.value([]);
  }
  
  // If user is not authenticated, return empty stream
  if (authState.value == null) {
    return Stream.value([]);
  }
  
  // Return inflation items stream for authenticated user
  final stream = inflationService.getInflationItems();
  
  // Automatically initialize default items if user has none
  // This runs asynchronously and doesn't block the stream
  stream.first.then((items) {
    if (items.isEmpty) {
      inflationService.ensureDefaultItemsInitialized().catchError((e) {
        // Silently fail - initialization is not critical
      });
    }
  }).catchError((e) {
    // Silently fail
  });
  
  return stream;
});

/// High Inflation Items Provider
/// Detects items with high inflation (above threshold)
/// Used by Dashboard alerts and Smart Suggestions
final highInflationItemsProvider = Provider<List<InflationItemModel>>((ref) {
  final items = ref.watch(inflationItemsProvider);
  final inflationService = ref.watch(inflationServiceProvider);
  
  if (items.value == null) return [];
  
  // Threshold: 5% increase
  final highInflationItems = inflationService.getHighInflationItems(items.value!, 5.0);
  
  // Check and create notifications for high inflation (async, don't wait)
  inflationService.checkAndCreateInflationNotifications(
    items.value!,
    5.0,
  ).catchError((e) {
    // Silently fail - notifications are not critical
  });
  
  return highInflationItems;
});

/// SharedPreferences Provider (for API service caching)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Inflation API Service Provider
final inflationApiServiceProvider = FutureProvider<InflationApiService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return InflationApiService(prefs: prefs);
});

/// Current Inflation Rate Provider
/// Fetches the current inflation rate from API
/// Used by Dashboard, Predictions, Analytics, and Inflation Tracker
final inflationRateProvider = FutureProvider<double>((ref) async {
  final inflationService = ref.watch(inflationServiceProvider);
  final rate = await inflationService.getCurrentInflationRate();
  return rate ?? 0.0; // Default to 0.0 if API fails
});

/// Historical Inflation Rates Provider
/// Fetches historical inflation rates for the last 12 months
/// Used by Inflation Tracker and Analytics
final historicalInflationProvider = FutureProvider<List<double>>((ref) async {
  final inflationService = ref.watch(inflationServiceProvider);
  return await inflationService.getHistoricalInflationRates(12);
});

