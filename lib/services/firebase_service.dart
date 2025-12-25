import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/inflation_item_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== TRANSACTIONS ====================

  // Add a new transaction
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final userId = currentUserId;
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

  // Get all transactions for current user
  Stream<List<TransactionModel>> getTransactions() {
    final userId = currentUserId;
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

  // Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = currentUserId;
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

  // Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final userId = currentUserId;
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

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      final userId = currentUserId;
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

  // ==================== BUDGETS ====================

  // Add or update budget
  Future<String> saveBudget(BudgetModel budget) async {
    try {
      final userId = currentUserId;
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

  // Get all budgets for current user
  Stream<List<BudgetModel>> getBudgets() {
    final userId = currentUserId;
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

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      final userId = currentUserId;
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

  // ==================== INFLATION ITEMS ====================

  // Add or update inflation item
  Future<String> saveInflationItem(InflationItemModel item) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      if (item.id == null) {
        final itemData = item.toMap();
        itemData['userId'] = userId;
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('inflationItems')
            .add(itemData);
        return docRef.id;
      } else {
        // Preserve createdAt by getting existing doc first
        final existingDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('inflationItems')
            .doc(item.id)
            .get();
        
        final existingData = existingDoc.data();
        final updateData = item.toUpdateMap();
        updateData['userId'] = userId;
        
        // Preserve createdAt if it exists
        if (existingData != null && existingData.containsKey('createdAt')) {
          updateData['createdAt'] = existingData['createdAt'];
        }
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('inflationItems')
            .doc(item.id)
            .update(updateData);
        return item.id!;
      }
    } catch (e) {
      throw Exception('Error saving inflation item: $e');
    }
  }

  // Get all inflation items for current user
  Stream<List<InflationItemModel>> getInflationItems() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('inflationItems')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InflationItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Delete inflation item
  Future<void> deleteInflationItem(String itemId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inflationItems')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting inflation item: $e');
    }
  }

  // ==================== USER PROFILE ====================

  // Initialize user profile (called after registration)
  Future<void> initializeUserProfile({
    required String email,
    String? displayName,
    String? photoUrl,
    String? username,
    String? mobileNumber,
    String? authMethod,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final userData = <String, dynamic>{
        'userId': userId,
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'username': username ?? email, // Default username to email if not provided
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'onboardingCompleted': false,
        'settings': {
          'currency': 'PHP',
          'language': 'en',
          'notifications': true,
        },
      };

      if (photoUrl != null) userData['photoUrl'] = photoUrl;
      if (mobileNumber != null) userData['mobileNumber'] = mobileNumber;
      if (authMethod != null) userData['authMethod'] = authMethod;

      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );
      
      // Also create/update lookup entry for forgot password functionality
      // This allows searching by username, mobile, or email without exposing other user data
      if (email.isNotEmpty) {
        await _firestore.collection('userLookups').doc(userId).set({
          'email': email,
          'username': username ?? email,
          'mobileNumber': mobileNumber,
          'userId': userId, // For reference only, not used in queries
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Error initializing user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    bool? onboardingCompleted,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? additionalData,
    String? username,
    String? mobileNumber,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final userData = <String, dynamic>{
        'lastLogin': DateTime.now().toIso8601String(),
      };
      
      if (displayName != null) userData['displayName'] = displayName;
      if (photoUrl != null) userData['photoUrl'] = photoUrl;
      if (onboardingCompleted != null) userData['onboardingCompleted'] = onboardingCompleted;
      if (settings != null) userData['settings'] = settings;
      if (username != null) userData['username'] = username;
      if (mobileNumber != null) userData['mobileNumber'] = mobileNumber;
      if (additionalData != null) userData.addAll(additionalData);

      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );
      
      // Update lookup entry if username or mobileNumber changed
      if (username != null || mobileNumber != null) {
        final profile = await getUserProfile();
        if (profile != null && profile['email'] != null) {
          await _firestore.collection('userLookups').doc(userId).set({
            'email': profile['email'],
            'username': username ?? profile['username'] ?? profile['email'],
            'mobileNumber': mobileNumber ?? profile['mobileNumber'],
            'userId': userId,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final profile = await getUserProfile();
      return profile?['onboardingCompleted'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await updateUserProfile(onboardingCompleted: true);
  }

  // Find user email by username, mobile number, or email
  // This is used for forgot password functionality
  // Uses userLookups collection which is publicly readable for forgot password only
  Future<String?> findUserEmail({
    String? username,
    String? mobileNumber,
    String? email,
  }) async {
    try {
      // If email is provided and looks like an email, verify it exists
      if (email != null && email.contains('@')) {
        // Search in userLookups collection (publicly readable for forgot password)
        final emailQuery = await _firestore
            .collection('userLookups')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        
        if (emailQuery.docs.isNotEmpty) {
          return email;
        }
        return null;
      }

      // Search by username
      if (username != null && username.isNotEmpty) {
        final usernameQuery = await _firestore
            .collection('userLookups')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        
        if (usernameQuery.docs.isNotEmpty) {
          return usernameQuery.docs.first.data()['email'] as String?;
        }
      }

      // Search by mobile number
      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        // Normalize mobile number (remove spaces, dashes, etc.)
        final normalizedMobile = mobileNumber.replaceAll(RegExp(r'[\s-]'), '');
        
        // Try original format first
        final mobileQuery = await _firestore
            .collection('userLookups')
            .where('mobileNumber', isEqualTo: mobileNumber)
            .limit(1)
            .get();
        
        if (mobileQuery.docs.isNotEmpty) {
          return mobileQuery.docs.first.data()['email'] as String?;
        }
        
        // Try normalized version if different
        if (normalizedMobile != mobileNumber) {
          final normalizedQuery = await _firestore
              .collection('userLookups')
              .where('mobileNumber', isEqualTo: normalizedMobile)
              .limit(1)
              .get();
          
          if (normalizedQuery.docs.isNotEmpty) {
            return normalizedQuery.docs.first.data()['email'] as String?;
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Error finding user email: $e');
    }
  }
}

