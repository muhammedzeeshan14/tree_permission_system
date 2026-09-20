class TreeModel {
  int? id;

  int applicationId;

  String treeNumber;

  int baseTreeNumber;

  String stemType; // Single / Multiple

  String stemLetter; // "", A, B, C...

  int stemSequence;

bool isLastStem;

  int speciesId;
  int recommendationTypeId;
  int? treeStatusId;

  double? gbh;

  double? height;

  bool notFitForTimber;

  int? numberOfBranches;
  int? numberOfTwigs;

  double firewood;

  List<int> recommendationReasonIds;

  String remarks;

  TreeModel({
    this.id,
    required this.applicationId,
    required this.treeNumber,
    required this.baseTreeNumber,
    required this.stemType,
    required this.stemLetter,

required this.stemSequence,

required this.isLastStem,

required this.speciesId,
required this.recommendationTypeId,
this.treeStatusId,
    this.gbh,
    this.height,

this.notFitForTimber = false,

this.numberOfBranches,
this.numberOfTwigs,
required this.firewood,
required this.recommendationReasonIds,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "applicationId": applicationId,
      "treeNumber": treeNumber,
      "baseTreeNumber": baseTreeNumber,
      "stemType": stemType,
      "stemLetter": stemLetter,

"stemSequence": stemSequence,

"isLastStem": isLastStem ? 1 : 0,

"speciesId": speciesId,
"recommendationTypeId": recommendationTypeId,
"treeStatusId": treeStatusId,
      "gbh": gbh,
"height": height,

"notFitForTimber":
    notFitForTimber ? 1 : 0,

"numberOfBranches": numberOfBranches,
"numberOfTwigs": numberOfTwigs,
"firewood": firewood,
"recommendationReasonIds":
    recommendationReasonIds.join(","),
"remarks": remarks,
    };
  }

  factory TreeModel.fromMap(
      Map<String, dynamic> map) {
    return TreeModel(
      id: map["id"],
      applicationId: map["applicationId"],
      treeNumber: map["treeNumber"],
      baseTreeNumber: map["baseTreeNumber"],
      stemType: map["stemType"],
      stemLetter: map["stemLetter"],

stemSequence: map["stemSequence"] ?? 1,

isLastStem: (map["isLastStem"] ?? 1) == 1,

speciesId: map["speciesId"],

recommendationTypeId:
    map["recommendationTypeId"] ?? 0,
    treeStatusId: map["treeStatusId"],
      gbh: map["gbh"] == null
    ? null
    : (map["gbh"] as num).toDouble(),

height: map["height"] == null
    ? null
    : (map["height"] as num).toDouble(),
    notFitForTimber:
    (map["notFitForTimber"] ?? 0) == 1,
    numberOfBranches: map["numberOfBranches"],

numberOfTwigs: map["numberOfTwigs"],

firewood: map["firewood"] == null
    ? 0
    : (map["firewood"] as num).toDouble(),
      
      recommendationReasonIds:
          map["recommendationReasonIds"]
              .toString()
              .isEmpty
          ? []
          : map["recommendationReasonIds"]
              .toString()
              .split(",")
              .map((e) => int.parse(e))
              .toList(),
      remarks: map["remarks"] ?? "",
    );
  }
}