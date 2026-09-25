import 'dart:convert';

class RevenueReply {
  static const satisfied = 'Satisfied';
  static const notSatisfied = 'Not satisfied';
  static const wrongAuthority = 'Wrong authority';
  static const natures = [satisfied, notSatisfied, wrongAuthority];
  static const onlineApplied = 'Applied';
  static const onlineNotApplied = 'Not applied';
  static const onlineStatuses = [onlineApplied, onlineNotApplied];
  static const requiredFields = [
    'authority',
    'letterNumber',
    'letterDate',
    'receivedDate',
    'nature',
  ];
  static const questions = <String, String>{
    'authority': '1. Revenue opinion giving authority',
    'letterNumber': '2. Letter no.',
    'letterDate': '3. Opinion letter date',
    'receivedDate': '4. Opinion letter received date',
    'nature': '5. Revenue opinion nature',
    'ownership': '6. Land ownership details? (optional)',
    'reserved': '7. Trees reserved for government? (optional)',
    'taxes': '8. Taxes being paid? (optional)',
    'dispute': '9. Any dispute from anyone? (optional)',
    'extra': 'Extra details (optional)',
    'unsatisfiedDetails': '10. Enter details (optional)',
    'wrongAuthorityDetails': '11. Enter details (optional)',
    'onlineApplicationStatus': '12. Online application status',
    'onlineApplicationNumber': '13. Enter online application No. (optional)',
  };
  final int id, applicationId, cycle, revision;
  final String requestedAt,
      requestAuthority,
      requestLetterPath,
      printedAt,
      stage,
      finalLetterPath;
  final Map<String, String> answers, decisions;
  final int? nextAuthorityId;

  RevenueReply.fromMap(Map<String, dynamic> map)
    : id = map['id'] as int,
      applicationId = map['applicationId'] as int,
      cycle = map['cycle'] as int,
      requestedAt = map['requestedAt'] as String? ?? '',
      requestAuthority = map['requestAuthority'] as String? ?? '',
      requestLetterPath = map['requestLetterPath'] as String? ?? '',
      printedAt = map['printedAt'] as String? ?? '',
      stage = map['stage'] as String,
      revision = map['revision'] as int? ?? 0,
      answers = Map<String, String>.from(
        jsonDecode(map['answers'] as String? ?? '{}') as Map,
      ),
      decisions = Map<String, String>.from(
        jsonDecode(map['decisions'] as String? ?? '{}') as Map,
      ),
      nextAuthorityId = map['nextAuthorityId'] as int?,
      finalLetterPath = map['finalLetterPath'] as String? ?? '';

  static List<String> fields(
    Map<String, String> answers, {
    bool includeOnline = true,
  }) {
    final list = [
      'authority',
      'letterNumber',
      'letterDate',
      'receivedDate',
      'nature',
      if (answers['nature'] == satisfied) ...[
        'ownership',
        'reserved',
        'taxes',
        'dispute',
        'extra',
      ],
      if (answers['nature'] == notSatisfied) 'unsatisfiedDetails',
      if (answers['nature'] == wrongAuthority) 'wrongAuthorityDetails',
    ];
    // Sandal Private has no online-application concept.
    if (includeOnline) {
      list.add('onlineApplicationStatus');
      if (answers['onlineApplicationStatus'] == onlineApplied) {
        list.add('onlineApplicationNumber');
      }
    }
    return list;
  }

  static Map<String, String> activeAnswers(
    Map<String, String> answers, {
    bool includeOnline = true,
  }) => {
    for (final key in fields(answers, includeOnline: includeOnline))
      key: (answers[key] ?? '').trim(),
  };

  static String? validate(
    Map<String, String> answers, {
    bool includeOnline = true,
  }) {
    if (!natures.contains(answers['nature']))
      return 'Select the revenue opinion nature.';
    if (includeOnline &&
        !onlineStatuses.contains(
            answers['onlineApplicationStatus'])) {
      return 'Select online application status (Applied / Not applied).';
    }
    for (final key in requiredFields) {
      if ((answers[key] ?? '').trim().isEmpty) {
        return 'Enter ' + questions[key]! + '.';
      }
    }
    final letter = DateTime.tryParse(answers['letterDate'] ?? '');
    final received = DateTime.tryParse(answers['receivedDate'] ?? '');
    if (letter == null || received == null)
      return 'Select valid letter and received dates.';
    if (received.isBefore(letter))
      return 'Received date cannot be before the letter date.';
    return null;
  }

  bool get allApproved => allApprovedFor();

  bool allApprovedFor({bool includeOnline = true}) =>
      validate(answers, includeOnline: includeOnline) == null &&
      fields(answers, includeOnline: includeOnline)
          .every((key) => decisions[key] == 'Approve');
}
