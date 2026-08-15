import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/note.dart';
import '../utils/formatters.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    var notes = app.notes
        .where((n) =>
            _query.isEmpty ||
            n.title.toLowerCase().contains(_query.toLowerCase()) ||
            n.content.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNoteScreen())),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Search notes...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notes.isEmpty
                  ? Center(child: Text('No notes yet', style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, i) => _NoteTile(note: notes[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final AppNote note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final removed = note;
        app.deleteNote(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${removed.title}"'),
            action: SnackBarAction(label: 'Undo', onPressed: () => app.addNote(removed)),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            note.content.isEmpty ? formatDate(note.updatedAt) : note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.pinned ? Theme.of(context).colorScheme.primary : null),
            onPressed: () {
              final updated = note..pinned = !note.pinned;
              app.updateNote(updated);
            },
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddNoteScreen(existing: note))),
        ),
      ),
    );
  }
}
