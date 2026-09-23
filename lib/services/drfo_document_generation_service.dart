import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/application_model.dart';

class DrfoDocumentGenerationService {
  // ==========================================================
  // COMMON
  // ==========================================================

  Future<pw.Font> _loadKannadaFont() async {
  final file = File(
    r'C:\Windows\Fonts\Nirmala.ttf',
  );

  if (!await file.exists()) {
    throw Exception(
      'Kannada font not found: C:\\Windows\\Fonts\\Nirmala.ttf',
    );
  }

  final bytes = await file.readAsBytes();

  return pw.Font.ttf(
    ByteData.sublistView(bytes),
  );
}

  Future<Directory> _getGeneratedFolder() async {
    final base =
        await getApplicationDocumentsDirectory();

    final folder = Directory(
      '${base.path}/TPMS/Generated Documents',
    );

    if (!await folder.exists()) {
      await folder.create(
        recursive: true,
      );
    }

    return folder;
  }

  String _safeOfficeNumber(
    String officeNumber,
  ) {
    return officeNumber.replaceAll(
      '/',
      '_',
    );
  }

  String _inspectionDate(
    ApplicationModel application,
  ) {
    if (application.drfoInspectionDate.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(
        application.drfoInspectionDate,
      );

      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return application.drfoInspectionDate.replaceAll('/', '-');
    }
  }

  // ==========================================================
  // DRFO DEFERRED LETTER
  // ==========================================================

