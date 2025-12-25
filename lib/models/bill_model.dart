import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BillModel {
  final String? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final IconData icon;
  final String category;
  final bool isRecurring;
  final int? recurringDays; // Days between recurring bills (e.g., 30 for monthly)
  final DateTime createdAt;
  final DateTime updatedAt;

  BillModel({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.icon,
    required this.category,
    this.isRecurring = false,
    this.recurringDays,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate days until due
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  // Check if overdue
  bool get isOverdue => daysUntilDue < 0;

  // Check if due soon (within 3 days)
  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= 3;

  // Get status color
  Color get statusColor {
    if (isOverdue) return const Color(0xFFE74C3C);
    if (isDueSoon) return const Color(0xFFF39C12);
    return Colors.grey;
  }

  // Get status text
  String get statusText {
    if (isOverdue) return 'Overdue';
    if (daysUntilDue == 0) return 'Due today';
    if (daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in $daysUntilDue days';
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'category': category,
      'isRecurring': isRecurring,
      'recurringDays': recurringDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory BillModel.fromMap(String id, Map<String, dynamic> map) {
    // Use constant IconData for tree-shaking compatibility
    const defaultIcon = Icons.receipt_long;
    final iconCodePoint = map['iconCodePoint'] as int?;
    
    // Safe date parsing with fallback (handle both Timestamp and String formats)
    DateTime parseDueDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is Timestamp) {
        return dateValue.toDate();
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
    
    return BillModel(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: parseDueDate(map['dueDate']),
      icon: iconCodePoint != null
          ? IconData(
              iconCodePoint,
              fontFamily: map['iconFontFamily'] as String?,
              fontPackage: map['iconFontPackage'] as String?,
            )
          : defaultIcon,
      category: map['category'] ?? 'Bills',
      isRecurring: map['isRecurring'] ?? false,
      recurringDays: map['recurringDays'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create copy with method
  BillModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    IconData? icon,
    String? category,
    bool? isRecurring,
    int? recurringDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringDays: recurringDays ?? this.recurringDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


