import 'package:crypto/crypto.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_client/storage_client.dart';

import '../database/database_helper.dart';
import 'online_database.dart';

import 'online_mode.dart';
import 'supabase_service.dart';
import 'attachment_file_cache.dart';
import 'package:open_filex/open_filex.dart';

/// A cloud file reference with best-effort size.
class CloudFileEntry {
  final String key;
  final int sizeBytes; // -1 when unknown

  const CloudFileEntry(this.key, this.sizeBytes);

  String get name => key.split('/').last;
}

/// Inspection attachment saves await cloud upload before publishing database rows.
/// Portable references resolve to a cache belonging to the current device.
class CloudFileService {
  CloudFileService._();

  static const photosBucket = 'tpms-documents';
  static const legacyPhotosBucket = 'tpms-photos';
  static const docsBucket = 'tpms-documents';

  static bool get enabled => OnlineMode.enabled;

  // Split on BOTH separators: paths synced from another OS use
  // that OS's separator (mobile '/' vs Windows '\').
  static String _fileName(String path) =>
      path.split(RegExp(r'[/\\]')).last;

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
  static final _cache = AttachmentFileCache(
    directory: getApplicationDocumentsDirectory,
    download: (bucket, key) async {
      final client = SupabaseService.client;
      if (client == null || !enabled) throw StateError('Connect to the cloud to download this attachment.');
      return client.storage.from(bucket).download(key).timeout(const Duration(seconds: 60));
    },
  );
  static final Set<String> _confirmedUploads = {};
  static final Map<String, Future<void>> _pendingUploads = {};

  static String reference(String bucket, String key) => Uri(scheme: 'cloud', host: bucket, path: '/$key').toString();

  static Future<void> _uploadAttachment(String bucket, String key, File file, {bool overwrite = false}) async {
    if (!enabled || SupabaseService.client == null) throw StateError('Cloud storage is unavailable. The attachment has not been saved.');
    if (!await AttachmentFileCache.usable(file.path)) throw StateError('The attachment file is missing or empty. Select it again.');
    final identity = '$bucket/$key';
    if (_confirmedUploads.contains(identity)) return;
    final pending = _pendingUploads[identity];
    if (pending != null) return pending;
    final operation = () async {
      try {
        await SupabaseService.client!.storage.from(bucket).upload(key, file,
          fileOptions: FileOptions(upsert: overwrite)).timeout(const Duration(seconds: 90));
      } on StorageException catch (error) {
        if (error.statusCode == '409') {
          // A conflict is success only when the existing object is readable.
          await SupabaseService.client!.storage.from(bucket).download(key)
              .timeout(const Duration(seconds: 60));
        } else {
          throw StateError('Attachment upload failed (${error.message}). Check connection/storage access and retry. It was not saved to the cloud.');
        }
      }
      _confirmedUploads.add(identity);
    }();
    _pendingUploads[identity] = operation;
    try { await operation; }
    finally { _pendingUploads.remove(identity); }
  }

  static Future<String> savePhotoFile(int applicationId, String path) => _saveAttachment(applicationId, path, true);
  static Future<String> saveDocumentFile(int applicationId, String path) => _saveAttachment(applicationId, path, false);

  static Future<String> _saveAttachment(int applicationId, String path, bool photo) async {
    if (!enabled) return path;
    if (path.startsWith('cloud://')) return path;
    if (applicationId <= 0) throw StateError('Save the application before attaching files.');
    final bucket = photo ? photosBucket : docsBucket;
    final key = await attachmentKey(applicationId, path, photo: photo);
    await _uploadAttachment(bucket, key, File(path));
    return reference(bucket, key);
  }

