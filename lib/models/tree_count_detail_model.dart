class TreeCountDetailModel {

  int? id;

  int siteId;

  int speciesId;

  int treeCount;

  int displayOrder;

  TreeCountDetailModel({

    this.id,

    required this.siteId,

    required this.speciesId,

    required this.treeCount,

    required this.displayOrder,

  });

  Map<String, dynamic> toMap() {

    return {

      "id": id,

      "siteId": siteId,

      "speciesId": speciesId,

      "treeCount": treeCount,

      "displayOrder": displayOrder,

    };

  }

  factory TreeCountDetailModel.fromMap(
      Map<String, dynamic> map) {

    return TreeCountDetailModel(

      id: map["id"],

      siteId: map["siteId"],

      speciesId: map["speciesId"],

      treeCount: map["treeCount"],

      displayOrder: map["displayOrder"],

    );

  }

}