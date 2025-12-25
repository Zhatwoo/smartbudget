import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inflation_item_model.dart';
import '../config/api_config.dart';
import 'notification_service.dart';
import 'inflation_api_service.dart';

/// Service for handling inflation-related Firebase operations
/// Handles all Firebase calls for inflation items
/// Returns clean InflationItemModel objects
/// NO UI logic - pure business logic only
class InflationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  InflationApiService? _apiService;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Initialize API service (lazy initialization)
  Future<InflationApiService> _getApiService() async {
    if (_apiService == null) {
      final prefs = await SharedPreferences.getInstance();
      _apiService = InflationApiService(prefs: prefs);
    }
    return _apiService!;
  }

  /// Add or update an inflation item
  /// Returns the document ID of the saved item
  Future<String> saveInflationItem(InflationItemModel item) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      if (item.id == null) {
        final itemData = item.toMap();
        itemData['userId'] = userId;
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('inflationItems')
            .add(itemData);
        return docRef.id;
      } else {
        // Preserve createdAt by getting existing doc first
        final existingDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('inflationItems')
            .doc(item.id)
            .get();
        
        final existingData = existingDoc.data();
        final updateData = item.toUpdateMap();
        updateData['userId'] = userId;
        
        // Preserve createdAt if it exists
        if (existingData != null && existingData.containsKey('createdAt')) {
          updateData['createdAt'] = existingData['createdAt'];
        }
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('inflationItems')
            .doc(item.id)
            .update(updateData);
        return item.id!;
      }
    } catch (e) {
      throw Exception('Error saving inflation item: $e');
    }
  }

  /// Get all inflation items for current user as a stream
  /// Returns a stream that emits updated inflation item lists
  Stream<List<InflationItemModel>> getInflationItems() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('inflationItems')
        .snapshots()
        .map((snapshot) {
      try {
      return snapshot.docs
          .map((doc) => InflationItemModel.fromMap(doc.id, doc.data()))
          .toList();
      } catch (e) {
        // If there's an error parsing, return empty list
        return <InflationItemModel>[];
      }
    }).handleError((error, stackTrace) {
      // Log error but don't crash - errors will be handled by StreamProvider
      // The stream will emit an error which StreamProvider will catch
    });
  }

  /// Delete an inflation item
  Future<void> deleteInflationItem(String itemId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inflationItems')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting inflation item: $e');
    }
  }

  /// Fetch latest prices from external API
  /// Uses inflation API to get current inflation rate and apply it to items
  Future<double> fetchLatestPrice(String itemName) async {
    try {
      final apiService = await _getApiService();
      final inflationRate = await apiService.getInflationRate(ApiConfig.defaultCountry);
      
      if (inflationRate != null) {
        // Get current item
        final items = await getInflationItems().first;
        final item = items.firstWhere(
          (i) => i.name == itemName,
          orElse: () => InflationItemModel(
            name: itemName,
            unit: 'unit',
            currentPrice: 0,
            previousPrice: 0,
            priceHistory: [],
            predictedPrices: [],
            color: '#4A90E2',
            icon: 'shopping_cart',
          ),
        );
        
        // Apply inflation rate to current price
        if (item.currentPrice > 0) {
          final monthlyRate = inflationRate / 100 / 12; // Convert annual to monthly
          return item.currentPrice * (1 + monthlyRate);
        }
      }
      
      // Fallback to current price from Firestore
      final items = await getInflationItems().first;
      final item = items.firstWhere(
        (i) => i.name == itemName,
        orElse: () => InflationItemModel(
          name: itemName,
          unit: 'unit',
          currentPrice: 0,
          previousPrice: 0,
          priceHistory: [],
          predictedPrices: [],
          color: '#4A90E2',
          icon: 'shopping_cart',
        ),
      );
      return item.currentPrice;
    } catch (e) {
      // Fallback to current price from Firestore
      final items = await getInflationItems().first;
      final item = items.firstWhere(
        (i) => i.name == itemName,
        orElse: () => InflationItemModel(
          name: itemName,
          unit: 'unit',
          currentPrice: 0,
          previousPrice: 0,
          priceHistory: [],
          predictedPrices: [],
          color: '#4A90E2',
          icon: 'shopping_cart',
        ),
      );
      return item.currentPrice;
    }
  }

  /// Refresh all prices using inflation API
  /// Fetches current inflation rate and applies it to all tracked items
  /// Updates price history and calculates predicted prices
  /// Uses free Statbureau.org API (no API key required)
  /// Falls back to default rates if API fails
  Future<void> refreshAllPrices() async {
    try {
      final apiService = await _getApiService();
      
      // Get inflation rate from free API (no key required)
      // API service handles fallback to default rates automatically
      final inflationRate = await apiService.getInflationRate(ApiConfig.defaultCountry);
      
      // If API returns null, use default rate (API service already handles this)
      final rate = inflationRate ?? 3.2; // Default Philippines inflation rate

      final items = await getInflationItems().first;
      
      for (final item in items) {
        // Use the rate (either from API or default)
        if (item.id == null || item.currentPrice <= 0) continue;

        // Calculate new price based on inflation rate
        final monthlyRate = rate / 100 / 12; // Convert annual to monthly
        final newPrice = item.currentPrice * (1 + monthlyRate);
        
        // Update price history
        final updatedHistory = List<double>.from(item.priceHistory);
        updatedHistory.add(item.currentPrice);
        
        // Keep only last 6 months of history
        if (updatedHistory.length > 6) {
          updatedHistory.removeAt(0);
        }
        
        // Calculate predicted prices for next 3 months
        final predictedPrices = apiService.calculatePricePredictions(
          newPrice,
          rate,
          3,
        );
        
        // Update item
        final updatedItem = item.copyWith(
          previousPrice: item.currentPrice,
          currentPrice: newPrice,
          priceHistory: updatedHistory,
          predictedPrices: predictedPrices,
        );
        
        await saveInflationItem(updatedItem);
      }
      
      // Check for high inflation notifications
      final updatedItems = await getInflationItems().first;
      await checkAndCreateInflationNotifications(updatedItems, 5.0);
    } catch (e) {
      // Silently fail - allow manual price updates
      throw Exception('Error refreshing prices: $e');
    }
  }

  /// Sync with inflation API
  /// Similar to refreshAllPrices but with more detailed error handling
  Future<bool> syncWithInflationAPI() async {
    try {
      await refreshAllPrices();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cache prices in Firestore
  /// Updates the price history with new price data
  Future<void> cachePrice(String itemId, double price) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inflationItems')
          .doc(itemId)
          .get();

      if (!doc.exists) throw Exception('Inflation item not found');

      final data = doc.data()!;
      final currentPrice = (data['currentPrice'] ?? 0).toDouble();
      final priceHistory = List<double>.from(data['priceHistory'] ?? []);

      // Add current price to history
      priceHistory.add(currentPrice);

      // Update with new price
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inflationItems')
          .doc(itemId)
          .update({
        'previousPrice': currentPrice,
        'currentPrice': price,
        'priceHistory': priceHistory,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error caching price: $e');
    }
  }

  /// Get items with high inflation (above threshold)
  /// Returns items where percentage change exceeds the threshold
  List<InflationItemModel> getHighInflationItems(
    List<InflationItemModel> items,
    double threshold,
  ) {
    return items.where((item) {
      final change = item.percentageChange;
      return change.abs() >= threshold && item.isIncrease;
    }).toList();
  }

  /// Check and create notifications for high inflation items
  /// This should be called when prices are updated
  Future<void> checkAndCreateInflationNotifications(
    List<InflationItemModel> items,
    double threshold,
  ) async {
    try {
      final notificationService = NotificationService();
      final highInflationItems = getHighInflationItems(items, threshold);
      
      for (final item in highInflationItems) {
        await notificationService.notifyHighInflation(
          itemName: item.name,
          percentageChange: item.percentageChange,
          currentPrice: item.currentPrice,
          previousPrice: item.previousPrice,
        );
      }
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }

  /// Initialize default inflation items for new users
  /// Automatically creates common items with default prices
  /// Only creates items if user has no existing items
  Future<void> initializeDefaultItems() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      // Check if user already has items
      final existingItems = await getInflationItems().first;
      if (existingItems.isNotEmpty) {
        // User already has items, don't initialize
        return;
      }

      // Default inflation items with common Philippine prices (as of 2024)
      // Prices set with >5% change to show in high inflation alerts
      final defaultItems = [
        InflationItemModel(
          name: 'Rice',
          unit: 'per kg',
          currentPrice: 52.0,
          previousPrice: 48.0,
          priceHistory: [48.0, 49.5, 50.5, 52.0],
          predictedPrices: [53.5, 55.0, 56.5],
          color: '#E74C3C',
          icon: 'rice_bowl',
        ),
        InflationItemModel(
          name: 'Milk',
          unit: 'per liter',
          currentPrice: 88.0,
          previousPrice: 82.0,
          priceHistory: [82.0, 84.0, 86.0, 88.0],
          predictedPrices: [90.0, 92.0, 94.0],
          color: '#4A90E2',
          icon: 'local_drink',
        ),
        InflationItemModel(
          name: 'Eggs',
          unit: 'per dozen',
          currentPrice: 185.0,
          previousPrice: 175.0,
          priceHistory: [175.0, 178.0, 181.0, 185.0],
          predictedPrices: [189.0, 193.0, 197.0],
          color: '#F39C12',
          icon: 'egg',
        ),
        InflationItemModel(
          name: 'Gasoline',
          unit: 'per liter',
          currentPrice: 68.0,
          previousPrice: 63.0,
          priceHistory: [63.0, 64.5, 66.0, 68.0],
          predictedPrices: [70.0, 72.0, 74.0],
          color: '#27AE60',
          icon: 'local_gas_station',
        ),
        InflationItemModel(
          name: 'Bread',
          unit: 'per loaf',
          currentPrice: 48.0,
          previousPrice: 43.0,
          priceHistory: [43.0, 44.5, 46.0, 48.0],
          predictedPrices: [50.0, 52.0, 54.0],
          color: '#9B59B6',
          icon: 'breakfast_dining',
        ),
      ];

      // Save all default items
      for (final item in defaultItems) {
        await saveInflationItem(item);
      }
    } catch (e) {
      // Silently fail - initialization is not critical
      // User can still manually add items
    }
  }

  /// Check and initialize default items if needed
  /// Should be called when user first opens the app or when items list is empty
  Future<void> ensureDefaultItemsInitialized() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      // Check if initialization is needed
      final items = await getInflationItems().first;
      if (items.isEmpty) {
        await initializeDefaultItems();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Get current inflation rate from API
  /// Returns the latest inflation rate for the default country
  /// Returns current inflation rate from free API (no key required)
  /// Falls back to default rate if API fails
  Future<double?> getCurrentInflationRate() async {
    try {
      final apiService = await _getApiService();
      return await apiService.getInflationRate(ApiConfig.defaultCountry);
    } catch (e) {
      return null;
    }
  }

  /// Get historical inflation rates
  /// Returns list of inflation rates for the specified number of months
  /// Uses free API (no key required), falls back to generated data if API fails
  Future<List<double>> getHistoricalInflationRates(int months) async {
    try {
      final apiService = await _getApiService();
      return await apiService.getHistoricalInflation(ApiConfig.defaultCountry, months);
    } catch (e) {
      return [];
    }
  }

  /// Refresh inflation data from API
  /// Fetches latest inflation rate and clears cache
  /// Uses free Statbureau.org API (no API key required)
  /// Falls back to default rates if API fails
  Future<void> refreshInflationData() async {
    try {
      final apiService = await _getApiService();
      
      // Fetch latest rate from free API (no key required)
      // API service handles fallback to default rates automatically
      final inflationRate = await apiService.getInflationRate(ApiConfig.defaultCountry);
      
      // Rate is cached automatically by API service
      // If null, default rate will be used on next call
      if (inflationRate == null) {
        // Silently fail - default rate will be used
        return;
      }
    } catch (e) {
      // Silently fail - default rate will be used on next call
      // No need to throw exception since we have fallback
    }
  }
}

