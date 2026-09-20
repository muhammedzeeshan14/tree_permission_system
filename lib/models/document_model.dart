class DocumentModel {

  int? id;

  int applicationId;

  int? documentTypeId;

  String documentTypeName;

  String filePath;

  String remarks;

  String createdDate;

  DocumentModel({

    this.id,

    required this.applicationId,

    required this.documentTypeId,

    required this.documentTypeName,

    required this.filePath,

    required this.remarks,

    required this.createdDate,

  });

}