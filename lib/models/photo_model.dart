class PhotoModel {

  int? id;

  int applicationId;

  String photoPath;

  String caption;

  String createdDate;

  PhotoModel({

    this.id,

    required this.applicationId,

    required this.photoPath,

    required this.caption,

    required this.createdDate,

  });

}