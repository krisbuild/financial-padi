import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/bill_model.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/empty_state.dart';
import '../widgets/bill_tile.dart';
import 'add_edit_bill_screen.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  Future<void> _markAsPaid(WidgetRef ref, BillModel bill) async {
    final service = ref.read(firestoreServiceProvider);

    await service.addTransaction(
      TransactionModel(
        id: const Uuid().v4(),
        categoryId: bill.categoryId,
        amount: bill.amount,
        type: CategoryType.expense,
        note: '${bill.name} (bill payment)',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    final updatedBill = bill.copyWith(nextDueDate: bill.computeNextDueDate());
    await service.updateBill(updatedBill);
    await NotificationService.instance.scheduleBillReminder(updatedBill);
  }

  Future<void> _delete(WidgetRef ref, BillModel bill) async {
    await NotificationService.instance.cancelBillReminder(bill);
    await ref.read(firestoreServiceProvider).deleteBill(bill.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider).value ?? [];
    final sorted = [...bills]..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Bills')),
      body: sorted.isEmpty
          ? const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No recurring bills',
              message: 'Add bills and subscriptions to get reminders before they are due.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final bill = sorted[index];
                return BillTile(
                  bill: bill,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddEditBillScreen(existing: bill)),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'paid') _markAsPaid(ref, bill);
                      if (value == 'delete') _delete(ref, bill);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'paid', child: Text('Mark as paid')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditBillScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