  static Future<String> attachmentKey(int applicationId, String path, {required bool photo}) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    final name = _fileName(path).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    // Application IDs cannot collide when office numbers were duplicated.
    // Content-addressed keys also make retries safe without overwriting files.
    return '${photo ? 'photos' : 'uploads'}/applications/$applicationId/$digest-$name';
  }

  static Future<String> _resolveAttachment({required int applicationId, required String storedPath, String? officeNumber, required bool photo}) async {
    if (storedPath.isEmpty) throw StateError('This attachment has no file reference. Upload it again.');
    // Views may pass the resolved cache path; never re-upload it under a
    // guessed office-number key (especially for duplicate old numbers).
    if (await AttachmentFileCache.usable(storedPath)) return storedPath;
    String bucket = photo ? photosBucket : docsBucket;
    String key;
    if (storedPath.startsWith('cloud://')) {
      final uri = Uri.parse(storedPath);
      bucket = uri.host;
      if (![docsBucket, legacyPhotosBucket].contains(bucket)) throw StateError('Unknown attachment storage bucket.');
      key = uri.pathSegments.join('/');
    } else {
      final office = officeNumber ?? await officeNumberFor(applicationId);
      if (office.isEmpty) throw StateError('Application details are unavailable. Refresh and retry.');
      key = photo ? photoKey(office, storedPath) : uploadKey(office, storedPath);
      String? original;
      if (await AttachmentFileCache.usable(storedPath)) {
        original = storedPath;
      } else if (!office.split(RegExp(r'[/\\]')).any((part) => part == '..' || part == '.')) {
        // Legacy downloads and restored mobile app folders may have a new root.
        final root = await getApplicationDocumentsDirectory();
        final candidate = '${root.path}/TPMS/${photo ? 'Photos' : 'Documents'}/$office/${_fileName(storedPath)}';
        if (await AttachmentFileCache.usable(candidate)) original = candidate;
      }
      if (original != null) {
        return original;
      }
    }
    try { return await _cache.resolve(bucket: bucket, key: key); }
    catch (error) {
      // Recover a legacy cloud reference whose upload never reached storage,
      // but whose source file still exists on the capture/upload device.
      if (storedPath.startsWith('cloud://')) {
        final office = officeNumber ?? await officeNumberFor(applicationId);
        if (office.isNotEmpty && !office.split(RegExp(r'[/\\]')).any((p) => p == '.' || p == '..')) {
          final root = await getApplicationDocumentsDirectory();
          final candidate = File('${root.path}/TPMS/${photo ? 'Photos' : 'Documents'}/$office/${_fileName(key)}');
          if (await AttachmentFileCache.usable(candidate.path)) {
            _confirmedUploads.remove('$bucket/$key');
            await _uploadAttachment(bucket, key, candidate);
            return candidate.path;
          }
        }
      }
      if (photo && bucket != legacyPhotosBucket) {
        try { return await _cache.resolve(bucket: legacyPhotosBucket, key: key); }
        catch (_) { /* Report the original failure below. */ }
      }
      throw StateError('Could not download ${photo ? 'photo' : 'document'} ${_fileName(storedPath)}. '
        'Check your connection and retry. If it was never uploaded, open this application on the original device to sync it. ($error)');
    }
  }

  static Future<String> resolvePhotoPath({required int applicationId, required String storedPath, String? officeNumber, bool requiredForUse = false}) async {
    try { return await _resolveAttachment(applicationId: applicationId, storedPath: storedPath, officeNumber: officeNumber, photo: true); }
    catch (error) { if (requiredForUse) rethrow; debugPrint('Photo unavailable: $error'); return storedPath; }
  }
  static Future<String> resolveDocumentPath({required int applicationId, required String storedPath, String? officeNumber, bool requiredForUse = false}) async {
    try { return await _resolveAttachment(applicationId: applicationId, storedPath: storedPath, officeNumber: officeNumber, photo: false); }
    catch (error) { if (requiredForUse) rethrow; debugPrint('Document unavailable: $error'); return storedPath; }
  }
  static Future<bool> ensurePhotoFile(int applicationId, String path) async {
    final local = await resolvePhotoPath(applicationId: applicationId, storedPath: path);
    return AttachmentFileCache.usable(local);
  }
  static Future<bool> ensureDocumentFile(int applicationId, String path) async {
    final local = await resolveDocumentPath(applicationId: applicationId, storedPath: path);
    return AttachmentFileCache.usable(local);
  }
  static Future<void> openDocument(int applicationId, String path) async {
    final local = await resolveDocumentPath(applicationId: applicationId, storedPath: path, requiredForUse: true);
    final result = await OpenFilex.open(local);
    if (result.type != ResultType.done) throw StateError('Could not open document: ${result.message}');
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

  static Future<void> uploadPhoto(String officeNumber, File file) async {
    if (!enabled) return;
    await _uploadAttachment(photosBucket, photoKey(officeNumber, file.path), file);
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

  static Future<void> uploadDocument(String officeNumber, File file) async {
    if (!enabled) return;
    await _uploadAttachment(docsBucket, uploadKey(officeNumber, file.path), file);
  }
}
