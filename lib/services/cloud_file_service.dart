import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storage_client/storage_client.dart';

import '../database/database_helper.dart';
import 'online_database.dart';

import 'online_mode.dart';
import 'supabase_service.dart';

/// A cloud file reference with best-effort size.
class CloudFileEntry {
  final String key;
  final int sizeBytes; // -1 when unknown

  const CloudFileEntry(this.key, this.sizeBytes);

  String get name => key.split('/').last;
}

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
    final entries = await listFiles(bucket, prefix);
    return entries.map((e) => e.key).toList();
  }

  static Future<String> officeNumberFor(int applicationId) async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          'applications',
          equals: {'id': applicationId},
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final office =
              rows.first['officeNumber']?.toString() ?? '';
          if (office.isNotEmpty) return office;
        }
      } catch (_) {
        // Fall through to local.
      }
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'applications',
        columns: ['officeNumber'],
        where: 'id=?',
        whereArgs: [applicationId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows.first['officeNumber']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('office lookup failed: $e');
    }
    return '';
  }

  /// Best-effort download of an inspection photo. Returns true when
  /// the local file exists afterwards.
  static Future<bool> ensurePhotoFile(
    int applicationId,
    String localPath,
  ) async {
    if (localPath.isEmpty) return false;
    if (await File(localPath).exists()) return true;
    if (!enabled) return false;
    try {
      final office = await officeNumberFor(applicationId);
      if (office.isEmpty) return false;
      await ensureLocal(
        bucket: photosBucket,
        key: photoKey(office, localPath),
        localPath: localPath,
      );
      return true;
    } catch (e) {
      debugPrint('ensure photo failed: $e');
      return false;
    }
  }

  /// Best-effort download of an uploaded document.
  static Future<bool> ensureDocumentFile(
    int applicationId,
    String localPath,
  ) async {
    if (localPath.isEmpty) return false;
    if (await File(localPath).exists()) return true;
    if (!enabled) return false;
    try {
      final office = await officeNumberFor(applicationId);
      if (office.isEmpty) return false;
      await ensureLocal(
        bucket: docsBucket,
        key: uploadKey(office, localPath),
        localPath: localPath,
      );
      return true;
    } catch (e) {
      debugPrint('ensure document failed: $e');
      return false;
    }
  }

  /// Lists files with best-effort sizes (bytes, -1 when unknown).
  static Future<List<CloudFileEntry>> listFiles(
    String bucket,
    String prefix,
  ) async {
    final client = SupabaseService.client;
    if (client == null || !enabled) return [];
    try {
      final entries = await client.storage
          .from(bucket)
          .list(path: prefix);
      return entries.where((e) => e.name.isNotEmpty).map((e) {
        var size = -1;
        try {
          final meta = e.metadata as Map?;
          final raw = meta?['size'];
          if (raw is num) size = raw.toInt();
          if (raw is String) size = int.tryParse(raw) ?? -1;
        } catch (_) {
          size = -1;
        }
        return CloudFileEntry('$prefix/${e.name}', size);
      }).toList();
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
