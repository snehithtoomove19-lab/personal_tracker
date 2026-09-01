import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_scope.dart';
import 'birthday_contacts_screen.dart';

const List<String> kCurrencies = ['â‚¹', '\$', 'â‚¬', 'Â£', 'Â¥'];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: app.darkMode,
              onChanged: (v) => app.setDarkMode(v),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Currency'),
              trailing: DropdownButton<String>(
                value: app.currency,
                items: kCurrencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) app.setCurrency(v);
                },
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Welcome-Back Summary'),
              subtitle: const Text(
                  'Shows a quick popup when you open the app if anything needs attention (overdue tasks, unlogged mood, over-budget categories)'),
              secondary: const Icon(Icons.notifications_active_outlined),
              value: app.showLaunchDigest,
              onChanged: (v) => app.setShowLaunchDigest(v),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text('AI Assistant',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            if (app.aiApiKey.trim().isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Add your OpenAI API key in Settings first. It is free to create one at platform.openai.com.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _launchOpenAIKeyPage,
                      child: const Text('Get a free OpenAI API key'),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('OpenAI API Key'),
              subtitle: Text(
                app.aiApiKey.trim().isEmpty
                    ? 'Not set â€” required to use "Ask AI". Get a free key at platform.openai.com.'
                    : 'â€¢â€¢â€¢â€¢ ${app.aiApiKey.length > 4 ? app.aiApiKey.substring(app.aiApiKey.length - 4) : ''}',
              ),
              onTap: () => _editAiKey(context, app),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('Model'),
              subtitle: Text(app.aiModel),
              onTap: () => _editAiModel(context, app),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Get a key at platform.openai.com â€” your key is stored only on this device and sent directly to OpenAI, never through any server of ours.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export Data (CSV)'),
              subtitle: const Text(
                  'Saves transactions to a CSV file in app documents'),
              onTap: () async {
                final file = await app.exportTransactionsCsv();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exported to ${file.path}')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup Data'),
              subtitle: const Text(
                  'Full backup of everything (transactions, tasks, notes, goals, mood, budgets)'),
              onTap: () => _showBackup(context, app),
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restore from Backup'),
              subtitle:
                  const Text('Paste a backup you copied earlier to restore it'),
              onTap: () => _showRestore(context, app),
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Birthday Contacts'),
              subtitle: const Text(
                  'Family and friends whose birthdays you want to remember'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BirthdayContactsScreen())),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('App Lock (PIN)'),
              secondary: const Icon(Icons.lock_outline),
              value: app.pinEnabled,
              onChanged: (v) {
                if (v) {
                  _setPin(context, app);
                } else {
                  app.setPin(null);
                }
              },
            ),
            if (app.pinEnabled)
              ListTile(
                leading: const SizedBox(width: 24),
                title: const Text('Change PIN'),
                onTap: () => _setPin(context, app),
              ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Erase All Data',
                  style: TextStyle(color: Colors.red)),
              onTap: () => _confirmErase(context, app),
            ),
          ],
        ),
      ),
    );
  }

  void _editAiKey(BuildContext context, app) {
    final ctrl = TextEditingController(text: app.aiApiKey);
    bool obscure = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('OpenAI API Key'),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'sk-...',
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setDialogState(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                app.setAiApiKey(ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editAiModel(BuildContext context, app) {
    final ctrl = TextEditingController(text: app.aiModel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Model'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'e.g. gpt-4o-mini, gpt-4o'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) app.setAiModel(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchOpenAIKeyPage() async {
    final uri = Uri.parse('https://platform.openai.com/signup');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  }

  void _setPin(BuildContext context, app) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set a 4-6 digit PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.length >= 4) {
                app.setPin(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBackup(BuildContext context, app) async {
    final file = await app.exportBackupFile();
    final jsonText = app.exportBackupJson() as String;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Ready'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved to:\n${file.path}',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text(
                  'You can also copy the backup text below and paste it into "Restore from Backup" later or on another device.'),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                    child: Text(jsonText,
                        style: const TextStyle(
                            fontSize: 10, fontFamily: 'monospace'))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonText));
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')));
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showRestore(BuildContext context, app) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Paste your backup JSON below. This will replace all current data.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 8,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                    hintText: 'Paste backup JSON here...',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await app.restoreFromBackup(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Backup restored successfully')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Could not restore â€” invalid backup data')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmErase(BuildContext context, app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
            'This will permanently delete all transactions, tasks, notes, goals, and mood logs.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              app.clearAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Erase', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
