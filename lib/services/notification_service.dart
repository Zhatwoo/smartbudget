import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Service for handling Firebase Cloud Messaging (FCM) notifications
/// Handles push notifications and deep linking
/// Also handles in-app notifications stored in Firestore
/// NO UI logic - pure business logic only
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Initialize notification service
  /// Request permissions and set up message handlers
  Future<void> initialize() async {
    // Request permission for iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null && _currentUserId != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        if (_currentUserId != null) {
          _saveTokenToFirestore(newToken);
        }
      });
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      });
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
      final userId = _currentUserId;
      if (userId == null) return;

      final exceeded = spent - limit;
      final notification = NotificationModel(
        type: 'budgetExceeded',
        title: 'Budget Limit Exceeded',
        message: 'You have exceeded your $category budget by ₱${exceeded.toStringAsFixed(2)}',
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
      final userId = _currentUserId;
      if (userId == null) return;

      final remaining = limit - spent;
      final notification = NotificationModel(
        type: 'budgetExceeded',
        title: 'Budget Limit Warning',
        message: 'You are at ${percentage.toStringAsFixed(0)}% of your $category budget. ₱${remaining.toStringAsFixed(2)} remaining.',
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
    } catch (e) {
      // Silently fail
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
      final userId = _currentUserId;
      if (userId == null) return;

      final change = predictedAmount - currentAmount;
      final changePercent = currentAmount > 0 
          ? (change / currentAmount * 100)
          : 0.0;

      String title;
      String message;

      if (category != null) {
        title = 'Spending Prediction for $category';
        message = 'Your $category expenses are predicted to be ₱${predictedAmount.toStringAsFixed(2)} $period';
      } else {
        title = 'Upcoming Month Prediction';
        if (changePercent > 10) {
          message = 'Your expenses are predicted to increase by ${changePercent.toStringAsFixed(1)}% $period';
        } else if (changePercent < -10) {
          message = 'Your expenses are predicted to decrease by ${changePercent.abs().toStringAsFixed(1)}% $period';
        } else {
          message = 'Your expenses are predicted to be ₱${predictedAmount.toStringAsFixed(2)} $period';
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
      final userId = _currentUserId;
      if (userId == null) return;

      // If predicted spending exceeds budget, create alert
      if (predictedAmount > budgetLimit) {
        final exceeded = predictedAmount - budgetLimit;
        final notification = NotificationModel(
          type: 'predictiveAlert',
          title: 'Budget Warning: $category',
          message: 'Your predicted spending (₱${predictedAmount.toStringAsFixed(0)}) exceeds your $category budget by ₱${exceeded.toStringAsFixed(0)}',
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

