class ApplicationReferenceModel {
  final int sourceId;
  final String sourceKind; // SOURCE | AGENCY | OFFICER
  final String forwardedBy;
  final String referenceNumber;
  final String referenceDate;

  ApplicationReferenceModel({
    required this.sourceId,
    this.sourceKind = 'SOURCE',
    required this.forwardedBy,
    required this.referenceNumber,
    required this.referenceDate,
  });
}