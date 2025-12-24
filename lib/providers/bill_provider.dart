import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bill_service.dart';
import '../models/bill_model.dart';

/// Bill Service Provider
final billServiceProvider = Provider<BillService>((ref) {
  return BillService();
});

/// Bills Stream Provider
/// Streams all bills for the current user
/// Used by Dashboard and Budget Planner screens
final billsProvider = StreamProvider<List<BillModel>>((ref) {
  final billService = ref.watch(billServiceProvider);
  return billService.getBills();
});

/// Upcoming Bills Provider (for compatibility with existing code)
/// Returns bills sorted by due date
final upcomingBillsFromInputProvider = Provider<List<BillModel>>((ref) {
  final billsAsync = ref.watch(billsProvider);
  
  if (billsAsync.value == null) return [];

  final bills = billsAsync.value!;
  final now = DateTime.now();

  // Filter bills that are due in the future or within last 7 days (overdue)
  return bills.where((bill) {
    return bill.dueDate.isAfter(now.subtract(const Duration(days: 7)));
  }).toList();
});


