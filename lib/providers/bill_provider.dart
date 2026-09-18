import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_model.dart';
import 'firestore_provider.dart';

final billsProvider = StreamProvider<List<BillModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchBills();
});

final upcomingBillsProvider = Provider<List<BillModel>>((ref) {
  final bills = ref.watch(billsProvider).value ?? [];
  final now = DateTime.now();
  final cutoff = now.add(const Duration(days: 30));
  final upcoming = bills
      .where((b) => b.isActive && b.nextDueDate.isBefore(cutoff))
      .toList()
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  return upcoming;
});
