import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../utils/currency_formatter.dart';

/// Service for handling Firebase Cloud Messaging (FCM) notifications
/// Handles push notifications and deep linking
/// Also handles in-app notifications stored in Firestore
/// NO UI logic - pure business logic only
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences? _prefs;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if notifications are enabled
  Future<bool> _areNotificationsEnabled() async {
    await _initPrefs();
    return _prefs?.getBool('pref_notifications_enabled') ?? true;
  }

  /// Check if budget alerts are enabled
  Future<bool> _areBudgetAlertsEnabled() async {
    await _initPrefs();
    return _prefs?.getBool('pref_budget_alerts_enabled') ?? true;
  }

  /// Check if inflation alerts are enabled
  Future<bool> _areInflationAlertsEnabled() async {
    await _initPrefs();
    return _prefs?.getBool('pref_inflation_alerts_enabled') ?? true;
  }

  /// Check if spending alerts are enabled
  Future<bool> _areSpendingAlertsEnabled() async {
    await _initPrefs();
    return _prefs?.getBool('pref_spending_alerts_enabled') ?? true;
  }

  /// Get currency from preferences
  Future<String> _getCurrency() async {
    await _initPrefs();
    return _prefs?.getString('pref_currency') ?? 'PHP (₱)';
  }

  /// Initialize notification service
  /// Request permissions and set up message handlers
  Future<void> initialize() async {
    try {
      // Request permission for iOS (Android doesn't need this)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // For Android, permission is granted by default
      // For iOS, check if authorized
      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
                          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        // Get FCM token (works for both Android and iOS)
        final token = await _messaging.getToken();
        if (token != null && _currentUserId != null) {
          await _saveTokenToFirestore(token);
        }

        // Set up foreground message handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          // Handle foreground messages here
          // You can show local notifications or update UI
          _handleForegroundMessage(message);
        });

        // Set up message opened handler (when user taps notification)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          // Handle notification tap here
          _handleNotificationTap(message);
        });

        // Check if app was opened from a notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          // Wait a bit to ensure user is logged in
          await Future.delayed(const Duration(seconds: 1));
          if (_currentUserId != null) {
            await _saveTokenToFirestore(newToken);
          }
        });
      }
    } catch (e) {
      // Silently fail - notification initialization errors shouldn't crash the app
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // You can show a local notification or update UI here
    // For now, we'll just create an in-app notification in Firestore
    try {
      if (_currentUserId != null) {
        final notification = NotificationModel(
          type: message.data['type'] ?? 'general',
          title: message.notification?.title ?? message.data['title'] ?? 'Notification',
          message: message.notification?.body ?? message.data['body'] ?? '',
          timestamp: message.sentTime ?? DateTime.now(),
          isRead: false,
          metadata: message.data,
        );
        await createNotification(notification);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Extract deep link and navigate
    // This will be handled by the app's navigation system
    final deepLink = getDeepLinkFromNotification(message);
    // Navigation will be handled by the UI layer
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      // Use set with merge to handle cases where user document might not exist
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - token saving is not critical
    }
  }

  /// Create in-app notification in Firestore
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  /// Get all notifications for current user as a stream
  Stream<List<NotificationModel>> getNotifications() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  /// Send notification when budget is exceeded
  /// This is called by BudgetService when overspending is detected
  Future<void> notifyBudgetExceeded({
    required String category,
    required double limit,
    required double spent,
  }) async {
    try {
      // Check if notifications and budget alerts are enabled
      if (!await _areNotificationsEnabled() || !await _areBudgetAlertsEnabled()) {
        return;
      }

      final userId = _currentUserId;
      if (userId == null) return;

      final exceeded = spent - limit;
      final currency = await _getCurrency();
      final notification = NotificationModel(
        type: 'budgetExceeded',
        title: 'Budget Limit Exceeded',
        message: 'You have exceeded your $category budget by ${CurrencyFormatter.format(exceeded, currency, decimals: 2)}',
        timestamp: DateTime.now(),
        isRead: false,
        category: category,
        metadata: {
          'limit': limit,
          'spent': spent,
          'exceeded': exceeded,
        },
      );

      await createNotification(notification);
      
      // Send push notification
      await _sendPushNotification(
        title: notification.title,
        body: notification.message,
        data: {'type': 'budget', 'screen': '/budget-planner'},
      );
    } catch (e) {
      // Silently fail - notification creation is not critical
    }
  }

  /// Send notification when budget is at risk (80%+)
  Future<void> notifyBudgetAtRisk({
    required String category,
    required double limit,
    required double spent,
    required double percentage,
  }) async {
    try {
      // Check if notifications and budget alerts are enabled
      if (!await _areNotificationsEnabled() || !await _areBudgetAlertsEnabled()) {
        return;
      }

      final userId = _currentUserId;
      if (userId == null) return;

      final remaining = limit - spent;
      final currency = await _getCurrency();
      final notification = NotificationModel(
        type: 'budgetExceeded',
        title: 'Budget Limit Warning',
        message: 'You are at ${percentage.toStringAsFixed(0)}% of your $category budget. ${CurrencyFormatter.format(remaining, currency, decimals: 2)} remaining.',
        timestamp: DateTime.now(),
        isRead: false,
        category: category,
        metadata: {
          'limit': limit,
          'spent': spent,
          'percentage': percentage,
          'remaining': remaining,
        },
      );

      await createNotification(notification);
      
      // Send push notification
      await _sendPushNotification(
        title: notification.title,
        body: notification.message,
        data: {'type': 'budget', 'screen': '/budget-planner'},
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Send notification for high inflation items
  /// This is called by InflationService when high inflation is detected
  Future<void> notifyHighInflation({
    required String itemName,
    required double percentageChange,
    required double currentPrice,
    required double previousPrice,
  }) async {
    try {
      // Check if notifications and inflation alerts are enabled
      if (!await _areNotificationsEnabled() || !await _areInflationAlertsEnabled()) {
        return;
      }

      final userId = _currentUserId;
      if (userId == null) return;

      final isIncrease = percentageChange > 0;
      final notification = NotificationModel(
        type: 'priceIncreased',
        title: 'Price ${isIncrease ? 'Increase' : 'Decrease'} Alert',
        message: '$itemName price ${isIncrease ? 'increased' : 'decreased'} by ${percentageChange.abs().toStringAsFixed(1)}% this month',
        timestamp: DateTime.now(),
        isRead: false,
        itemName: itemName,
        metadata: {
          'percentageChange': percentageChange,
          'currentPrice': currentPrice,
          'previousPrice': previousPrice,
        },
      );

      await createNotification(notification);
      
      // Send push notification
      await _sendPushNotification(
        title: notification.title,
        body: notification.message,
        data: {'type': 'inflation', 'screen': '/inflation-tracker'},
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Send push notification via FCM
  Future<void> _sendPushNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if notifications are enabled
      if (!await _areNotificationsEnabled()) {
        return;
      }

      // Get FCM token from Firestore
      final userId = _currentUserId;
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) return;

      // Note: In a production app, you would send notifications via a backend server
      // For now, we'll just create in-app notifications
      // Push notifications should be sent from your backend using the FCM Admin SDK
    } catch (e) {
      // Silently fail - push notifications are not critical
    }
  }

  /// Send notification for expense predictions
  /// This is called by PredictionService when predictions are available
  Future<void> notifyExpensePrediction({
    required double predictedAmount,
    required double currentAmount,
    required String period,
    String? category,
  }) async {
    try {
      // Check if notifications and spending alerts are enabled
      if (!await _areNotificationsEnabled() || !await _areSpendingAlertsEnabled()) {
        return;
      }

      final userId = _currentUserId;
      if (userId == null) return;

      final change = predictedAmount - currentAmount;
      final changePercent = currentAmount > 0 
          ? (change / currentAmount * 100)
          : 0.0;

      String title;
      String message;
      final currency = await _getCurrency();

      if (category != null) {
        title = 'Spending Prediction for $category';
        message = 'Your $category expenses are predicted to be ${CurrencyFormatter.format(predictedAmount, currency, decimals: 2)} $period';
      } else {
        title = 'Upcoming Month Prediction';
        if (changePercent > 10) {
          message = 'Your expenses are predicted to increase by ${changePercent.toStringAsFixed(1)}% $period';
        } else if (changePercent < -10) {
          message = 'Your expenses are predicted to decrease by ${changePercent.abs().toStringAsFixed(1)}% $period';
        } else {
          message = 'Your expenses are predicted to be ${CurrencyFormatter.format(predictedAmount, currency, decimals: 2)} $period';
        }
      }

      final notification = NotificationModel(
        type: 'predictiveAlert',
        title: title,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        category: category,
        metadata: {
          'predictedAmount': predictedAmount,
          'currentAmount': currentAmount,
          'change': change,
          'changePercent': changePercent,
          'period': period,
        },
      );

      await createNotification(notification);
    } catch (e) {
      // Silently fail
    }
  }

  /// Check and create notifications for predictions vs budgets
  /// This should be called when predictions are calculated
  Future<void> checkPredictionBudgetAlerts({
    required double predictedAmount,
    required double budgetLimit,
    required String category,
  }) async {
    try {
      // Check if notifications and budget alerts are enabled
      if (!await _areNotificationsEnabled() || !await _areBudgetAlertsEnabled()) {
        return;
      }

      final userId = _currentUserId;
      if (userId == null) return;

      // If predicted spending exceeds budget, create alert
      if (predictedAmount > budgetLimit) {
        final exceeded = predictedAmount - budgetLimit;
        final currency = await _getCurrency();
        final notification = NotificationModel(
          type: 'predictiveAlert',
          title: 'Budget Warning: $category',
          message: 'Your predicted spending (${CurrencyFormatter.format(predictedAmount, currency)}) exceeds your $category budget by ${CurrencyFormatter.format(exceeded, currency)}',
          timestamp: DateTime.now(),
          isRead: false,
          category: category,
          metadata: {
            'predictedAmount': predictedAmount,
            'budgetLimit': budgetLimit,
            'exceeded': exceeded,
          },
        );

        await createNotification(notification);
        
        // Send push notification
        await _sendPushNotification(
          title: notification.title,
          body: notification.message,
          data: {'type': 'budget', 'screen': '/budget-planner'},
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Handle notification tap and deep link to screen
  /// This should be called from the app's notification handler
  String? getDeepLinkFromNotification(RemoteMessage message) {
    final data = message.data;
    
    // Extract screen route from notification data
    if (data.containsKey('screen')) {
      return data['screen'];
    }
    
    // Default deep links based on notification type
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'budget':
          return '/budget-planner';
        case 'inflation':
          return '/inflation-tracker';
        case 'prediction':
          return '/predictions';
        default:
          return '/home';
      }
    }
    
    return '/home';
  }
}

