class ApplicationRevenueOpinionModel {

  int? id;

  int applicationId;

  int revenueOpinionId;

  ApplicationRevenueOpinionModel({

    this.id,

    required this.applicationId,

    required this.revenueOpinionId,

  });

  Map<String,dynamic> toMap(){

    return{

      "id":id,

      "applicationId":applicationId,

      "revenueOpinionId":revenueOpinionId,

    };

  }

  factory ApplicationRevenueOpinionModel.fromMap(
      Map<String,dynamic> map){

    return ApplicationRevenueOpinionModel(

      id:map["id"],

      applicationId:map["applicationId"],

      revenueOpinionId:map["revenueOpinionId"],

    );

  }

}