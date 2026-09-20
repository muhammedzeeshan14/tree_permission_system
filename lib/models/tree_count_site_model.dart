class TreeCountSiteModel {

  int? id;

  int applicationId;

  String siteDetails;

  int displayOrder;

  TreeCountSiteModel({

    this.id,

    required this.applicationId,

    required this.siteDetails,

    required this.displayOrder,

  });

  Map<String, dynamic> toMap() {

    return {

      "id": id,

      "applicationId": applicationId,

      "siteDetails": siteDetails,

      "displayOrder": displayOrder,

    };

  }

  factory TreeCountSiteModel.fromMap(
      Map<String, dynamic> map) {

    return TreeCountSiteModel(

      id: map["id"],

      applicationId: map["applicationId"],

      siteDetails: map["siteDetails"] ?? "",

      displayOrder: map["displayOrder"],

    );

  }

}