import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Downloads attachments into THIS device's cache, never another device's path.
class AttachmentFileCache {
  final Future<Directory> Function() directory;
  final Future<Uint8List> Function(String bucket, String key) download;
  final Map<String, Future<String>> _downloads = {};
  AttachmentFileCache({required this.directory, required this.download});

  static Future<bool> usable(String path) async {
    if (path.isEmpty || path.startsWith('cloud://')) return false;
    try { return await File(path).exists() && await File(path).length() > 0; }
    on FileSystemException { return false; }
  }

  Future<String> resolve({required String bucket, required String key}) async {
    final parts = key.split('/');
    if (bucket.contains(RegExp(r'[/\\]')) || parts.any((s) => s.isEmpty || s == '.' || s == '..' || s.contains('\\'))) {
      throw StateError('Invalid attachment reference.');
    }
    final root = await directory();
    final target = p.joinAll([root.path, 'TPMS', 'CloudAttachments', bucket, ...parts]);
    if (await usable(target)) return target;
    final running = _downloads[target];
    if (running != null) return running;
    final future = _download(bucket, key, target);
    _downloads[target] = future;
    try { return await future; }
    finally { if (identical(_downloads[target], future)) _downloads.remove(target); }
  }

  Future<String> _download(String bucket, String key, String target) async {
    final bytes = await download(bucket, key);
    if (bytes.isEmpty) throw StateError('The cloud attachment is empty. Upload it again from the original device.');
    final file = File(target);
    await file.parent.create(recursive: true);
    final partial = File('$target.${const Uuid().v4()}.part');
    try {
      await partial.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete(); // only a verified cache target
      await partial.rename(target);
    } finally { if (await partial.exists()) await partial.delete(); }
    return target;
  }
}
