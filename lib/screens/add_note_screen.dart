import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/note.dart';

class AddNoteScreen extends StatefulWidget {
  final AppNote? existing;
  const AddNoteScreen({super.key, this.existing});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _contentCtrl.text = widget.existing!.content;
      _pinned = widget.existing!.pinned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'Add Note'),
        actions: [
          IconButton(
            icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _pinned = !_pinned),
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.deleteNote(widget.existing!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: !isEditing,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Note', alignLabelWithHint: true),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty &&
                      _contentCtrl.text.trim().isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  final now = DateTime.now();
                  if (isEditing) {
                    final updated = widget.existing!
                      ..title = _titleCtrl.text.trim().isEmpty
                          ? 'Untitled'
                          : _titleCtrl.text.trim()
                      ..content = _contentCtrl.text.trim()
                      ..pinned = _pinned
                      ..updatedAt = now;
                    app.updateNote(updated);
                  } else {
                    app.addNote(AppNote(
                      id: app.newId(),
                      title: _titleCtrl.text.trim().isEmpty
                          ? 'Untitled'
                          : _titleCtrl.text.trim(),
                      content: _contentCtrl.text.trim(),
                      pinned: _pinned,
                      createdAt: now,
                      updatedAt: now,
                    ));
                  }
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save Note'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
