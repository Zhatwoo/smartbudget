import 'package:flutter/material.dart';
import '../screens/budgetplanner.dart';
import '../screens/inflationTracker.dart';
import '../screens/analyticsReport.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: NotificationType.budgetExceeded,
      title: 'Budget Limit Exceeded',
      message: 'You have exceeded your Food budget by ₱2,500.00',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      category: 'Food',
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.priceIncreased,
      title: 'Price Increase Alert',
      message: 'Rice price increased by 5.2% this month',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
      itemName: 'Rice',
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.predictiveAlert,
      title: 'Upcoming Month Prediction',
      message: 'Your expenses are predicted to increase by 8.5% next month',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.budgetExceeded,
      title: 'Budget Limit Warning',
      message: 'You are at 85% of your Transport budget',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
      category: 'Transport',
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.priceIncreased,
      title: 'Price Increase Alert',
      message: 'Gasoline price increased by 3.8% this month',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      itemName: 'Gasoline',
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.predictiveAlert,
      title: 'Spending Trend Alert',
      message: 'Your spending trend suggests you may exceed budget next month',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  int get _unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          category: _notifications[index].category,
          itemName: _notifications[index].itemName,
        );
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          message: _notifications[i].message,
          timestamp: _notifications[i].timestamp,
          isRead: true,
          category: _notifications[i].category,
          itemName: _notifications[i].itemName,
        );
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    _markAsRead(notification.id);

    switch (notification.type) {
      case NotificationType.budgetExceeded:
        Navigator.of(context).pushNamed('/budget-planner');
        break;
      case NotificationType.priceIncreased:
        Navigator.of(context).pushNamed('/inflation-tracker');
        break;
      case NotificationType.predictiveAlert:
        Navigator.of(context).pushNamed('/analytics-report');
        break;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.budgetExceeded:
        return Icons.account_balance_wallet;
      case NotificationType.priceIncreased:
        return Icons.trending_up;
      case NotificationType.predictiveAlert:
        return Icons.lightbulb_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.budgetExceeded:
        return const Color(0xFFE74C3C); // Red
      case NotificationType.priceIncreased:
        return const Color(0xFFF39C12); // Orange
      case NotificationType.predictiveAlert:
        return const Color(0xFF4A90E2); // Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header (matching dashboard style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Unread Count Badge
                        if (_unreadCount > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: const Color(0xFF4A90E2).withOpacity(0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4A90E2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Color(0xFF4A90E2),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Notifications List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20.0),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              final color = _getNotificationColor(notification.type);
                              final icon = _getNotificationIcon(notification.type);

                              return Dismissible(
                                key: Key(notification.id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE74C3C),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  _deleteNotification(notification.id);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: notification.isRead
                                          ? Colors.grey.withOpacity(0.15)
                                          : color.withOpacity(0.3),
                                      width: notification.isRead ? 1.5 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () => _handleNotificationTap(notification),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              icon,
                                              color: color,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notification.title,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: notification.isRead
                                                              ? FontWeight.w600
                                                              : FontWeight.bold,
                                                          color: Colors.black87,
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!notification.isRead)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: color,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  notification.message,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _formatTimestamp(notification.timestamp),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Action Button
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey.shade400,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notification Models
enum NotificationType {
  budgetExceeded,
  priceIncreased,
  predictiveAlert,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? category;
  final String? itemName;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.category,
    this.itemName,
  });
}

