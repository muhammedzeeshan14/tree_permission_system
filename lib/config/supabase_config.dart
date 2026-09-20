// Stage 2: Supabase configuration for multi-device TPMS.
//
// Values come from --dart-define when provided, otherwise fall back to
// the project's baked-in defaults so store/CI builds (Codemagic default
// workflow, release APKs) sync without extra flags. The anon key is the
// public publishable key designed to ship inside client apps; rotate it
// in Supabase dashboard if it ever needs revoking.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://drgttmvxxhltlkeyoizy.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRyZ3R0bXZ4eGhsdGxrZXlvaXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5MjA4MDYsImV4cCI6MjEwNTQ5NjgwNn0._Df-PDA9UDSa9krQ7kLFG617NJWDhI05a1aAMgY8HAo',
  );

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty;
}
