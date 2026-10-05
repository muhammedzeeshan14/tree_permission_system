/// Grammatical joins for master text; never substitutes an English label.
class DocumentMasterGrammar {
  static String structurePhrase(String value) {
    final text = value.trim();
    const forms = {
      'ಕಟ್ಟಡ': 'ಕಟ್ಟಡದ',
      'ರಸ್ತೆ': 'ರಸ್ತೆಯ',
      'ಚರಂಡಿ': 'ಚರಂಡಿಯ',
      'ಸೇತುವೆ': 'ಸೇತುವೆಯ',
      'ಕಾಂಪೌಂಡ್ ಗೋಡೆ': 'ಕಾಂಪೌಂಡ್ ಗೋಡೆಯ',
      'ಬಡಾವಣೆ': 'ಬಡಾವಣೆಯ',
      'ಮನೆ': 'ಮನೆಯ',
    };
    if (text.isEmpty) return '';
    // Unknown/custom text stays intact; a neutral connector avoids guessing a suffix.
    return forms[text] ?? '$text ಸಂಬಂಧಿತ';
  }

  static String purposePhrase(String value) {
    final text = value.trim();
    const forms = {
      'ಸುರಕ್ಷತೆ': 'ಸುರಕ್ಷತೆಗೆ',
      'ಮನೆ ನಿರ್ಮಾಣ': 'ನಿರ್ಮಾಣ ಕಾಮಗಾರಿಗೆ',
      'ರಸ್ತೆ ಅಗಲೀಕರಣ': 'ಅಗಲೀಕರಣ ಕಾಮಗಾರಿಗೆ',
      'ಕೃಷಿ': 'ಕೃಷಿ ಉದ್ದೇಶಕ್ಕಾಗಿ',
    };
    return forms[text] ?? text;
  }

  static String workPhrase(String value) =>
      value.trim().isEmpty ? '' : '(ಕಾಮಗಾರಿ: ${value.trim()})';

  static String removalPhrase(String value) {
    const forms = {
      'ಅಪಾಯಕಾರಿ ಮರ/ಕೊಂಬೆ': 'ಅಪಾಯ ಉಂಟಾಗುತ್ತಿರುವ',
      'ಅಭಿವೃದ್ಧಿ ಕಾಮಗಾರಿ': 'ಅಡಚಣೆ ಉಂಟಾಗುತ್ತಿರುವ',
    };
    final text = forms[value.trim()] ?? value.trim();
    if (text.isEmpty || text.endsWith('ಕಾರಣ') || text.endsWith('ಗಾಗಿ') || text.endsWith('ಕ್ಕಾಗಿ'))
      return text;
    return '$text ಕಾರಣ';
  }
}
