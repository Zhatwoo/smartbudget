class BudgetModel {
  final String? id;
  final String category;
  final double limit;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final String? userId;

  BudgetModel({
    this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.startDate,
    required this.endDate,
    this.userId,
  });

  double get remaining => limit - spent;
  double get percentage => limit > 0 ? (spent / limit) * 100 : 0;
  bool get isExceeded => spent > limit;
  bool get isAtRisk => percentage >= 80 && percentage < 100;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'category': category,
      'limit': limit,
      'spent': spent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userId': userId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }
  
  // Update map (for updates, preserves createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'category': category,
      'limit': limit,
      'spent': spent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userId': userId,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Firestore document
  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    // Safe date parsing with fallback
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is DateTime) {
        return dateValue;
      }
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return BudgetModel(
      id: id,
      category: map['category'] ?? '',
      limit: (map['limit'] ?? 0).toDouble(),
      spent: (map['spent'] ?? 0).toDouble(),
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      userId: map['userId'],
    );
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? limit,
    double? spent,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
    );
  }
}

