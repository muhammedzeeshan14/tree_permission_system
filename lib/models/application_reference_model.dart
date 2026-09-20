class ApplicationReferenceModel {
  final int sourceId;
  final String forwardedBy;
  final String referenceNumber;
  final String referenceDate;

  ApplicationReferenceModel({
    required this.sourceId,
    required this.forwardedBy,
    required this.referenceNumber,
    required this.referenceDate,
  });
}