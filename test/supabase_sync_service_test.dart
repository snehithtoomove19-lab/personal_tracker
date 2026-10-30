import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/services/supabase_sync_service.dart';

void main() {
  test('accepts a Supabase HTTPS URL and public key', () {
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: 'sb_publishable_public-key',
      ),
      isNull,
    );
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: 'eyJhbGciOiJIUzI1NiJ9.legacy-anon-key',
      ),
      isNull,
    );
  });

  test('rejects insecure URLs, service keys, and missing project credentials',
      () {
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: 'http://example-project.supabase.co',
        publishableKey: 'public-key',
      ),
      isNotNull,
    );
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: 'service_role_secret',
      ),
      contains('Never use a service-role key'),
    );
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: 'sb_secret_do-not-use',
      ),
      contains('Never use a service-role key'),
    );
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: 'e30.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature',
      ),
      contains('Never use a service-role key'),
    );
    expect(
      SupabaseSyncService.validateConfiguration(
        projectUrl: '',
        publishableKey: 'public-key',
      ),
      isNotNull,
    );
  });
}
