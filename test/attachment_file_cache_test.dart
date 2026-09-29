import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tree_permission_system/services/attachment_file_cache.dart';
import 'package:tree_permission_system/services/cloud_file_service.dart';

void main() {
  late Directory temporary;
  setUp(() async { temporary = await Directory.systemTemp.createTemp('tpms_attachment_test_'); });
  tearDown(() async { await temporary.delete(recursive: true); });
  test('Two devices download identical bytes into their own directories', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final a = AttachmentFileCache(directory: () async => Directory(p.join(temporary.path, 'deviceA')), download: (_, __) async => bytes);
    final b = AttachmentFileCache(directory: () async => Directory(p.join(temporary.path, 'deviceB')), download: (_, __) async => bytes);
    final first = await a.resolve(bucket: 'tpms-documents', key: 'photos/APP/one.jpg');
    final second = await b.resolve(bucket: 'tpms-documents', key: 'photos/APP/one.jpg');
    expect(first, isNot(second)); expect(await File(first).readAsBytes(), bytes); expect(await File(second).readAsBytes(), bytes);
    expect(p.isWithin(temporary.path, second), isTrue);
  });
  test('Concurrent preview and printing share one completed download', () async {
    final downloaded = Completer<Uint8List>(); var calls = 0;
    final cache = AttachmentFileCache(directory: () async => temporary, download: (_, __) { calls++; return downloaded.future; });
    final a = cache.resolve(bucket: 'tpms-documents', key: 'uploads/APP/a.pdf');
    final b = cache.resolve(bucket: 'tpms-documents', key: 'uploads/APP/a.pdf');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1); downloaded.complete(Uint8List.fromList([1, 2]));
    expect(await a, await b);
    expect(await cache.resolve(bucket: 'tpms-documents', key: 'uploads/APP/a.pdf'), await a);
    expect(calls, 1);
  });
  test('Failed or empty download is not cached; retry succeeds', () async {
    var calls = 0;
    final cache = AttachmentFileCache(directory: () async => temporary, download: (_, __) async {
      calls++; if (calls == 1) throw StateError('network unavailable');
      if (calls == 2) return Uint8List(0);
      return Uint8List.fromList([7]);
    });
    for (var attempt = 0; attempt < 2; attempt++) {
      await expectLater(cache.resolve(bucket: 'tpms-documents', key: 'photos/APP/a.jpg'), throwsStateError);
    }
    final path = await cache.resolve(bucket: 'tpms-documents', key: 'photos/APP/a.jpg');
    expect(await File(path).readAsBytes(), [7]);
    expect((await temporary.list(recursive: true).toList()).where((f) => f.path.endsWith('.part')), isEmpty);
  });
  test('Traversal cannot escape the device cache', () async {
    final cache = AttachmentFileCache(directory: () async => temporary, download: (_, __) async => Uint8List(1));
    await expectLater(cache.resolve(bucket: 'tpms-documents', key: '../secret'), throwsStateError);
    await expectLater(cache.resolve(bucket: '../bucket', key: 'photos/a.jpg'), throwsStateError);
  });
  test('Windows and mobile legacy paths resolve to the same cloud key', () {
    expect(CloudFileService.photoKey('APP', r'C:\Users\A\Photos\photo.jpg'), 'photos/APP/photo.jpg');
    expect(CloudFileService.photoKey('APP', '/data/user/photos/photo.jpg'), 'photos/APP/photo.jpg');
    final ref = Uri.parse(CloudFileService.reference('tpms-documents', 'uploads/APP/file name.pdf'));
    expect(ref.pathSegments.join('/'), 'uploads/APP/file name.pdf');
  });
}
