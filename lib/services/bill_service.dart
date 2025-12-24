import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_model.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Save a new bill or update existing
  Future<void> saveBill(BillModel bill) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final billData = bill.id == null
          ? bill.copyWith(
              createdAt: now,
              updatedAt: now,
            ).toMap()
          : bill.copyWith(updatedAt: now).toMap();

      if (bill.id == null) {
        // Create new bill
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .add(billData);
      } else {
        // Update existing bill
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc(bill.id)
            .update(billData);
      }
    } catch (e) {
      throw Exception('Error saving bill: $e');
    }
  }

  /// Get all bills for current user as a stream
  Stream<List<BillModel>> getBills() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    // Create stream with comprehensive error handling
    // Use StreamController to catch all errors and emit empty list instead
    final controller = StreamController<List<BillModel>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
    
    // Set up the Firestore stream with error handling
    try {
      subscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .orderBy('dueDate', descending: false)
          .snapshots()
          .listen(
        (snapshot) {
          if (!controller.isClosed) {
            final bills = snapshot.docs
                .map((doc) => BillModel.fromMap(doc.id, doc.data()))
                .toList();
            controller.add(bills);
          }
        },
        onError: (error, stackTrace) {
          // Emit empty list on error instead of propagating
          if (!controller.isClosed) {
            controller.add(<BillModel>[]);
          }
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      // If setup fails, emit empty list immediately
      if (!controller.isClosed) {
        controller.add(<BillModel>[]);
      }
    }
    
    // Handle stream cancellation
    controller.onCancel = () {
      subscription?.cancel();
      if (!controller.isClosed) {
        controller.close();
      }
    };
    
    return controller.stream;
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting bill: $e');
    }
  }

  /// Mark bill as paid (updates due date if recurring)
  Future<void> markBillAsPaid(BillModel bill) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // If recurring, update due date to next occurrence
      if (bill.isRecurring && bill.recurringDays != null) {
        final nextDueDate = bill.dueDate.add(Duration(days: bill.recurringDays!));
        await saveBill(bill.copyWith(dueDate: nextDueDate));
      } else {
        // If not recurring, delete the bill
        if (bill.id != null) {
          await deleteBill(bill.id!);
        }
      }
    } catch (e) {
      throw Exception('Error marking bill as paid: $e');
    }
  }
}

