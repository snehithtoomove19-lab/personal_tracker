import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_scope.dart';
import '../services/supabase_sync_service.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  bool _controllersInitialized = false;
  bool _obscureKey = true;
  bool _obscurePassword = true;
  String? _message;
  bool _isError = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _keyController = TextEditingController();
    _listenForAuthChanges();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;
    final app = AppScope.of(context);
    _urlController.text = app.supabaseProjectUrl;
    _keyController.text = app.supabasePublishableKey;
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isError = error;
    });
  }

  Future<void> _saveAndConnect() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    final app = AppScope.of(context);
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    final validation = SupabaseSyncService.validateConfiguration(
      projectUrl: url,
      publishableKey: key,
    );
    if (validation != null) {
      _showMessage(validation, error: true);
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await app.setSupabaseConfiguration(
        projectUrl: url,
        publishableKey: key,
      );
      await SupabaseSyncService.initialize(
        projectUrl: url,
        publishableKey: key,
      );
      _listenForAuthChanges();
      app.setSupabaseInitError(null);
      _showMessage(
        'Supabase client initialized. Sign in to verify this project and access your account.',
      );
    } catch (error) {
      app.setSupabaseInitError(error.toString());
      _showMessage('Could not connect: $error', error: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _listenForAuthChanges() {
    if (_authSubscription != null || !SupabaseSyncService.isInitialized) {
      return;
    }
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _withBusy(
    Future<String> Function() action,
  ) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      _showMessage(await action());
    } on AuthException catch (error) {
      _showMessage(error.message, error: true);
    } catch (error) {
      _showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signIn() async {
    await _withBusy(() async {
      await SupabaseSyncService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      return 'Signed in. Your cloud backup is ready.';
    });
  }

  Future<void> _signUp() async {
    await _withBusy(() async {
      final sessionCreated = await SupabaseSyncService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      return sessionCreated
          ? 'Account created and signed in.'
          : 'Account created. Check your email to confirm, then sign in.';
    });
  }

  Future<void> _signOut() => _withBusy(() async {
        await SupabaseSyncService.signOut();
        return 'Signed out. Cloud data remains in your Supabase account.';
      });

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _upload() async {
    final proceed = await _confirm(
      title: 'Upload this device?',
      message: 'This replaces the current cloud backup for your account '
          'with all data currently on this device.',
      actionLabel: 'Upload backup',
    );
    if (!proceed) return;
    await _withBusy(() async {
      final updatedAt = await SupabaseSyncService.uploadBackup(
        AppScope.of(context),
      );
      return 'Cloud backup updated${updatedAt == null ? '' : ' at ${updatedAt.toLocal()}'}';
    });
  }

  Future<void> _download() async {
    final proceed = await _confirm(
      title: 'Replace this device’s data?',
      message: 'Downloading replaces this device’s tracker records with '
          'your cloud backup. Export a local backup first if you need to keep '
          'the data currently on this device.',
      actionLabel: 'Replace local data',
    );
    if (!proceed) return;
    await _withBusy(() async {
      final updatedAt = await SupabaseSyncService.downloadBackup(
        AppScope.of(context),
      );
      if (updatedAt == null) {
        return 'No cloud backup was found. Your local records were not changed.';
      }
      final timestamp = updatedAt.updatedAt;
      return timestamp == null
          ? 'Cloud backup restored.'
          : 'Cloud backup restored from ${timestamp.toLocal()}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = SupabaseSyncService.currentUser;
    final activeConfiguration = SupabaseSyncService.isConfiguredFor(
      projectUrl: _urlController.text,
      publishableKey: _keyController.text,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud sync')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Your tracker stays on this device unless you choose to upload '
            'or restore a backup. Each account can access only its own backup.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'Supabase project',
            icon: Icons.cloud_outlined,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Project URL',
                      hintText: 'https://your-project.supabase.co',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your Supabase project URL.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    autocorrect: false,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Anon / publishable key',
                      hintText: 'sb_publishable_… or legacy anon key',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(_obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the public anon or publishable key.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use Project Settings → API. Never enter a database '
                    'password or service-role/secret key here.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (SupabaseSyncService.isInitialized &&
                      !activeConfiguration) ...[
                    const SizedBox(height: 8),
                    Text(
                      'These differ from the active connection. Save them '
                      'and restart the app before using the new project.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.error),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _isBusy ? null : _saveAndConnect,
                    icon: const Icon(Icons.link_rounded),
                    label: Text(_isBusy ? 'Connecting…' : 'Save & connect'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: user == null ? 'Your account' : 'Signed in',
            icon: Icons.account_circle_outlined,
            child: user == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed:
                            _isBusy || !activeConfiguration ? null : _signIn,
                        child: const Text('Sign in'),
                      ),
                      OutlinedButton(
                        onPressed:
                            _isBusy || !activeConfiguration ? null : _signUp,
                        child: const Text('Create account'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(user.email ?? 'Signed-in Supabase user'),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed:
                            _isBusy || !activeConfiguration ? null : _upload,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Upload this device'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _isBusy || !activeConfiguration ? null : _download,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Restore cloud backup'),
                      ),
                      TextButton(
                        onPressed: _isBusy ? null : _signOut,
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Card(
              color:
                  _isError ? colors.errorContainer : colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isError
                        ? colors.onErrorContainer
                        : colors.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
          if (app.supabaseInitError != null && _message == null) ...[
            const SizedBox(height: 12),
            Card(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Cloud sync could not initialize: ${app.supabaseInitError}',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _card(
            context,
            title: 'Before you connect',
            icon: Icons.shield_outlined,
            child: const Text(
              'Run supabase/migrations/20261030000000_user_backups.sql in '
              'the Supabase SQL Editor first. Row Level Security restricts '
              'backups to their signed-in owner. Cloud restore replaces local '
              'records; it does not merge them. AI settings and API keys are '
              'never included in a backup.',
            ),
          ),
          if (app.supabaseProjectUrl.isNotEmpty &&
              app.supabasePublishableKey.isNotEmpty &&
              !SupabaseSyncService.isInitialized)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Project settings are saved on this device. Save & connect '
                'to initialize this session.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
