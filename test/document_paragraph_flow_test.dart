import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/services/document_paragraph_flow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paragraph uses remaining space and moves only overflowing lines', () {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 14))
      ..addText('First line\nSecond line\nThird line\nFourth line');
    final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 200));
    final metrics = paragraph.computeLineMetrics();
    final line = metrics[1].baseline - metrics[1].ascent;
    final pageHeight = line * 6;
    final margin = line;
    final start = pageHeight - margin - line * 2;
    final positions = <double>[];
    double position(double y, double height) {
      final page = (y / pageHeight).floor();
      final result = y + height <= (page + 1) * pageHeight - margin + 0.001
          ? y : (page + 1) * pageHeight + margin;
      if (height < paragraph.height) positions.add(result);
      return result;
    }
    final recorder = ui.PictureRecorder();
    final end = drawDocumentParagraph(
      canvas: ui.Canvas(recorder), paragraph: paragraph, x: 0, y: start,
      usableHeight: pageHeight - margin * 2, pagePosition: position);
    recorder.endRecording().dispose();
    expect(positions, hasLength(4));
    expect(positions.first, closeTo(start, 0.001));
    expect(positions[1], lessThan(pageHeight));
    expect(positions[2], greaterThanOrEqualTo(pageHeight + margin));
    expect(end, lessThan(pageHeight + margin + paragraph.height));
    paragraph.dispose();
  });

  test('branch table uses approved count fields and existing top description', () {
    expect(branchPermissionDescription(code: 'BRANCH', branches: 2, twigs: 9),
        '2 ಸಂಖ್ಯೆ ಕೊಂಬೆ');
    expect(branchPermissionDescription(code: 'TWIG', branches: 9, twigs: 3),
        '3 ಸಂಖ್ಯೆ ಸಣ್ಣ ತುದಿ');
    expect(branchPermissionDescription(code: 'TOP', branches: 9),
        '20 ಅಡಿ ಮೇಲಿನ ಭಾಗ ಮಾತ್ರ');
  });
}
