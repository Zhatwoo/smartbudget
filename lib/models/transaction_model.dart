import 'package:cloud_firestore/cloud_firestore.dart';

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
      'date': Timestamp.fromDate(date), // Use Timestamp for proper querying
      'type': type,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(now), // Use Timestamp for proper ordering
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  // Create from Firestore document
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    // Handle both Timestamp and ISO string formats for backward compatibility
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else {
        return DateTime.now();
      }
    }

    return TransactionModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: parseDate(map['date']),
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
      'date': Timestamp.fromDate(date), // Use Timestamp for proper querying
      'type': type,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
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

