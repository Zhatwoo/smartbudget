import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'notification_service.dart';

/// Service for handling budget-related Firebase operations
/// Handles all Firebase calls for budgets
/// Returns clean BudgetModel objects
/// NO UI logic - pure business logic only
class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add or update a budget
  /// Returns the document ID of the saved budget
  Future<String> saveBudget(BudgetModel budget) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final budgetData = budget.toMap();
      budgetData['userId'] = userId;

      if (budget.id == null) {
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .add(budgetData);
        return docRef.id;
      } else {
        // For updates, preserve createdAt by getting existing doc first
        final existingDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc(budget.id)
            .get();
        
        final existingData = existingDoc.data();
        final updateData = budget.toUpdateMap();
        
        // Preserve createdAt if it exists
        if (existingData != null && existingData.containsKey('createdAt')) {
          updateData['createdAt'] = existingData['createdAt'];
        }
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc(budget.id)
            .update(updateData);
        return budget.id!;
      }
    } catch (e) {
      throw Exception('Error saving budget: $e');
    }
  }

  /// Get all budgets for current user as a stream
  /// Returns a stream that emits updated budget lists
  Stream<List<BudgetModel>> getBudgets() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(budgetId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting budget: $e');
    }
  }

  /// Calculate spent amount for a budget category from transactions
  /// This is used to update budget.spent based on actual transactions
  double calculateSpentForCategory(
    String category,
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    return transactions
        .where((t) =>
            t.category == category &&
            t.type == 'expense' &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Update budget spent amounts based on transactions
  /// This compares budgets vs transactions and updates spent values
  Future<void> updateBudgetSpent(
    BudgetModel budget,
    List<TransactionModel> transactions,
  ) async {
    final spent = calculateSpentForCategory(
      budget.category,
      transactions,
      budget.startDate,
      budget.endDate,
    );

    final updatedBudget = budget.copyWith(spent: spent);
    await saveBudget(updatedBudget);
  }

  /// Get budgets with overspending highlighted
  /// Returns budgets with isExceeded flag set based on transactions
  List<BudgetModel> getBudgetsWithOverspending(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    return budgets.map((budget) {
      final spent = calculateSpentForCategory(
        budget.category,
        transactions,
        budget.startDate,
        budget.endDate,
      );
      return budget.copyWith(spent: spent);
    }).toList();
  }

  /// Check and create notifications for budget alerts
  /// This should be called periodically or when transactions are added
  Future<void> checkAndCreateBudgetNotifications(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) async {
    // Import notification service dynamically to avoid circular dependency
    // This will be called from providers or background tasks
    try {
      final notificationService = NotificationService();
      
      for (final budget in budgets) {
        final spent = calculateSpentForCategory(
          budget.category,
          transactions,
          budget.startDate,
          budget.endDate,
        );
        
        final percentage = budget.limit > 0 ? (spent / budget.limit * 100) : 0.0;
        
        // Check if budget is exceeded
        if (spent > budget.limit) {
          await notificationService.notifyBudgetExceeded(
            category: budget.category,
            limit: budget.limit,
            spent: spent,
          );
        }
        // Check if budget is at risk (80% or more)
        else if (percentage >= 80.0 && percentage < 100.0) {
          await notificationService.notifyBudgetAtRisk(
            category: budget.category,
            limit: budget.limit,
            spent: spent,
            percentage: percentage.toDouble(),
          );
        }
      }
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }
}

