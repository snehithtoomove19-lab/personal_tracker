import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/birthday_contact.dart';
import '../services/app_scope.dart';

const _uuid = Uuid();

class BirthdayContactsScreen extends StatelessWidget {
  const BirthdayContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final contacts = app.birthdayContacts.toList()
      ..sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));

    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Birthday Contacts')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _editContact(context, app),
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        itemCount: contacts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Add friends and family birthdays here. The app will remind you when a birthday is coming up.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            );
          }
          final contact = contacts[index - 1];
          final next = contact.nextOccurrence(now);
          final days = contact.daysUntil(now);
          final age = contact.ageOn(next);
          final birthdayLabel = days == 0
              ? 'Turns $age today'
              : days == 1
                  ? 'Turns $age tomorrow'
                  : 'In $days days, turns $age';
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(contact.initials)),
              title: Text('${contact.name} • ${contact.relation}'),
              subtitle: Text('${DateFormat.yMMMMd().format(contact.date)} • $birthdayLabel'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editContact(context, app, contact: contact)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteContact(context, app, contact)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _editContact(BuildContext context, app, {BirthdayContact? contact}) {
    final nameCtrl = TextEditingController(text: contact?.name ?? '');
    final relationCtrl = TextEditingController(text: contact?.relation ?? 'Friend');
    DateTime date = contact?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(contact == null ? 'Add Birthday Contact' : 'Edit Birthday Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relation (e.g. Sister, Friend)')),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(DateTime.now().year + 5),
                );
                if (picked != null) {
                  date = picked;
                }
              },
              child: Text('Birthday: ${DateFormat.yMMMd().format(date)}'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final edited = BirthdayContact(
                id: contact?.id ?? _uuid.v4(),
                name: nameCtrl.text.trim(),
                relation: relationCtrl.text.trim().isEmpty ? 'Friend' : relationCtrl.text.trim(),
                date: DateTime(date.year, date.month, date.day),
              );
              if (contact == null) {
                app.addBirthdayContact(edited);
              } else {
                app.updateBirthdayContact(edited);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteContact(BuildContext context, app, BirthdayContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove ${contact.name} from birthday reminders?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              app.deleteBirthdayContact(contact.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
