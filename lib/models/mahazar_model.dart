class MahazarModel {

  int? id;

  int applicationId;

  String mahazarDate;

  String startTime;

String startTimeManual;

String endTime;

String endTimeManual;
int? northLocationId;

int? eastLocationId;

int? southLocationId;

int? westLocationId;

  String northBoundary;

  String eastBoundary;

  String southBoundary;

  String westBoundary;

  MahazarModel({

    this.id,

    required this.applicationId,

    this.mahazarDate = "",

    this.startTime = "",

this.startTimeManual = "",

this.endTime = "",

this.endTimeManual = "",
this.northLocationId,

this.eastLocationId,

this.southLocationId,

this.westLocationId,

    this.northBoundary = "",

    this.eastBoundary = "",

    this.southBoundary = "",

    this.westBoundary = "",

  });

  Map<String, dynamic> toMap() {

    return {

      "id": id,

      "applicationId": applicationId,

      "mahazarDate": mahazarDate,

      "startTime": startTime,

"startTimeManual": startTimeManual,

"endTime": endTime,

"endTimeManual": endTimeManual,
"northLocationId": northLocationId,

"eastLocationId": eastLocationId,

"southLocationId": southLocationId,

"westLocationId": westLocationId,
      "northBoundary": northBoundary,

      "eastBoundary": eastBoundary,

      "southBoundary": southBoundary,

      "westBoundary": westBoundary,

    };

  }

  factory MahazarModel.fromMap(
      Map<String, dynamic> map) {

    return MahazarModel(

      id: map["id"],

      applicationId: map["applicationId"],

      mahazarDate:
          map["mahazarDate"] ?? "",

          startTime:
    map["startTime"] ?? "",

startTimeManual:
    map["startTimeManual"] ?? "",

endTime:
    map["endTime"] ?? "",

endTimeManual:
    map["endTimeManual"] ?? "",

northLocationId:
    map["northLocationId"] as int?,

eastLocationId:
    map["eastLocationId"] as int?,

southLocationId:
    map["southLocationId"] as int?,

westLocationId:
    map["westLocationId"] as int?,

      northBoundary:
          map["northBoundary"] ?? "",

      eastBoundary:
          map["eastBoundary"] ?? "",

      southBoundary:
          map["southBoundary"] ?? "",

      westBoundary:
          map["westBoundary"] ?? "",

    );

  }

}