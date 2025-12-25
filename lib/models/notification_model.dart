/// Notification Model for Firestore
class NotificationModel {
  final String? id;
  final String type; // 'budgetExceeded', 'priceIncreased', 'predictiveAlert'
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? category; // For budget notifications
  final String? itemName; // For inflation notifications
  final Map<String, dynamic>? metadata; // Additional data

  NotificationModel({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.category,
    this.itemName,
    this.metadata,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'category': category,
      'itemName': itemName,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Firestore document
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      category: map['category'],
      itemName: map['itemName'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? category,
    String? itemName,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      metadata: metadata ?? this.metadata,
    );
  }
}


