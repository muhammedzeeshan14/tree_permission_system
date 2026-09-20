// Stage 1: Supabase configuration for multi-device TPMS.
// Values come from --dart-define so no secrets are checked in.
//
// Example:
//   flutter run \
//     --dart-define=SUPABASE_URL=https://xyz.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty;
}
