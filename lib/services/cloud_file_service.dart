import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storage_client/storage_client.dart';

import 'online_mode.dart';
import 'supabase_service.dart';

/// Cloud file sync via Supabase Storage (free tier).
///
/// DB rows already sync across devices; this moves the actual bytes:
/// - inspection photos      -> bucket tpms-photos
/// - generated PDFs         -> bucket tpms-documents
/// - uploaded documents     -> bucket tpms-documents
///
/// Uploads are fire-and-forget (never throw, never block the UI).
/// Reads use [ensureLocal]: if the file is missing locally it is
/// downloaded from cloud into the exact expected local path, so all
/// existing viewers (`Image.file`, `OpenFilex`) work unchanged.
class CloudFileService {
  CloudFileService._();

  static const photosBucket = 'tpms-photos';
  static const docsBucket = 'tpms-documents';

  static bool get enabled => OnlineMode.enabled;

  static String _fileName(String path) =>
      path.split(Platform.pathSeparator).last;

  static String photoKey(String officeNumber, String localPath) =>
      'photos/$officeNumber/${_fileName(localPath)}';

  static String generatedKey(String officeNumber, String localPath) =>
      'generated/$officeNumber/${_fileName(localPath)}';

  static String uploadKey(String officeNumber, String localPath) =>
      'uploads/$officeNumber/${_fileName(localPath)}';

  static Future<void> _upload(
    String bucket,
    String key,
    File file,
  ) async {
    if (!enabled) return;
    try {
      final client = SupabaseService.client;
      if (client == null) return;
      if (!await file.exists()) return;
      await client.storage.from(bucket).upload(
            key,
            file,
            fileOptions:
                const FileOptions(upsert: true),
          );
    } catch (e) {
      debugPrint('cloud upload $bucket/$key failed: $e');
    }
  }

  /// Download [key] into [localPath] when the local file is missing.
  /// Returns the local path. Throws when offline or download fails.
  static Future<String> ensureLocal({
    required String bucket,
    required String key,
    required String localPath,
  }) async {
    final local = File(localPath);
    if (await local.exists()) return localPath;
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase not configured.');
    }
    final bytes =
        await client.storage.from(bucket).download(key);
    await local.parent.create(recursive: true);
    await local.writeAsBytes(bytes);
    return localPath;
  }

  static Future<List<String>> listKeys(
    String bucket,
    String prefix,
  ) async {
    final client = SupabaseService.client;
    if (client == null || !enabled) return [];
    try {
      final entries = await client.storage
          .from(bucket)
          .list(path: prefix);
      return entries
          .where((e) => e.name.isNotEmpty)
          .map((e) => '$prefix/${e.name}')
          .toList();
    } catch (e) {
      debugPrint('cloud list $bucket/$prefix failed: $e');
      return [];
    }
  }

  static Future<void> deleteKey(
    String bucket,
    String key,
  ) async {
    if (!enabled) return;
    try {
      final client = SupabaseService.client;
      if (client == null) return;
      await client.storage.from(bucket).remove([key]);
    } catch (e) {
      debugPrint('cloud delete $bucket/$key failed: $e');
    }
  }

  static Future<void> deletePrefix(
    String bucket,
    String prefix,
  ) async {
    final keys = await listKeys(bucket, prefix);
    if (keys.isEmpty) return;
    try {
      final client = SupabaseService.client;
      await client?.storage.from(bucket).remove(keys);
    } catch (e) {
      debugPrint('cloud deletePrefix $bucket/$prefix failed: $e');
    }
  }

  // ---------- convenience wrappers (never throw) ----------

  static void uploadPhoto(
    String officeNumber,
    File file,
  ) {
    unawaited(_upload(
      photosBucket,
      photoKey(officeNumber, file.path),
      file,
    ));
  }

  static void uploadGenerated(
    String officeNumber,
    File file,
  ) {
    unawaited(_upload(
      docsBucket,
      generatedKey(officeNumber, file.path),
      file,
    ));
  }

  static void uploadDocument(
    String officeNumber,
    File file,
  ) {
    unawaited(_upload(
      docsBucket,
      uploadKey(officeNumber, file.path),
      file,
    ));
  }
}
