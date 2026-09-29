import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tree_permission_system/services/inspection_attachment_pdf_service.dart';

void main() {
  late Directory temporary;
  final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAADklEQVR4nGP4DwYMEAoAU7oL9ZisIGcAAAAASUVORK5CYII=');
  setUp(() async { temporary = await Directory.systemTemp.createTemp('tpms_print_test_'); });
  tearDown(() async { await temporary.delete(recursive: true); });
  test('All uploaded PDF pages become printable pages', () async {
    final original = Uint8List.fromList(utf8.encode('%PDF-test-input'));
    final file = await File('${temporary.path}/upload.pdf').writeAsBytes(original);
    final pdf = pw.Document(compress: false);
    final pages = await InspectionAttachmentPdfService.appendDocumentPages(pdf: pdf, file: file,
      officeNumber: 'APP', title: 'Uploaded Document', rasterize: (bytes) async* {
        expect(bytes, original); yield png; yield png; yield png;
      });
    expect(pages, 3);
    final output = latin1.decode(await pdf.save());
    expect(output, contains('/Count 3'));
    expect(output, isNot(contains('cannot be embedded')));
  });
  test('A missing attachment stops printing instead of silently omitting it', () async {
    await expectLater(InspectionAttachmentPdfService.appendDocumentPages(pdf: pw.Document(),
      file: File('${temporary.path}/missing.pdf'), officeNumber: 'APP', title: 'Missing'), throwsStateError);
  });
  test('Image upload prints its content', () async {
    final file = await File('${temporary.path}/image.png').writeAsBytes(png);
    final pdf = pw.Document();
    expect(await InspectionAttachmentPdfService.appendDocumentPages(pdf: pdf, file: file, officeNumber: 'APP', title: 'Image'), 1);
    expect((await pdf.save()).length, greaterThan(100));
  });
}
