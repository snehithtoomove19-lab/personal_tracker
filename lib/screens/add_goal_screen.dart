import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/goal.dart';
import '../utils/formatters.dart';

class AddGoalScreen extends StatefulWidget {
  final AppGoal? existing;
  const AddGoalScreen({super.key, this.existing});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleCtrl = TextEditingController();
  DateTime? _targetDate;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _targetDate = widget.existing!.targetDate;
      _progress = widget.existing!.progress.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Add Goal'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.deleteGoal(widget.existing!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Goal title'),
              autofocus: !isEditing,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Target date'),
              subtitle: Text(_targetDate != null ? formatDate(_targetDate!) : 'No target date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            const SizedBox(height: 8),
            Text('Progress: ${_progress.round()}%'),
            Slider(
              value: _progress,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_progress.round()}%',
              onChanged: (v) => setState(() => _progress = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                if (isEditing) {
                  final updated = widget.existing!
                    ..title = _titleCtrl.text.trim()
                    ..targetDate = _targetDate
                    ..progress = _progress.round()
                    ..completed = _progress.round() >= 100;
                  app.updateGoal(updated);
                } else {
                  app.addGoal(AppGoal(
                    id: app.newId(),
                    title: _titleCtrl.text.trim(),
                    targetDate: _targetDate,
                    progress: _progress.round(),
                    completed: _progress.round() >= 100,
                    createdAt: DateTime.now(),
                  ));
                }
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isEditing ? 'Save Changes' : 'Add Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
