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
      if (userId == null) throw Exception('User not authenticated');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(transaction.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Error adding transaction: $e');
    }
  }

  /// Get all transactions for current user as a stream
  /// Returns a stream that emits updated transaction lists
  Stream<List<TransactionModel>> getTransactions() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get transactions by date range
  /// Returns a list of transactions within the specified date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  /// Get transactions by category
  /// Returns a list of transactions filtered by category
  Future<List<TransactionModel>> getTransactionsByCategory(String category) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
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

