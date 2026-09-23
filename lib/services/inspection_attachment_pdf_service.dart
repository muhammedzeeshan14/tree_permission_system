import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../repositories/document_repository.dart';
import '../repositories/inspection_photo_repository.dart';
import '../models/document_model.dart';
import 'cloud_file_service.dart';

/// Items 5-6: printable PDFs for inspection photos and uploaded
/// documents, generated for the DRFO alongside letters and lists.
///
/// Photos: 1 PDF, chunks of 4 photos per A4 page (1 photo fills the
/// whole page, 2-4 share one page, 5 photos = 4+1 pages, etc.).
/// Uploaded documents: 1 PDF, each scanned image on its own full A4
/// page; non-image files get an info page pointing at the original.
class InspectionAttachmentPdfService {
  InspectionAttachmentPdfService._();

  static const _photoFileName = 'INSPECTION_PHOTOS.pdf';
  static const _docsFileName = 'UPLOADED_DOCUMENTS.pdf';

  static bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  static Future<Directory> _outputFolder(
    String officeNumber,
  ) async {
    final base = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${base.path}/TPMS/Documents/$officeNumber',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  static pw.Widget _pageHeader(
    String title,
    String officeNumber,
    int page,
    int pages,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '$officeNumber • Page $page of $pages',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Builds (or rebuilds) the inspection-photos PDF.
  /// Throws StateError when no usable photos exist.
  static Future<File> buildPhotoPdf({
    required int applicationId,
    required String officeNumber,
  }) async {
    final rows =
        await InspectionPhotoRepository().getPhotos(applicationId);
    final entries = <Map<String, String>>[];
    for (final row in rows) {
      final path = row['photoPath']?.toString() ?? '';
      if (path.isEmpty) continue;
      try {
        // Cloud: fetch photos taken on other devices.
        await CloudFileService.ensureLocal(
          bucket: CloudFileService.photosBucket,
          key: CloudFileService.photoKey(officeNumber, path),
          localPath: path,
        );
      } catch (_) {
        continue;
      }
      if (!await File(path).exists()) continue;
      if (!_isImage(path)) continue;
      entries.add({
        'path': path,
        'caption': row['caption']?.toString() ?? '',
      });
    }
    if (entries.isEmpty) {
      throw StateError('No inspection photos found.');
    }

    final chunks = <List<Map<String, String>>>[];
    for (var i = 0; i < entries.length; i += 4) {
      chunks.add(
        entries.sublist(
          i,
          i + 4 > entries.length ? entries.length : i + 4,
        ),
      );
    }

    final pdf = pw.Document();
    for (var page = 0; page < chunks.length; page++) {
      final chunk = chunks[page];
      final images = <pw.Widget>[];
      for (final entry in chunk) {
        final bytes = await File(entry['path']!).readAsBytes();
        final image = pw.MemoryImage(bytes);
        final caption = entry['caption']!.trim();
        images.add(
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ),
                if (caption.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      caption,
                      style:
                          const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.stretch,
            children: [
              _pageHeader(
                'Inspection Photos',
                officeNumber,
                page + 1,
                chunks.length,
              ),
              ...images,
            ],
          ),
        ),
      );
    }

    final folder = await _outputFolder(officeNumber);
    final file = File('${folder.path}/$_photoFileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Builds (or rebuilds) the uploaded-documents PDF.
  /// Throws StateError when no usable documents exist.
  static Future<File> buildDocumentsPdf({
    required int applicationId,
    required String officeNumber,
  }) async {
    final docs =
        await DocumentRepository().getDocuments(applicationId);
    final usable = <DocumentModel>[];
    for (final doc in docs) {
      if (doc.filePath.isEmpty) continue;
      try {
        // Cloud: fetch documents uploaded on other devices.
        await CloudFileService.ensureLocal(
          bucket: CloudFileService.docsBucket,
          key: CloudFileService.uploadKey(
              officeNumber, doc.filePath),
          localPath: doc.filePath,
        );
      } catch (_) {
        continue;
      }
      if (File(doc.filePath).existsSync()) usable.add(doc);
    }
    final existing = usable;
    if (existing.isEmpty) {
      throw StateError('No uploaded documents found.');
    }

    final pdf = pw.Document();
    for (var i = 0; i < existing.length; i++) {
      final doc = existing[i];
      final name = doc.filePath.split(RegExp(r'[/\\]')).last;
      if (_isImage(doc.filePath)) {
        final bytes = await File(doc.filePath).readAsBytes();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (_) => pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.stretch,
              children: [
                _pageHeader(
                  doc.documentTypeName.isEmpty
                      ? 'Uploaded Document'
                      : doc.documentTypeName,
                  officeNumber,
                  i + 1,
                  existing.length,
                ),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(bytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                _pageHeader(
                  'Uploaded Document',
                  officeNumber,
                  i + 1,
                  existing.length,
                ),
                pw.Text(
                  doc.documentTypeName.isEmpty
                      ? name
                      : doc.documentTypeName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'File: $name\n\n'
                  'This file cannot be embedded in print. '
                  'Open the original file from the application '
                  'documents folder to view or print it.',
                  style:
                      const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }
    }

    final folder = await _outputFolder(officeNumber);
    final file = File('${folder.path}/$_docsFileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<int> photoCount(
    int applicationId, {
    String officeNumber = '',
  }) async {
    final rows =
        await InspectionPhotoRepository().getPhotos(applicationId);
    var count = 0;
    for (final row in rows) {
      final path = row['photoPath']?.toString() ?? '';
      if (path.isEmpty) continue;
      if (officeNumber.isNotEmpty) {
        try {
          await CloudFileService.ensureLocal(
            bucket: CloudFileService.photosBucket,
            key: CloudFileService.photoKey(officeNumber, path),
            localPath: path,
          );
        } catch (_) {
          // Offline; count local only.
        }
      }
      if (path.isNotEmpty && await File(path).exists()) count++;
    }
    return count;
  }

  static Future<int> documentCount(
    int applicationId, {
    String officeNumber = '',
  }) async {
    final docs =
        await DocumentRepository().getDocuments(applicationId);
    var count = 0;
    for (final doc in docs) {
      if (officeNumber.isNotEmpty && doc.filePath.isNotEmpty) {
        try {
          await CloudFileService.ensureLocal(
            bucket: CloudFileService.docsBucket,
            key: CloudFileService.uploadKey(
                officeNumber, doc.filePath),
            localPath: doc.filePath,
          );
        } catch (_) {
          // Offline; count local only.
        }
      }
      if (await File(doc.filePath).exists()) count++;
    }
    return count;
  }
}
