import 'dart:convert';

class GovernmentApproval {
  static const types = ['Auction', 'Valuation'];
  static const natures = ['Satisfied', 'Not satisfied'];
  static const questions = {
    'authority':'1. Documents / reply giving authority',
    'letterNumber':'2. Letter no.',
    'letterDate':'3. Letter date',
    'receivedDate':'4. Letter received date',
    'nature':'5. Reply nature',
  };
  final int applicationId, revision;
  final String permissionType, stage, requestDate, requestLetterPath, finalDate;
  final bool? khataGiven;
  final int? treeOfficerId;
  final Map<String,String> answers;
  final Set<String> approvedFields;
  final List<String> finalPaths;
  GovernmentApproval.fromMap(Map<String,dynamic> row)
    : applicationId=row['applicationId'] as int, revision=row['revision'] as int? ?? 0,
      permissionType=row['permissionType'] as String? ?? '', stage=row['stage'] as String? ?? 'draft',
      khataGiven=row['khataGiven']==null?null:row['khataGiven']==1,treeOfficerId=row['treeOfficerId'] as int?,
      requestDate=row['requestDate'] as String? ?? '',requestLetterPath=row['requestLetterPath'] as String? ?? '',finalDate=row['finalDate'] as String? ?? '',
      answers=Map<String,String>.from(jsonDecode(row['answers'] as String? ?? '{}')),
      approvedFields=Set<String>.from(jsonDecode(row['approvedFields'] as String? ?? '[]')),
      finalPaths=List<String>.from(jsonDecode(row['finalPaths'] as String? ?? '[]'));
  static bool isGovernment(String type)=>{'STGL','CGL','GL','MCC'}.contains(type.trim().toUpperCase());
  static String? validateAnswers(Map<String,String> answers) {
    for(final key in questions.keys) {if((answers[key]??'').trim().isEmpty)return 'Enter '+questions[key]!+'.';}
    if(!natures.contains(answers['nature']))return 'Select reply nature.';
    final date=DateTime.tryParse(answers['letterDate']??'');final received=DateTime.tryParse(answers['receivedDate']??'');
    if(date==null||received==null)return 'Select valid letter dates.';
    if(received.isBefore(date))return 'Received date cannot precede letter date.';
    return null;
  }
  bool get allApproved=>validateAnswers(answers)==null&&questions.keys.every(approvedFields.contains);
}
