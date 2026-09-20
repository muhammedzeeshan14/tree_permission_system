class RevenueOpinionModel {

  int? id;

  String revenueOpinion;

  String code;

  String officeName;

  String officeAddress;

  String remarks;

  int displayOrder;

  bool isActive;

  RevenueOpinionModel({

    this.id,

    required this.revenueOpinion,

    required this.code,

    required this.officeName,

    required this.officeAddress,

    required this.remarks,

    required this.displayOrder,

    required this.isActive,

  });

  Map<String, dynamic> toMap() {

    return {

      "id": id,

      "revenueOpinion": revenueOpinion,

      "code": code,

      "officeName": officeName,

      "officeAddress": officeAddress,

      "remarks": remarks,

      "displayOrder": displayOrder,

      "isActive": isActive ? 1 : 0,

    };

  }

  factory RevenueOpinionModel.fromMap(

      Map<String, dynamic> map) {

    return RevenueOpinionModel(

      id: map["id"],

      revenueOpinion:
          map["revenueOpinion"] ?? "",

      code: map["code"] ?? "",

      officeName:
          map["officeName"] ?? "",

      officeAddress:
          map["officeAddress"] ?? "",

      remarks:
          map["remarks"] ?? "",

      displayOrder:
          map["displayOrder"] ?? 1,

      isActive:
          (map["isActive"] ?? 1) == 1,

    );

  }

}