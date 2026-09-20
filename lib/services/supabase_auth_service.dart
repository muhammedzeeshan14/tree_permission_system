import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Stage 2: link local `users` rows to Supabase Auth.
///
/// Local usernames (admin, rfo, ...) are not emails, so we map each
/// username to a synthetic email `<username>@tpms.local`. On first
/// online login we sign up (or sign in) that email with the same
/// local password, then store `auth_id` + `email` on the local row.
/// Local login always remains the fallback when offline.
class SupabaseAuthService {
  SupabaseAuthService._();

  static String syntheticEmail(String username) =>
      '${username.trim().toLowerCase()}@tpms.local';

  /// Link [localUser] to Supabase Auth. Returns auth user id or null
  /// when offline / unconfigured / failed (caller keeps local login).
  static Future<String?> linkLocalUser(
    Map<String, dynamic> localUser,
    String password,
  ) async {
    final client = SupabaseService.client;
    if (client == null) return null;
    final username = (localUser['username'] ?? '').toString();
    if (username.isEmpty || password.isEmpty) return null;
    final email = syntheticEmail(username);
    try {
      // Try sign-in first.
      AuthResponse res;
      try {
        res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } on AuthException catch (e) {
        // Unknown user -> create it, then sign in.
        if (!e.message.toLowerCase().contains('invalid')) rethrow;
        res = await client.auth.signUp(email: email, password: password);
        if (res.user == null) {
          res = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
        }
      }
      final authId = res.user?.id;
      if (authId == null) return null;
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'users',
        {'authId': authId, 'email': email},
        where: 'id=?',
        whereArgs: [localUser['id']],
      );
      return authId;
    } catch (e) {
      debugPrint('Supabase auth link failed for $username: $e');
      return null;
    }
  }

  static Future<void> signOutRemote() async {
    try {
      await SupabaseService.client?.auth.signOut();
    } catch (e) {
      debugPrint('Supabase sign-out failed: $e');
    }
  }
}
