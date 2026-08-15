import 'package:flutter/material.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/add_note_screen.dart';
import '../screens/add_goal_screen.dart';
import '../models/transaction.dart';

void showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      Widget option(IconData icon, String label, Color color, VoidCallback onTap) {
        return ListTile(
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
          title: Text(label),
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Quick Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              option(Icons.remove_circle_outline, 'Add Expense', Colors.redAccent, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(type: TxType.expense)));
              }),
              option(Icons.add_circle_outline, 'Add Income', Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(type: TxType.income)));
              }),
              option(Icons.check_circle_outline, 'Add Task', Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
              }),
              option(Icons.note_add_outlined, 'Add Note', Colors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNoteScreen()));
              }),
              option(Icons.flag_outlined, 'Add Goal', Colors.purple, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen()));
              }),
            ],
          ),
        ),
      );
    },
  );
}
