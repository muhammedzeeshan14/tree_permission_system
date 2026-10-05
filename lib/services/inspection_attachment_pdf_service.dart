import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../repositories/document_repository.dart';
import '../repositories/inspection_photo_repository.dart';
import '../repositories/photo_repository.dart';
import 'cloud_file_service.dart';

/// Items 5-6: printable PDFs for inspection photos and uploaded
/// documents, generated for the DRFO alongside letters and lists.
///
/// Photos: 1 PDF, chunks of 4 photos per A4 page (1 photo fills the
/// whole page, 2-3 stack with gaps, 4 use a 2x2 grid).
/// Uploaded documents: 1 PDF, each scanned image on its own full A4
/// page; PDF uploads contribute all of their actual pages.
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
    int applicationId,
  ) async {
    final base = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${base.path}/TPMS/AttachmentPdfs/$applicationId',
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
      final path = await CloudFileService.resolvePhotoPath(
        applicationId: applicationId,
        storedPath: row['sourcePath']?.toString() ?? row['photoPath']?.toString() ?? '',
        officeNumber: officeNumber, requiredForUse: true,
      );
      if (!_isImage(path)) throw StateError('Unsupported photo format. Upload a JPG or PNG image.');
      entries.add({'path': path, 'caption': row['caption']?.toString() ?? ''});
    }
    if (entries.isEmpty) {
      throw StateError('No inspection photos found.');
    }

    final bytes = await photoPdfBytes(entries: entries, officeNumber: officeNumber);
    final folder = await _outputFolder(applicationId);
    final file = File('${folder.path}/$_photoFileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<Uint8List> photoPdfBytes({
    required List<Map<String, String>> entries,
    required String officeNumber,
  }) async {
    if (entries.isEmpty) throw StateError('No inspection photos found.');
    final chunks = <List<Map<String, String>>>[];
    for (var i = 0; i < entries.length; i += 4) {
      chunks.add(
        entries.sublist(
          i,
          i + 4 > entries.length ? entries.length : i + 4,
        ),
      );
    }

    final pdf = await _newDocument();
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
              if (images.length == 4)
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            images[0],
                            pw.SizedBox(width: 12),
                            images[1],
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            images[2],
                            pw.SizedBox(width: 12),
                            images[3],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < images.length; i++) ...[
                  if (i > 0) pw.SizedBox(height: 12),
                  images[i],
                ],
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Builds (or rebuilds) the uploaded-documents PDF.
  /// Throws StateError when no usable documents exist.
  static Future<File> buildDocumentsPdf({
    required int applicationId,
    required String officeNumber,
  }) async {
    final docs =
        await DocumentRepository().getDocuments(applicationId);
    if (docs.isEmpty) throw StateError('No uploaded documents found.');
    final pdf = await _newDocument();
    for (final doc in docs) {
      final local = await CloudFileService.resolveDocumentPath(applicationId: applicationId,
        storedPath: doc.storedPath, officeNumber: officeNumber, requiredForUse: true);
      await appendDocumentPages(pdf: pdf, file: File(local), officeNumber: officeNumber,
        title: doc.documentTypeName.isEmpty ? 'Uploaded Document' : doc.documentTypeName);
    }

    final folder = await _outputFolder(applicationId);
    final file = File('${folder.path}/$_docsFileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<pw.Document> _newDocument() async {
    Future<pw.Font> font(String path) async {
      final asset = await rootBundle.load(path);
      // The PDF font parser indexes the underlying buffer from zero. Asset
      // bundles can return a ByteData view with a non-zero starting offset.
      final bytes = Uint8List.fromList(asset.buffer.asUint8List(
          asset.offsetInBytes, asset.lengthInBytes));
      return pw.Font.ttf(ByteData.sublistView(bytes));
    }
    final regular = await font('assets/fonts/NotoSansKannada-Regular.ttf');
    final bold = await font('assets/fonts/NotoSansKannada-Bold.ttf');
    return pw.Document(theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(), bold: pw.Font.helveticaBold(),
      fontFallback: [regular, bold]));
  }

  /// A PDF upload is rendered page-by-page; never substitute a filename-only page.
  /// [rasterize] is injectable so rendering can be tested without a printer driver.
  static Future<int> appendDocumentPages({required pw.Document pdf, required File file,
    required String officeNumber, required String title,
    Stream<Uint8List> Function(Uint8List)? rasterize}) async {
    if (!await file.exists() || await file.length() == 0) throw StateError('Document file is missing or empty. Refresh attachments and retry.');
    final bytes = await file.readAsBytes();
    void addImage(Uint8List imageBytes, int page) {
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Text('$title — $officeNumber — Page $page', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Expanded(child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain))),
        ]),
      ));
    }
    if (_isImage(file.path)) { addImage(bytes, 1); return 1; }
    if (file.path.toLowerCase().endsWith('.pdf')) {
      final render = rasterize ?? (Uint8List data) => Printing.raster(data, dpi: 144).asyncMap((page) => page.toPng());
      var pages = 0;
      await for (final png in render(bytes)) { addImage(png, ++pages); }
      if (pages == 0) throw StateError('The uploaded PDF has no printable pages.');
      return pages;
    }
    throw StateError('This document format cannot be combined into a PDF. Use View to open and print the original file, or upload a PDF/JPG/PNG version.');
  }

  // Counts are records, not files already cached on this particular device.
  static Future<int> photoCount(int applicationId, {String officeNumber = ''}) => PhotoRepository().totalPhotos(applicationId);
  static Future<int> documentCount(int applicationId, {String officeNumber = ''}) => DocumentRepository().totalDocuments(applicationId);
}
