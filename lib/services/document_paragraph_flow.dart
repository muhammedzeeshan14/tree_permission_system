import 'dart:ui' as ui;

/// Keeps lines that fit on the current page instead of moving a whole paragraph.
double drawDocumentParagraph({
  required ui.Canvas canvas,
  required ui.Paragraph paragraph,
  required double x,
  required double y,
  required double usableHeight,
  required double Function(double, double) pagePosition,
}) {
  if (paragraph.height <= usableHeight &&
      pagePosition(y, paragraph.height) == y) {
    canvas.drawParagraph(paragraph, ui.Offset(x, y));
    return y + paragraph.height;
  }
  final metrics = paragraph.computeLineMetrics();
  var sourceTop = 0.0;
  for (var index = 0; index < metrics.length; index++) {
    final sourceBottom = index + 1 == metrics.length
        ? paragraph.height
        : metrics[index + 1].baseline - metrics[index + 1].ascent;
    final height = sourceBottom - sourceTop;
    y = pagePosition(y, height);
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(x, y, paragraph.width, height));
    canvas.drawParagraph(paragraph, ui.Offset(x, y - sourceTop));
    canvas.restore();
    y += height;
    sourceTop = sourceBottom;
  }
  return y;
}

/// Tree values already include the saved DRFO/RFO modifications.
String branchPermissionDescription({
  required String code, int? branches, int? twigs,
}) {
  switch (code) {
    case 'BRANCH': return '${branches ?? 0} ಸಂಖ್ಯೆ ಕೊಂಬೆ';
    case 'TWIG': return '${twigs ?? 0} ಸಂಖ್ಯೆ ಸಣ್ಣ ತುದಿ';
    case 'TOP': return '20 ಅಡಿ ಮೇಲಿನ ಭಾಗ ಮಾತ್ರ';
    default: throw ArgumentError.value(code, 'code');
  }
}
