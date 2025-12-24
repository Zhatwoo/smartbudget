class TransactionModel {
  final String? id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // 'expense' or 'income'
  final String? notes;
  final String? receiptUrl;

  TransactionModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.notes,
    this.receiptUrl,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      type: map['type'] ?? 'expense',
      notes: map['notes'],
      receiptUrl: map['receiptUrl'],
    );
  }
  
  // Update map (for updates, preserves createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create copy with method
  TransactionModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? type,
    String? notes,
    String? receiptUrl,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}

