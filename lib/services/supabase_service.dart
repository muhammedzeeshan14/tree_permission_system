import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Stage 1: central Supabase client.
///
/// Local sqflite remains the offline cache. Supabase Postgres becomes
/// the shared source of truth once configured. All calls are safe
/// no-ops when [SupabaseConfig.isConfigured] is false so the current
/// single-device flow keeps working.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static bool get isReady =>
      _initialized && SupabaseConfig.isConfigured;

  static SupabaseClient? get client =>
      isReady ? Supabase.instance.client : null;

  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint(
        'Supabase not configured. Running in local-only mode. '
        'Pass --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY to enable sync.',
      );
      return;
    }
    if (_initialized) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
    debugPrint('Supabase initialized: ${SupabaseConfig.url}');
  }
}
