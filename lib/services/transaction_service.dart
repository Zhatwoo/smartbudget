import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

/// Service for handling transaction-related Firebase operations
/// Handles all Firebase calls for transactions
/// Returns clean TransactionModel objects
/// NO UI logic - pure business logic only
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add a new transaction to Firestore
  /// Returns the document ID of the created transaction
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated. Please log in to save transactions.');
      }

      // Add userId to transaction data for easier querying
      final transactionData = transaction.toMap();
      transactionData['userId'] = userId;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(transactionData);

      return docRef.id;
    } catch (e) {
      // Provide more detailed error message
      if (e.toString().contains('not authenticated')) {
        rethrow;
      }
      throw Exception('Error adding transaction: $e');
    }
  }

  /// Get all transactions for current user as a stream
  /// Returns a stream that emits updated transaction lists
  /// SECURITY: Only returns transactions for the authenticated user
  Stream<List<TransactionModel>> getTransactions() {
    final userId = _currentUserId;
    if (userId == null) {
      // Return empty stream if not authenticated
      return Stream.value([]);
    }

    // SECURITY: Use nested collection structure to ensure user isolation
    // Path: users/{userId}/transactions/{transactionId}
    // This ensures Firestore rules can properly enforce user-level access
    return _firestore
        .collection('users')
        .doc(userId) // Explicitly use authenticated user's ID
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(500) // Limit to 500 most recent transactions for performance
        .snapshots()
        .map((snapshot) {
      // Additional security: Filter by userId in the data as well
      final transactions = snapshot.docs
          .where((doc) {
            // Double-check that userId matches (extra security layer)
            final data = doc.data();
            final docUserId = data['userId'] as String?;
            return docUserId == null || docUserId == userId;
          })
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // Sort by date descending (most recent first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    }).handleError((error, stackTrace) {
      // Log error but don't crash - return empty list
      // Error is handled silently to prevent crashes
      return <TransactionModel>[];
    });
  }

  /// Get transactions by date range
  /// Returns a list of transactions within the specified date range
  /// SECURITY: Only returns transactions for the authenticated user
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId) // Explicitly use authenticated user's ID
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      // Additional security: Filter by userId in the data
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final docUserId = data['userId'] as String?;
            return docUserId == null || docUserId == userId;
          })
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  /// Get transactions by category
  /// Returns a list of transactions filtered by category
  /// SECURITY: Only returns transactions for the authenticated user
  Future<List<TransactionModel>> getTransactionsByCategory(String category) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId) // Explicitly use authenticated user's ID
          .collection('transactions')
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      // Additional security: Filter by userId in the data
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final docUserId = data['userId'] as String?;
            return docUserId == null || docUserId == userId;
          })
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching transactions by category: $e');
    }
  }

  /// Update an existing transaction
  /// Preserves createdAt timestamp
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');
      if (transaction.id == null) throw Exception('Transaction ID is required');

      // Preserve createdAt by getting existing doc first
      final existingDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .get();
      
      final existingData = existingDoc.data();
      final updateData = transaction.toUpdateMap();
      
      // Preserve createdAt if it exists
      if (existingData != null && existingData.containsKey('createdAt')) {
        updateData['createdAt'] = existingData['createdAt'];
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .update(updateData);
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }

  /// Calculate total balance from transactions
  /// Returns the net balance (income - expenses)
  double calculateTotalBalance(List<TransactionModel> transactions) {
    return transactions.fold(0.0, (sum, t) {
      if (t.type == 'income') {
        return sum + t.amount.abs();
      } else {
        return sum - t.amount.abs();
      }
    });
  }

  /// Calculate total income from transactions
  double calculateTotalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Calculate total expenses from transactions
  double calculateTotalExpenses(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }
}

