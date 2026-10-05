import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/services/document_master_grammar.dart';
import 'package:tree_permission_system/database/document_grammar_defaults.dart';

void main() {
  test('default combinations form coherent Kannada reason clauses', () {
    String sentence(String structure, String purpose, String reason) =>
        '${DocumentMasterGrammar.structurePhrase(structure)} '
        '${DocumentMasterGrammar.purposePhrase(purpose)} '
        '${DocumentMasterGrammar.removalPhrase(reason)} ತೆರವುಗೊಳಿಸಲು';
    expect(
      sentence('ರಸ್ತೆ', 'ಅಗಲೀಕರಣ ಕಾಮಗಾರಿಗೆ', 'ಅಡಚಣೆ ಉಂಟಾಗುತ್ತಿರುವ'),
      'ರಸ್ತೆಯ ಅಗಲೀಕರಣ ಕಾಮಗಾರಿಗೆ ಅಡಚಣೆ ಉಂಟಾಗುತ್ತಿರುವ ಕಾರಣ ತೆರವುಗೊಳಿಸಲು',
    );
    expect(
      sentence('ಕಟ್ಟಡ', 'ಸುರಕ್ಷತೆಗೆ', 'ಅಪಾಯ ಉಂಟಾಗುತ್ತಿರುವ'),
      'ಕಟ್ಟಡದ ಸುರಕ್ಷತೆಗೆ ಅಪಾಯ ಉಂಟಾಗುತ್ತಿರುವ ಕಾರಣ ತೆರವುಗೊಳಿಸಲು',
    );
    expect(DocumentMasterGrammar.structurePhrase('ಚರಂಡಿ'), 'ಚರಂಡಿಯ');
    expect(DocumentMasterGrammar.structurePhrase('ಸೇತುವೆ'), 'ಸೇತುವೆಯ');
    expect(
      DocumentMasterGrammar.structurePhrase('ಕಾಂಪೌಂಡ್ ಗೋಡೆ'),
      'ಕಾಂಪೌಂಡ್ ಗೋಡೆಯ',
    );
  });
  test('custom text and existing endings are retained without guessing', () {
    expect(
      DocumentMasterGrammar.structurePhrase('Custom office'),
      'Custom office ಸಂಬಂಧಿತ',
    );
    expect(
      DocumentMasterGrammar.removalPhrase('ಸ್ವಂತ ಅನುಕೂಲಕ್ಕಾಗಿ'),
      'ಸ್ವಂತ ಅನುಕೂಲಕ್ಕಾಗಿ',
    );
    expect(
      DocumentMasterGrammar.removalPhrase('ಹಾನಿ ಉಂಟಾಗುತ್ತಿರುವ ಕಾರಣ'),
      'ಹಾನಿ ಉಂಟಾಗುತ್ತಿರುವ ಕಾರಣ',
    );
    expect(DocumentMasterGrammar.workPhrase(''), '');
    expect(DocumentMasterGrammar.workPhrase('ABC'), '(ಕಾಮಗಾರಿ: ABC)');
    expect(DocumentMasterGrammar.purposePhrase('ಸುರಕ್ಷತೆ'), 'ಸುರಕ್ಷತೆಗೆ');
  });
  test(
    'five defaults per group and every purpose maps to a removal reason',
    () {
      for (final type in ['Structure Type', 'Why Removing', 'Purpose']) {
        expect(
          documentGrammarDefaults.where((r) => r['masterType'] == type).length,
          5,
        );
      }
      final codes = documentGrammarDefaults
          .where((r) => r['masterType'] == 'Why Removing')
          .map((r) => r['code'])
          .toSet();
      for (final row in documentGrammarDefaults.where(
        (r) => r['masterType'] == 'Purpose',
      )) {
        expect(codes.contains(row['parentCode']), true);
      }
    },
  );
  test(
    'active templates do not append a universal suffix or duplicate cause',
    () {
      for (final dir in ['assets/templates/drfo', 'assets/templates/rfo']) {
        for (final file in Directory(dir).listSync().whereType<File>()) {
          final text = file.readAsStringSync();
          expect(
            text.contains('{{STRUCTURE_TYPE_KANNADA}}ಯ'),
            false,
            reason: file.path,
          );
          expect(
            text.contains('{{WHY_REMOVING_KANNADA}} ಕಾರಣ'),
            false,
            reason: file.path,
          );
        }
      }
    },
  );
}
