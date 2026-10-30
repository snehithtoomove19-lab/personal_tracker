import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';

class SupabaseSyncService {
  SupabaseSyncService._();

  static String? _initializedUrl;
  static String? _initializedPublishableKey;
  static const _backupTable = 'user_backups';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static bool get isInitialized => _initializedUrl != null;

  static bool isConfiguredFor({
    required String projectUrl,
    required String publishableKey,
  }) =>
      isInitialized &&
      _initializedUrl == projectUrl.trim() &&
      _initializedPublishableKey == publishableKey.trim();

  static User? get currentUser =>
      isInitialized ? Supabase.instance.client.auth.currentUser : null;

  static String? validateConfiguration({
    required String projectUrl,
    required String publishableKey,
  }) {
    final uri = Uri.tryParse(projectUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return 'Enter your Supabase HTTPS project URL, such as '
          'https://your-project.supabase.co.';
    }
    if (publishableKey.trim().isEmpty) {
      return 'Enter the Supabase anon or publishable key.';
    }
    final normalizedKey = publishableKey.trim().toLowerCase();
    if (normalizedKey.contains('service_role') ||
        normalizedKey.startsWith('sb_secret_') ||
        _isLegacyServiceRoleKey(publishableKey.trim())) {
      return 'Never use a service-role key in the app. Use the public anon or publishable key.';
    }
    return null;
  }

  static bool _isLegacyServiceRoleKey(String key) {
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map && payload['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }

  static Future<void> initialize({
    required String projectUrl,
    required String publishableKey,
  }) async {
    final error = validateConfiguration(
      projectUrl: projectUrl,
      publishableKey: publishableKey,
    );
    if (error != null) throw FormatException(error);
    final url = projectUrl.trim();
    final key = publishableKey.trim();
    if (_initializedUrl != null &&
        (_initializedUrl != url || _initializedPublishableKey != key)) {
      throw StateError(
        'Supabase is already connected with different project settings. Restart the app to use the saved settings.',
      );
    }
    if (_initializedUrl != null) {
      return;
    }

    final host = Uri.parse(url).host;
    await Supabase.initialize(
      url: url,
      publishableKey: key,
      authOptions: FlutterAuthClientOptions(
        localStorage: _SecureSupabaseSessionStorage(host, _secureStorage),
      ),
    );
    _initializedUrl = url;
    _initializedPublishableKey = key;
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _requireInitialized();
    await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _requireInitialized();
    final response = await Supabase.instance.client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.session != null;
  }

  static Future<void> signOut() async {
    _requireInitialized();
    await Supabase.instance.client.auth.signOut();
  }

  static Future<DateTime?> uploadBackup(AppState app) async {
    final user = _requireUser();
    final updatedAt = DateTime.now().toUtc();
    await Supabase.instance.client.from(_backupTable).upsert(
      {
        'user_id': user.id,
        'data': jsonDecode(app.exportBackupJson()),
        'updated_at': updatedAt.toIso8601String(),
      },
      onConflict: 'user_id',
    );
    return updatedAt;
  }

  static Future<CloudBackupMetadata?> downloadBackup(AppState app) async {
    final user = _requireUser();
    final record = await Supabase.instance.client
        .from(_backupTable)
        .select('data, updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
    if (record == null) return null;

    final data = record['data'];
    if (data is! Map) {
      throw const FormatException(
        'The cloud backup has an invalid format. Your local data was not changed.',
      );
    }
    final backup = Map<String, dynamic>.from(data);
    await app.restoreFromBackup(jsonEncode(backup));
    final updatedAt = record['updated_at'];
    return CloudBackupMetadata(
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
    );
  }

  static void _requireInitialized() {
    if (!isInitialized) {
      throw StateError(
        'Save the Supabase project URL and public key before signing in.',
      );
    }
  }

  static User _requireUser() {
    _requireInitialized();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to your Supabase account first.');
    }
    return user;
  }
}

class CloudBackupMetadata {
  const CloudBackupMetadata({required this.updatedAt});

  final DateTime? updatedAt;
}

class _SecureSupabaseSessionStorage extends LocalStorage {
  const _SecureSupabaseSessionStorage(this.host, this.storage);

  final String host;
  final FlutterSecureStorage storage;

  String get _key => 'personal_tracker_supabase_session_$host';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await storage.read(key: _key) != null;

  @override
  Future<String?> accessToken() => storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: _key, value: persistSessionString);
}
