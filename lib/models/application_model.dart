import 'tree_model.dart';
import 'application_reference_model.dart';

class ApplicationModel {
  int? id;

  // ===========================
  // BASIC DETAILS
  // ===========================

  String officeNumber;
  String applicationType;

String verifiedApplicationType;

int? permissionTypeId;

String permissionType;

  String applicantLetterNumber;
  String applicationDate;
  String receivedDate;

  String applicantName;

String applicantAddress;

bool treeLocationSame;

String treeLocationAddress;

String mobile;

  // ===========================
// APPLICATION SOURCE
// ===========================

String applicationSource;

String forwardedDate;
String drfoAssignmentDate;

List<ApplicationReferenceModel> forwardingReferences;

 // ===========================
// DATABASE IDS
// ===========================

int? createdBy;

int? sectionId;

int? beatId;

int? assignedBFOId;

int? assignedDRFOId;

// ===========================
// DISPLAY VALUES
// ===========================

String section;

String beat;

String assignedBFO;

String assignedDRFO;

  // ===========================
  // APPLICATION
  // ===========================

  int? purposeId;

String purpose;

int? whyRemovingId;

  int? governmentAgencyId;

int? urbanRuralId;

int? structureTypeId;

String workName;

// ===========================
// BFO
// ===========================

String gpsCoordinates;

String bfoVerificationDate;

bool inspectionStarted;

String inspectionDecision;

List<int> deferredReasonIds;

int? overallRemarkId;

String overallRemarks;

  // ===========================
  // DRFO
  // ===========================

  String drfoInspectionDate;

  String drfoOverallRemarks;

  // ===========================
  // RFO
  // ===========================

  bool rfoInspectionStarted;

 String rfoInspectionDate;

String rfoApprovalDate;

String rfoOverallRemarks;

  // ===========================
  // RETURN
  // ===========================

  String returnReason;

  String returnRemarks;

  String returnedBy;

  String returnedDate;

  // ===========================
  // TREES
  // ===========================

  List<TreeModel> trees;

  int? sandalDestinationId;

  String sandalDestinationCustom;

  // ===========================
  // STATUS
  // ===========================

  String status;

  String inspectionMode;

  DateTime createdDate;

  ApplicationModel({

    this.id,

    required this.officeNumber,

    required this.applicationType,

required this.verifiedApplicationType,

this.permissionTypeId,

this.permissionType = "",

this.applicantLetterNumber = '',
required this.applicationDate,

    required this.receivedDate,

    required this.applicantName,

required this.applicantAddress,

this.treeLocationSame = true,

this.treeLocationAddress = "",

required this.mobile,

  required this.applicationSource,

required this.forwardedDate,
this.drfoAssignmentDate = "",

this.forwardingReferences = const [],

    this.createdBy,

this.sectionId,

this.beatId,

this.assignedBFOId,

this.assignedDRFOId,

required this.section,

required this.beat,

required this.assignedBFO,

required this.assignedDRFO,

    this.purposeId,

required this.purpose,

this.whyRemovingId,

    this.governmentAgencyId,

this.urbanRuralId,

this.structureTypeId,

this.workName = "",

   required this.gpsCoordinates,

required this.bfoVerificationDate,

required this.inspectionStarted,

required this.inspectionDecision,

required this.deferredReasonIds,

this.overallRemarkId,

required this.overallRemarks,

    required this.drfoInspectionDate,

    required this.drfoOverallRemarks,

    required this.rfoInspectionStarted,

   required this.rfoInspectionDate,

this.rfoApprovalDate = "",

required this.rfoOverallRemarks,

    required this.returnReason,

    required this.returnRemarks,

    required this.returnedBy,

    required this.returnedDate,

    required this.trees,

    this.sandalDestinationId,

    this.sandalDestinationCustom = "",

    required this.status,

    required this.inspectionMode,

    required this.createdDate,

  });

}