  Future<File> generateDeferredLetter(
    ApplicationModel application,
  ) async {
    final font = await _loadKannadaFont();

    final pdf = pw.Document();

    final regular = pw.TextStyle(
      font: font,
      fontSize: 12,
      lineSpacing: 4,
    );

    final bold = pw.TextStyle(
      font: font,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      lineSpacing: 4,
    );

    final subjectStyle = pw.TextStyle(
      font: font,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      lineSpacing: 4,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          60,
          55,
          55,
          55,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [

              // ------------------------------------------
              // TO
              // ------------------------------------------

              pw.Text(
                'ರವರಿಗೆ,',
                style: regular,
              ),

              pw.SizedBox(height: 3),

              pw.Text(
                'ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿಗಳು,',
                style: regular,
              ),

              pw.Text(
                'ಮೈಸೂರು ವಲಯ, ಮೈಸೂರು.',
                style: regular,
              ),

              pw.SizedBox(height: 18),

              pw.Text(
                'ಮಾನ್ಯರೆ,',
                style: regular,
              ),

              pw.SizedBox(height: 12),

              // ------------------------------------------
              // SUBJECT
              // ------------------------------------------

              pw.RichText(
                text: pw.TextSpan(
                  style: subjectStyle,
                  children: [
                    const pw.TextSpan(
                      text: 'ವಿಷಯ: ',
                    ),
                    pw.TextSpan(
                      text:
                          '${application.applicantName}, '
                          '${application.applicantAddress} '
                          'ಇವರ ${_landText(application)} ಇರುವ '
                          'ಮರ/ಮರದ ರೆಂಬೆ ಕೊಂಬೆಗಳನ್ನು '
                          'ತೆರವುಗೊಳಿಸಲು ಕೋರಿ ಸಲ್ಲಿಸಿದ ಅರ್ಜಿಗೆ '
                          'ವರದಿಯನ್ನು ಸಲ್ಲಿಸುವ ಬಗ್ಗೆ.',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ------------------------------------------
              // REFERENCES
              // ------------------------------------------

              pw.Text(
                'ಉಲ್ಲೇಖ:',
                style: regular,
              ),

              pw.SizedBox(height: 4),

              pw.Text(
                '1. ${application.applicantName}, '
                '${application.applicantAddress} ಇವರ ಅರ್ಜಿ ದಿನಾಂಕ: '
                '${application.applicationDate} '
                '(ಸ್ವೀಕೃತಿ ದಿನಾಂಕ ${application.receivedDate})',
                style: regular,
              ),

              if (application.applicationSource
                  .trim()
                  .isNotEmpty)
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(
                    top: 4,
                  ),
                  child: pw.Text(
                    '2. ${application.applicationSource}',
                    style: regular,
                  ),
                ),

              if (application.forwardedDate
                  .trim()
                  .isNotEmpty)
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(
                    top: 4,
                  ),
                  child: pw.Text(
                    '3. ತಮ್ಮ ಆದೇಶ ದಿನಾಂಕ: '
                    '${application.forwardedDate}',
                    style: regular,
                  ),
                ),

              pw.SizedBox(height: 10),

              pw.Divider(),

              pw.SizedBox(height: 10),

              // ------------------------------------------
              // MAIN BODY
              // ------------------------------------------

              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(
                      text:
                          'ಈ ಮೇಲ್ಕಂಡ ವಿಷಯಕ್ಕೆ ಸಂಬಂಧಿಸಿದಂತೆ '
                          '${application.applicantName}, '
                          '${application.applicantAddress} ರವರು '
                          '${_landText(application)} ಇರುವ '
                          'ಮರ/ಮರದ ರೆಂಬೆ ಕೊಂಬೆಗಳನ್ನು ತೆರವುಗೊಳಿಸಲು '
                          'ಅನುಮತಿಯನ್ನು ಉಲ್ಲೇಖಿತ ಪತ್ರದಲ್ಲಿ ಕೋರಿದ '
                          'ಮೇರೆಗೆ ಸ್ಥಳ ಪರಿಶೀಲಿಸಿ ವರದಿಯನ್ನು ಸಲ್ಲಿಸಲು '
                          'ತಾವು ಆದೇಶವನ್ನು ಮಾಡಿರುತ್ತೀರಿ.',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    const pw.TextSpan(
                      text:
                          'ಅದರಂತೆ ನಾನು ಮತ್ತು ಸಿಬ್ಬಂದಿಗಳು '
                          'ಅರ್ಜಿದಾರರ ಸ್ಥಳಕ್ಕೆ ಹೋಗಿ ಪರಿಶೀಲಿಸಿ ನೋಡಲಾಗಿ ',
                    ),

                    pw.TextSpan(
                      text:
                          _deferredReason(
                        application,
                      ),
                    ),

                    const pw.TextSpan(
                      text:
                          '. ಆದ್ದರಿಂದ ಸ್ಥಳ ಮತ್ತು ಮರಗಳನ್ನು '
                          'ಪರಿಶೀಲಿಸಲು ಆಗಿರುವುದಿಲ್ಲ. ಆದ ಕಾರಣ ಸದರಿ '
                          'ಅರ್ಜಿಯನ್ನು ವಿಲೇಮಾಡಲು ಶಿಫಾರಸ್ಸು ಮಾಡುತ್ತಾ '
                          'ಹಾಗು ಮರ/ಮರಗಳನ್ನು ಯಥಾಸ್ಥಿತಿ ಕಾಪಾಡುವುದು '
                          'ಸೂಕ್ತ ಎಂಬ ಅಭಿಪ್ರಾಯದೊಂದಿಗೆ ಈ ವರದಿಯನ್ನು '
                          'ತಮ್ಮ ಅವಗಾಹನೆಗೆ ಗೌರವಪೂರಕವಾಗಿ ಸಲ್ಲಿಸಿದೆ.',
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ------------------------------------------
              // SIGNATURE
              // ------------------------------------------

              pw.Text(
                'ವಂದನೆಗಳೊಂದಿಗೆ,',
                style: regular,
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'ದಿನಾಂಕ: ${_inspectionDate(application)}',
                style: regular,
              ),

              pw.Text(
                'ಸ್ಥಳ: ಮೈಸೂರು',
                style: regular,
              ),

              pw.SizedBox(height: 18),

              pw.Align(
                alignment:
                    pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ತಮ್ಮ ನಂಬುಗೆಯ,',
                      style: regular,
                    ),

                    pw.SizedBox(height: 28),

                    pw.Text(
                      'ಉಪವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರ',
                      style: bold,
                      textAlign:
                          pw.TextAlign.center,
                    ),

                    pw.Text(
                      '${application.section} ಶಾಖೆ, ಮೈಸೂರು ವಲಯ',
                      style: regular,
                      textAlign:
                          pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final folder =
        await _getGeneratedFolder();

    final safeOfficeNumber =
        _safeOfficeNumber(
      application.officeNumber,
    );

    final file = File(
      '${folder.path}/'
      '${safeOfficeNumber}_DRFO_DEFERRED.pdf',
    );

    await file.writeAsBytes(
      await pdf.save(),
    );

    return file;
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _landText(
    ApplicationModel application,
  ) {
    if (application.treeLocationAddress
        .trim()
        .isNotEmpty) {
      return '${application.applicantAddress} ಮತ್ತು '
          '${application.treeLocationAddress}';
    }

    return application.applicantAddress;
  }

  String _deferredReason(
    ApplicationModel application,
  ) {
    if (application.drfoOverallRemarks
        .trim()
        .isNotEmpty) {
      return application.drfoOverallRemarks
          .trim();
    }

    if (application.overallRemarks
        .trim()
        .isNotEmpty) {
      return application.overallRemarks
          .trim();
    }

    return 'ಸ್ಥಳ ಪರಿಶೀಲನೆ ನಡೆಸಲು ಸಾಧ್ಯವಾಗದ ಕಾರಣ';
  }
}