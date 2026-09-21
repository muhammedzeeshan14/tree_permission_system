import 'supabase_service.dart';

/// Stage 3: completely-online mode.
///
/// When Supabase is configured, the app reads/writes Supabase Postgres
/// directly — no local queue, no Sync button needed. The local sqflite
/// database stays only as a fallback when Supabase is not configured
/// (developer runs without flags).
class OnlineMode {
  OnlineMode._();

  /// Set true (e.g. from Settings) to force local-only even when
  /// Supabase is configured. Defaults to false = live cloud data.
  static bool forceOffline = false;

  static bool get enabled =>
      !forceOffline && SupabaseService.isReady;
}
