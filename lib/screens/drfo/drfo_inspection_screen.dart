import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../services/workflow_service.dart';
import '../../services/session_service.dart';
import '../../constants/workflow_status.dart';
import '../../widgets/verification_card.dart';
import '../../repositories/master_repository.dart';
import '../../repositories/application_verification_repository.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/application_type_repository.dart';
import '../../repositories/application_type_permission_mapping_repository.dart';
import 'tree_verification_screen.dart';
import '../../repositories/photo_repository.dart';
import '../../models/photo_model.dart';
import 'dart:io';
import '../../services/drfo_document_service.dart';
import '../../repositories/document_repository.dart';
import '../../models/document_model.dart';
import 'package:open_filex/open_filex.dart';
import '../bfo/wizard/inspection_summary_step.dart';
import '../bfo/wizard/photo_step.dart';
import '../bfo/wizard/document_step.dart';
import 'generate_documents_screen.dart';
import '../../repositories/inspection_defer_reason_repository.dart';
import 'tree_count_verification_screen.dart';
import 'revenue_opinion_verification_screen.dart';
import 'mahazar_verification_screen.dart';
import '../../repositories/tree_repository.dart';
import 'drfo_forwarded_application_screen.dart';

class DRFOInspectionScreen extends StatefulWidget {

  final ApplicationModel application;

  const DRFOInspectionScreen({

    super.key,

    required this.application,

  });

  @override
  State<DRFOInspectionScreen> createState() =>
      _DRFOInspectionScreenState();

}

class _DRFOInspectionScreenState
    extends State<DRFOInspectionScreen> {

final WorkflowService workflowService =
    WorkflowService();

final DrfoDocumentService documentService =
    DrfoDocumentService();

final ApplicationVerificationRepository
    verificationRepository =
        ApplicationVerificationRepository();

  final PageController pageController =
      PageController();

      final GlobalKey<TreeVerificationScreenState>
    treeVerificationKey =
        GlobalKey<TreeVerificationScreenState>();

        final GlobalKey<TreeCountVerificationScreenState>
    treeCountVerificationKey =
        GlobalKey<TreeCountVerificationScreenState>();

        final GlobalKey<RevenueOpinionVerificationScreenState>
    revenueOpinionVerificationKey =
        GlobalKey<RevenueOpinionVerificationScreenState>();

        final GlobalKey<MahazarVerificationScreenState>
    mahazarVerificationKey =
        GlobalKey<MahazarVerificationScreenState>();

  int currentPage = 0;
bool allTreesNotRecommended = false;
bool allTreesBranchOnly = false;

bool get isTreeCount {
  return widget.application.applicationType
          .trim()
          .toUpperCase() ==
      'RTC';
}

bool get isGovernmentCategory {
  final type = widget.application.applicationType
      .trim()
      .toUpperCase();

  return type == "GL" ||
      type == "STGL" ||
      type == "CGL" ||
      type == "SGL";
}

bool get isPrivateCategory {
  final type = widget.application.applicationType
      .trim()
      .toUpperCase();

  return type == "PL" || type == "SPL";
}

bool get showsAdditionalDetails =>
    isGovernmentCategory || isPrivateCategory;

    String get selectedWhyRemovingCode {
  final selectedId =
      widget.application.whyRemovingId;

  if (selectedId == null) return "";

  final matches = whyRemovingList.where(
    (item) => item["id"] == selectedId,
  );

  if (matches.isEmpty) return "";

  return matches.first["code"]
          ?.toString()
          .trim()
          .toUpperCase() ??
      "";
}

bool get isDevelopmentWork =>
    selectedWhyRemovingCode == "WORKS";

bool get showsNameOfWork =>
    showsAdditionalDetails &&
    isDevelopmentWork;

bool get needsRevenueOpinion {
  final type = widget.application.applicationType
      .trim()
      .toUpperCase();

  return !isTreeCount &&
      !allTreesNotRecommended &&
      !allTreesBranchOnly &&
      (type == 'PL' || type == 'SPL');
}

bool get needsMahazar {
  return !isTreeCount && !allTreesNotRecommended;
}

bool get needsOverallRemarkVerification =>
    !isTreeCount;

int get overallRemarkPageIndex =>
    3 +
    (needsRevenueOpinion ? 1 : 0) +
    (needsMahazar ? 1 : 0);

int get documentsPageIndex =>
    overallRemarkPageIndex +
    (needsOverallRemarkVerification ? 1 : 0);

Future<void> loadTreeRequirements() async {
  final applicationId = widget.application.id;

  if (applicationId == null || isTreeCount) {
    allTreesNotRecommended = false;
    allTreesBranchOnly = false;
    return;
  }

  allTreesNotRecommended = await TreeRepository()
      .areAllTreesNotRecommended(applicationId);
  allTreesBranchOnly = await TreeRepository().areAllTreesBranchOnly(applicationId);
}
  bool get isDeferred =>
    widget.application.inspectionDecision == "DEFERRED";
  
  bool? applicationTypeCorrect;
bool? governmentAgencyCorrect;
bool? urbanRuralCorrect;
bool? whyRemovingCorrect;
bool? purposeCorrect;
bool? structureTypeCorrect;
bool? workNameCorrect;
bool? overallRemarkCorrect;
bool? gpsCorrect;
bool? photosCorrect;
bool? documentsCorrect;

String? applicationTypeReason;
String? governmentAgencyReason;
String? urbanRuralReason;
String? whyRemovingReason;
String? purposeReason;
String? structureTypeReason;
String? workNameReason;
String? overallRemarkReason;
String? gpsReason;
String? photosReason;
String? documentsReason;

// Three-option verification statuses.
// Values: Correct, Modify, Re-inspect
String? applicationTypeStatus;
String? governmentAgencyStatus;
String? urbanRuralStatus;
String? whyRemovingStatus;
String? purposeStatus;
String? structureTypeStatus;
String? workNameStatus;
String? overallRemarkStatus;
String? gpsStatus;
String? photosStatus;
String? documentsStatus;

bool? deferredCorrect;
String? deferredReason;

List<String> deferredReasons = [];

final MasterRepository masterRepository = MasterRepository();
final PhotoRepository photoRepository = PhotoRepository();
final DocumentRepository documentRepository =
    DocumentRepository();

final InspectionDeferredReasonRepository deferredRepository =
    InspectionDeferredReasonRepository();

List<Map<String, dynamic>> selectedDeferredReasons = [];

List<DocumentModel> documents = [];
List<PhotoModel> photos = [];
List<File> generatedDocuments = [];

List<String> applicationTypeReasons = [];
List<String> gpsReasons = [];
List<String> photoReasons = [];
List<String> documentReasons = [];

String applicationTypeDisplay = "";
String governmentAgencyDisplay = "";
String urbanRuralDisplay = "";
String whyRemovingDisplay = "";
String purposeDisplay = "";
String structureTypeDisplay = "";
String overallRemarkDisplay = "";

List<Map<String, dynamic>> applicationTypeList = [];
List<Map<String, dynamic>> governmentAgencyList = [];
List<Map<String, dynamic>> urbanRuralList = [];
List<Map<String, dynamic>> whyRemovingList = [];
List<Map<String, dynamic>> allPurposeList = [];
List<Map<String, dynamic>> purposeList = [];
List<Map<String, dynamic>> structureTypeList = [];
List<Map<String, dynamic>> overallRemarkList = [];

int? selectedOverallRemarkId;

final TextEditingController workNameController =
    TextEditingController();

final TextEditingController gpsController =
    TextEditingController();

@override
void initState() {
  super.initState();

  workNameController.text =
      widget.application.workName;

  gpsController.text =
      widget.application.gpsCoordinates;

  selectedOverallRemarkId =
      widget.application.overallRemarkId;

debugPrint(
    "Verified Type = ${widget.application.verifiedApplicationType}");

debugPrint(
    "Application Type = ${widget.application.applicationType}");

  _initialize();
}

@override
void dispose() {
  workNameController.dispose();
  gpsController.dispose();
  super.dispose();
}

Future<void> _initialize() async {
  await loadTreeRequirements();

  await _loadVerificationReasons();
  await _loadAdditionalApplicationDetails();

  selectedDeferredReasons =
      await deferredRepository.getReasons(
    widget.application.id!,
  );

    await _loadSavedVerification();

  // Do NOT load previously generated documents here.
  // Documents must be freshly generated only when
  // DRFO completes verification and forwards the application to RFO.
  generatedDocuments = [];

  if (mounted) {
    setState(() {});
  }

}

Future<void> _loadVerificationReasons() async {
  applicationTypeReasons =
      await masterRepository.getVerificationReasons(
    "APPLICATION_TYPE",
  );

  gpsReasons =
      await masterRepository.getVerificationReasons(
    "GPS",
  );

  photoReasons =
      await masterRepository.getVerificationReasons(
    "PHOTO",
  );

  documentReasons =
      await masterRepository.getVerificationReasons(
    "DOCUMENT",
  );

photos = await photoRepository.getPhotos(
  widget.application.id!,
);

documents =
    await documentRepository.getDocuments(
  widget.application.id!,
);

deferredReasons =
    await masterRepository.getVerificationReasons(
  "DEFERRED",
);

  if (mounted) {
    setState(() {});
  }
}

void _filterPurposeList() {
  final parentCode =
      selectedWhyRemovingCode;

  if (parentCode.isEmpty) {
    purposeList = [];
    return;
  }

  purposeList = allPurposeList.where((item) {
    final purposeParentCode =
        item["parentCode"]
                ?.toString()
                .trim()
                .toUpperCase() ??
            "";

    return purposeParentCode == parentCode;
  }).toList();
}

Future<void> _loadAdditionalApplicationDetails() async {
    final applicationTypes =
      await ApplicationTypeRepository().getAll();

  final savedApplicationType =
      widget.application.applicationType.trim().toUpperCase();

  applicationTypeList = applicationTypes.where((item) {
    final isActive = item["isActive"] == 1;

    final code =
        item["shortCode"]?.toString().trim().toUpperCase() ??
            "";

    final name = item["applicationType"]
            ?.toString()
            .trim()
            .toUpperCase() ??
        "";

    return isActive ||
        code == savedApplicationType ||
        name == savedApplicationType;
  }).toList();

  final allGovernmentAgencies =
      await masterRepository.getMasters(
    "Government Agency",
  );

  final allUrbanRural =
      await masterRepository.getMasters(
    "Urban Rural",
  );

  final allWhyRemoving =
      await masterRepository.getMasters(
    "Why Removing",
  );

  final allPurposes =
      await masterRepository.getMasters(
    "Purpose",
  );

  final allStructureTypes =
      await masterRepository.getMasters(
    "Structure Type",
  );

  final allOverallRemarks =
      await masterRepository.getMasters(
    "Inspecting Officer Overall Remark",
  );

  List<Map<String, dynamic>> activeOrSelected(
    List<Map<String, dynamic>> items,
    int? selectedId,
  ) {
    return items.where((item) {
      return item["isActive"] == 1 ||
          item["id"] == selectedId;
    }).toList();
  }

  governmentAgencyList = activeOrSelected(
    allGovernmentAgencies,
    widget.application.governmentAgencyId,
  );

  urbanRuralList = activeOrSelected(
    allUrbanRural,
    widget.application.urbanRuralId,
  );

  whyRemovingList = activeOrSelected(
    allWhyRemoving,
    widget.application.whyRemovingId,
  );

  allPurposeList = activeOrSelected(
    allPurposes,
    widget.application.purposeId,
  );

  _filterPurposeList();

  structureTypeList = activeOrSelected(
    allStructureTypes,
    widget.application.structureTypeId,
  );

  overallRemarkList = activeOrSelected(
    allOverallRemarks,
    widget.application.overallRemarkId,
  );

  final savedType = widget.application.applicationType
      .trim()
      .toUpperCase();

  final matchingTypes = applicationTypes.where((item) {
    final code =
        item["shortCode"]?.toString().trim().toUpperCase() ??
            "";

    final name = item["applicationType"]
            ?.toString()
            .trim()
            .toUpperCase() ??
        "";

    return code == savedType || name == savedType;
  });

  if (matchingTypes.isNotEmpty) {
    final item = matchingTypes.first;

    // Show English only in the application.
    // Kannada remains stored in the master for documents.
    applicationTypeDisplay =
        item["applicationType"]?.toString().trim() ?? "";
  } else {
    applicationTypeDisplay =
        widget.application.verifiedApplicationType
                .trim()
                .isNotEmpty
            ? widget.application.verifiedApplicationType
            : widget.application.applicationType;
  }

  String masterDisplay(
    Map<String, dynamic>? item,
  ) {
    if (item == null) return "";

    // Display only the English master value in the app.
    // Kannada is retained in the database for letter generation.
    return item["value"]?.toString().trim() ?? "";
  }

  final governmentAgency =
      await masterRepository.getMasterById(
    widget.application.governmentAgencyId,
  );

  final urbanRural =
      await masterRepository.getMasterById(
    widget.application.urbanRuralId,
  );

  final whyRemoving =
      await masterRepository.getMasterById(
    widget.application.whyRemovingId,
  );

  final purpose =
      await masterRepository.getMasterById(
    widget.application.purposeId,
  );

  final structureType =
      await masterRepository.getMasterById(
    widget.application.structureTypeId,
  );

  final overallRemark =
      await masterRepository.getMasterById(
    widget.application.overallRemarkId,
  );

  governmentAgencyDisplay =
      masterDisplay(governmentAgency);

  urbanRuralDisplay =
      masterDisplay(urbanRural);

  whyRemovingDisplay =
      masterDisplay(whyRemoving);

  purposeDisplay =
      masterDisplay(purpose);

  // Compatibility for older applications where purpose
  // was stored directly as text without a purposeId.
  if (purposeDisplay.isEmpty) {
    purposeDisplay = widget.application.purpose.trim();
  }

  structureTypeDisplay =
      masterDisplay(structureType);

  overallRemarkDisplay =
      masterDisplay(overallRemark);

  if (overallRemarkDisplay.isEmpty) {
    overallRemarkDisplay =
        widget.application.overallRemarks.trim();
  }
}

Future<void> _loadSavedVerification() async {
  final verification =
      await verificationRepository.getVerification(
    widget.application.id!,
  );

  if (verification == null) return;

  bool? readVerificationValue(String column) {
    final value = verification[column];

    if (value == null) return null;

    if (value is bool) return value;

    if (value is num) return value == 1;

    return value.toString() == "1";
  }

  String? readReason(String column) {
    final value = verification[column];

    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? readVerificationStatus(
    String statusColumn,
    bool? oldValue,
  ) {
    final savedStatus =
        verification[statusColumn]?.toString().trim();

    if (savedStatus == "Correct" ||
        savedStatus == "Modify" ||
        savedStatus == "Re-inspect") {
      return savedStatus;
    }

    // Backward compatibility for verification records
    // saved before the Modify option was introduced.
    if (oldValue == null) return null;

    return oldValue ? "Correct" : "Re-inspect";
  }

  applicationTypeCorrect =
      readVerificationValue("applicationTypeCorrect");

  governmentAgencyCorrect =
      readVerificationValue("governmentAgencyCorrect");

  urbanRuralCorrect =
      readVerificationValue("urbanRuralCorrect");

  whyRemovingCorrect =
      readVerificationValue("whyRemovingCorrect");

  purposeCorrect =
      readVerificationValue("purposeCorrect");

  structureTypeCorrect =
      readVerificationValue("structureTypeCorrect");

  workNameCorrect =
      readVerificationValue("workNameCorrect");

  overallRemarkCorrect =
      readVerificationValue("overallRemarkCorrect");

  gpsCorrect =
      readVerificationValue("gpsCorrect");

  photosCorrect =
      readVerificationValue("photosCorrect");

  documentsCorrect =
      readVerificationValue("documentsCorrect");

  applicationTypeReason =
      readReason("applicationTypeReason");

  governmentAgencyReason =
      readReason("governmentAgencyReason");

  urbanRuralReason =
      readReason("urbanRuralReason");

  whyRemovingReason =
      readReason("whyRemovingReason");

  purposeReason =
      readReason("purposeReason");

  structureTypeReason =
      readReason("structureTypeReason");

  workNameReason =
      readReason("workNameReason");

  overallRemarkReason =
      readReason("overallRemarkReason");

  gpsReason =
      readReason("gpsReason");

  photosReason =
      readReason("photosReason");

  documentsReason =
      readReason("documentsReason");

  deferredCorrect =
      readVerificationValue("deferredCorrect");

  deferredReason =
      readReason("deferredReason");

  applicationTypeStatus =
      readVerificationStatus(
    "applicationTypeStatus",
    applicationTypeCorrect,
  );

  governmentAgencyStatus =
      readVerificationStatus(
    "governmentAgencyStatus",
    governmentAgencyCorrect,
  );

  urbanRuralStatus =
      readVerificationStatus(
    "urbanRuralStatus",
    urbanRuralCorrect,
  );

  whyRemovingStatus =
      readVerificationStatus(
    "whyRemovingStatus",
    whyRemovingCorrect,
  );

  purposeStatus =
      readVerificationStatus(
    "purposeStatus",
    purposeCorrect,
  );

  structureTypeStatus =
      readVerificationStatus(
    "structureTypeStatus",
    structureTypeCorrect,
  );

  workNameStatus =
      readVerificationStatus(
    "workNameStatus",
    workNameCorrect,
  );

  overallRemarkStatus =
      readVerificationStatus(
    "overallRemarkStatus",
    overallRemarkCorrect,
  );

  gpsStatus =
      readVerificationStatus(
    "gpsStatus",
    gpsCorrect,
  );

  photosStatus =
      readVerificationStatus(
    "photosStatus",
    photosCorrect,
  );

  documentsStatus =
      readVerificationStatus(
    "documentsStatus",
    documentsCorrect,
  );

  if (mounted) {
    setState(() {});
  }
}


Future<void> _saveVerification() async {
  bool? statusToLegacyValue(
    String? status,
    bool? existingValue,
  ) {
    if (status == "Correct" || status == "Modify") {
      return true;
    }

    if (status == "Re-inspect") {
      return false;
    }

    return existingValue;
  }

  applicationTypeCorrect = statusToLegacyValue(
    applicationTypeStatus,
    applicationTypeCorrect,
  );

  governmentAgencyCorrect = statusToLegacyValue(
    governmentAgencyStatus,
    governmentAgencyCorrect,
  );

  urbanRuralCorrect = statusToLegacyValue(
    urbanRuralStatus,
    urbanRuralCorrect,
  );

  whyRemovingCorrect = statusToLegacyValue(
    whyRemovingStatus,
    whyRemovingCorrect,
  );

  purposeCorrect = statusToLegacyValue(
    purposeStatus,
    purposeCorrect,
  );

  structureTypeCorrect = statusToLegacyValue(
    structureTypeStatus,
    structureTypeCorrect,
  );

  workNameCorrect = statusToLegacyValue(
    workNameStatus,
    workNameCorrect,
  );

  overallRemarkCorrect = statusToLegacyValue(
    overallRemarkStatus,
    overallRemarkCorrect,
  );

  gpsCorrect = statusToLegacyValue(
    gpsStatus,
    gpsCorrect,
  );

  photosCorrect = statusToLegacyValue(
    photosStatus,
    photosCorrect,
  );

  documentsCorrect = statusToLegacyValue(
    documentsStatus,
    documentsCorrect,
  );

  await verificationRepository.saveVerification(
    applicationId: widget.application.id!,

    applicationTypeCorrect:
        applicationTypeCorrect,
    applicationTypeReason:
        applicationTypeReason,

    governmentAgencyCorrect:
        isGovernmentCategory
            ? governmentAgencyCorrect
            : null,
    governmentAgencyReason:
        isGovernmentCategory
            ? governmentAgencyReason
            : null,

    urbanRuralCorrect:
        isPrivateCategory
            ? urbanRuralCorrect
            : null,
    urbanRuralReason:
        isPrivateCategory
            ? urbanRuralReason
            : null,

    whyRemovingCorrect:
        showsAdditionalDetails
            ? whyRemovingCorrect
            : null,
    whyRemovingReason:
        showsAdditionalDetails
            ? whyRemovingReason
            : null,

    purposeCorrect:
        showsAdditionalDetails
            ? purposeCorrect
            : null,
    purposeReason:
        showsAdditionalDetails
            ? purposeReason
            : null,

    structureTypeCorrect:
        showsAdditionalDetails
            ? structureTypeCorrect
            : null,
    structureTypeReason:
        showsAdditionalDetails
            ? structureTypeReason
            : null,

    workNameCorrect:
        showsNameOfWork
            ? workNameCorrect
            : null,
    workNameReason:
        showsNameOfWork
            ? workNameReason
            : null,

    overallRemarkCorrect:
        !isTreeCount
            ? overallRemarkCorrect
            : null,
    overallRemarkReason:
        !isTreeCount
            ? overallRemarkReason
            : null,

    gpsCorrect: gpsCorrect,
    gpsReason: gpsReason,

    photosCorrect: photosCorrect,
    photosReason: photosReason,

    documentsCorrect: documentsCorrect,
    documentsReason: documentsReason,

    applicationTypeStatus:
        applicationTypeStatus,

    governmentAgencyStatus:
        isGovernmentCategory
            ? governmentAgencyStatus
            : null,

    urbanRuralStatus:
        isPrivateCategory
            ? urbanRuralStatus
            : null,

    whyRemovingStatus:
        showsAdditionalDetails
            ? whyRemovingStatus
            : null,

    purposeStatus:
        showsAdditionalDetails
            ? purposeStatus
            : null,

    structureTypeStatus:
        showsAdditionalDetails
            ? structureTypeStatus
            : null,

    workNameStatus:
        showsNameOfWork
            ? workNameStatus
            : null,

    overallRemarkStatus:
        !isTreeCount
            ? overallRemarkStatus
            : null,

    gpsStatus: gpsStatus,
    photosStatus: photosStatus,
    documentsStatus: documentsStatus,

    deferredCorrect: isDeferred ? deferredCorrect : null,
    deferredReason: isDeferred ? deferredReason : null,

    verifiedBy: SessionService.instance.name,
  );

  // Save deferred inspection reasons.
  if (isDeferred) {
    await deferredRepository.saveReasons(
      applicationId: widget.application.id!,
      reasons: selectedDeferredReasons,
    );
  }
}

Future<void> _changeVerificationStatus({
  required String? newStatus,
  required void Function(String?) setStatus,
  required void Function(bool?) setLegacyValue,
  required VoidCallback clearReason,
}) async {
  setState(() {
    setStatus(newStatus);

    if (newStatus == null) {
      setLegacyValue(null);
    } else if (newStatus == "Re-inspect") {
      setLegacyValue(false);
    } else {
      // Both Correct and Modify are accepted values.
      setLegacyValue(true);
    }

    // A reason is required only for Re-inspect.
    if (newStatus != "Re-inspect") {
      clearReason();
    }
  });

  await _saveVerification();
}

Future<void> _saveCorrectedApplication() async {
  await ApplicationRepository().updateApplication(
    widget.application,
  );

  await _loadAdditionalApplicationDetails();

  if (mounted) {
    setState(() {});
  }
}

void _showPhotos() {

  showDialog(

    context: context,

    builder: (_) {

      return Dialog(

        child: SizedBox(

          width: 900,
          height: 600,

          child: Column(

            children: [

              AppBar(

                automaticallyImplyLeading: false,

                title: Text(
                  "Inspection Photos (${photos.length})",
                ),

              ),

              Expanded(

                child: photos.isEmpty

                    ? const Center(
                        child: Text(
                          "No Photos Added",
                        ),
                      )

                    : GridView.builder(

                        padding:
                            const EdgeInsets.all(15),

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(

                          crossAxisCount: 3,

                          crossAxisSpacing: 12,

                          mainAxisSpacing: 12,

                        ),

                        itemCount: photos.length,

                        itemBuilder: (_, index) {

                          final photo = photos[index];

                          return GestureDetector(

                            onTap: () {

                              showDialog(

                                context: context,

                                builder: (_) {

                                  return Dialog(

                                    child: InteractiveViewer(

                                      child: Image.file(

                                        File(photo.photoPath),

                                        fit: BoxFit.contain,

                                      ),

                                    ),

                                  );

                                },

                              );

                            },

                            child: Image.file(

                              File(photo.photoPath),

                              fit: BoxFit.cover,

                            ),

                          );

                        },

                      ),

              ),

              Padding(

                padding: const EdgeInsets.all(12),

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.pop(context);

                  },

                  child: const Text("CLOSE"),

                ),

              ),

            ],

          ),

        ),

      );

    },

  );

}

void _showDocuments() {

  showDialog(

    context: context,

    builder: (_) {

      return Dialog(

        child: SizedBox(

          width: 750,

          height: 550,

          child: Column(

            children: [

              AppBar(

                automaticallyImplyLeading: false,

                title: Text(
                  "Uploaded Documents (${documents.length})",
                ),

              ),

              Expanded(

                child: documents.isEmpty

                    ? const Center(
                        child: Text(
                          "No Documents Uploaded",
                        ),
                      )

                    : ListView.builder(

                        itemCount: documents.length,

                        itemBuilder: (_, index) {

                          final doc =
                              documents[index];

                          return Card(

                            margin:
                                const EdgeInsets.all(8),

                            child: ListTile(

                              leading: const Icon(
                                Icons.description,
                                color: Colors.blue,
                              ),

                              title: Text(
                                doc.documentTypeName,
                              ),

                              subtitle: Text(
                                doc.remarks.isEmpty
                                    ? "-"
                                    : doc.remarks,
                              ),

                              trailing:
                                  ElevatedButton.icon(

                                icon: const Icon(
                                  Icons.visibility,
                                ),

                                label: const Text(
                                  "VIEW",
                                ),

                                onPressed: () async {

                                  await OpenFilex.open(
                                    doc.filePath,
                                  );

                                },

                              ),

                            ),

                          );

                        },

                      ),

              ),

              Padding(

                padding:
                    const EdgeInsets.all(12),

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.pop(context);

                  },

                  child: const Text(
                    "CLOSE",
                  ),

                ),

              ),

            ],

          ),

        ),

      );

    },

  );

}

bool validateDeferredVerification() {

  if (deferredCorrect == null) {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Please verify deferred reason.",
        ),

      ),

    );

    return false;

  }

  if (deferredCorrect == false &&
      (deferredReason == null ||
          deferredReason!.isEmpty)) {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Please select verification reason.",
        ),

      ),

    );

    return false;

  }

  return true;

}

bool validateApplicationVerification() {
  bool validateItem({
    required String? status,
    required String title,
    required String? reason,
  }) {
       if (status == null || status.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please verify $title.",
          ),
        ),
      );

      return false;
    }

    if (status == "Re-inspect" &&
        (reason == null || reason.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a re-inspection reason for $title.",
          ),
        ),
      );

      return false;
    }

    return true;
  }

  if (!validateItem(
    status: applicationTypeStatus,
    title: "Application Type",
    reason: applicationTypeReason,
  )) {
    return false;
  }

  if (isGovernmentCategory &&
      !validateItem(
        status: governmentAgencyStatus,
        title: "Government Agency",
        reason: governmentAgencyReason,
      )) {
    return false;
  }

  if (isPrivateCategory &&
      !validateItem(
        status: urbanRuralStatus,
        title: "Urban / Rural",
        reason: urbanRuralReason,
      )) {
    return false;
  }

  if (showsAdditionalDetails &&
      !validateItem(
        status: whyRemovingStatus,
        title: "Why Removing",
        reason: whyRemovingReason,
      )) {
    return false;
  }

  if (showsAdditionalDetails &&
      !validateItem(
        status: purposeStatus,
        title: "Purpose",
        reason: purposeReason,
      )) {
    return false;
  }

  if (showsAdditionalDetails &&
      !validateItem(
        status: structureTypeStatus,
        title: "Structure Type",
        reason: structureTypeReason,
      )) {
    return false;
  }

  if (showsNameOfWork &&
      !validateItem(
        status: workNameStatus,
        title: "Name of Work",
        reason: workNameReason,
      )) {
    return false;
  }

  if (!validateItem(
    status: gpsStatus,
    title: "GPS",
    reason: gpsReason,
  )) {
    return false;
  }

  if (!validateItem(
    status: photosStatus,
    title: "Inspection Photos",
    reason: photosReason,
  )) {
    return false;
  }

  if (!validateItem(
    status: documentsStatus,
    title: "Uploaded Documents",
    reason: documentsReason,
  )) {
    return false;
  }

  return true;
}

bool validateOverallRemarkVerification() {
  if (overallRemarkStatus == null ||
      overallRemarkStatus!.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please verify Inspecting Officer's Overall Remarks.",
        ),
      ),
    );

    return false;
  }

  if (overallRemarkStatus == "Re-inspect" &&
      (overallRemarkReason == null ||
          overallRemarkReason!.trim().isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please select a re-inspection reason for Overall Remarks.",
        ),
      ),
    );

    return false;
  }

  if (overallRemarkStatus == "Modify" &&
      selectedOverallRemarkId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please select the corrected Overall Remark.",
        ),
      ),
    );

    return false;
  }

  return true;
}


bool hasApplicationReInspection() {
  return applicationTypeStatus == "Re-inspect" ||
      (isGovernmentCategory &&
          governmentAgencyStatus == "Re-inspect") ||
      (isPrivateCategory &&
          urbanRuralStatus == "Re-inspect") ||
      (showsAdditionalDetails &&
          whyRemovingStatus == "Re-inspect") ||
      (showsAdditionalDetails &&
          purposeStatus == "Re-inspect") ||
      (showsAdditionalDetails &&
          structureTypeStatus == "Re-inspect") ||
      (showsNameOfWork &&
          workNameStatus == "Re-inspect") ||
      (!isTreeCount &&
          overallRemarkStatus == "Re-inspect") ||
      gpsStatus == "Re-inspect" ||
      photosStatus == "Re-inspect" ||
      documentsStatus == "Re-inspect";
}

bool hasAnyReInspection() {

  if (hasApplicationReInspection()) {
  return true;
}

  if (isTreeCount) {

    if (treeCountVerificationKey.currentState
            ?.verification ==
        "Re-inspect") {
      return true;
    }

  } else {

    if (treeVerificationKey.currentState
            ?.verificationStatus
            .values
            .contains("Re-inspect") ==
        true) {
      return true;
    }

  }

  if (needsRevenueOpinion) {

    if (revenueOpinionVerificationKey
            .currentState
            ?.verification ==
        "Re-inspect") {
      return true;
    }

  }

  if (needsMahazar) {

    if (mahazarVerificationKey
            .currentState
            ?.verification ==
        "Re-inspect") {
      return true;
    }

  }

  return false;

}

void _showGeneratedDocuments() {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        child: SizedBox(
          width: 750,
          height: 550,
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text(
                  "Generated Documents (${generatedDocuments.length})",
                ),
              ),

              Expanded(
                child: generatedDocuments.isEmpty
                    ? const Center(
                        child: Text(
                          "No Generated Documents",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: generatedDocuments.length,
                        itemBuilder: (_, index) {
                          final file =
                              generatedDocuments[index];

                          final fileName =
                              file.path.split(
                            Platform.pathSeparator,
                          ).last;

                          String documentName = fileName;

                          if (fileName.contains(
                              '_DRFO_DEFERRED')) {
                            documentName =
                                "DRFO Deferred Letter";
                          } else if (fileName.contains(
                              '_DRFO_RECOMMENDED')) {
                            documentName =
                                "DRFO Recommended Letter";
                          } else if (fileName.contains(
                              '_MAHAZAR')) {
                            documentName = "Mahazar";
                          } else if (fileName.contains(
                              '_TREE_ENUMERATION')) {
                            documentName =
                                "Tree Enumeration List";
                          }

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 32,
                              ),
                              title: Text(
                                documentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(fileName),
                              trailing:
                                  ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.visibility,
                                ),
                                label: const Text("VIEW"),
                                onPressed: () async {
                                  await OpenFilex.open(
                                    file.path,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("CLOSE"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOverallRemarkVerificationPage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerificationCard(
          title: "Inspecting Officer's Overall Remarks",
          value: overallRemarkDisplay.isEmpty
              ? "Not entered"
              : overallRemarkDisplay,
          threeOptions: true,
          verificationStatus:
              overallRemarkStatus,
          selectedReason:
              overallRemarkReason,
          reasons: applicationTypeReasons,
          onStatusChanged: (value) async {
            await _changeVerificationStatus(
              newStatus: value,
              setStatus: (status) {
                overallRemarkStatus = status;
              },
              setLegacyValue: (correct) {
                overallRemarkCorrect = correct;
              },
              clearReason: () {
                overallRemarkReason = null;
              },
            );
          },
          onReasonChanged: (value) async {
            setState(() {
              overallRemarkReason = value;
            });

            await _saveVerification();
          },
          modifyField:
              DropdownButtonFormField<int>(
            value: overallRemarkList.any(
              (item) =>
                  item["id"] ==
                  selectedOverallRemarkId,
            )
                ? selectedOverallRemarkId
                : null,
            decoration: const InputDecoration(
              labelText:
                  "Correct Overall Remark",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items:
                overallRemarkList.map((item) {
              return DropdownMenuItem<int>(
                value: item["id"] as int,
                child: Text(
                  item["value"]?.toString() ??
                      "",
                ),
              );
            }).toList(),
            onChanged: (selectedId) async {
              if (selectedId == null) return;

              final selectedItem =
                  overallRemarkList.firstWhere(
                (item) =>
                    item["id"] == selectedId,
              );

              final selectedText =
                  selectedItem["value"]
                          ?.toString()
                          .trim() ??
                      "";

              setState(() {
                selectedOverallRemarkId =
                    selectedId;
                overallRemarkDisplay =
                    selectedText;

                widget.application
                        .overallRemarkId =
                    selectedId;
                widget.application
                        .overallRemarks =
                    selectedText;
              });

              // Save the corrected application immediately.
              // Later summaries and documents use this value.
              await _saveCorrectedApplication();
              await _saveVerification();
            },
          ),
        ),
      ],
    ),
  );
}


@override
Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        centerTitle: true,

        title: const Text(

          "DRFO Verification",

        ),

      ),

      body: Column(

        children: [

          Container(

  width: double.infinity,

  color: Colors.green.shade50,

  padding: const EdgeInsets.all(12),

  child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      Text(

        widget.application.officeNumber,

        style: const TextStyle(

          fontWeight: FontWeight.bold,

          fontSize: 18,

        ),

      ),

      const SizedBox(height: 5),

      Text(
        "Applicant : ${widget.application.applicantName}",
      ),

      Text(
        "Application Type : $applicationTypeDisplay",
      ),

      Text(
        "Section : ${widget.application.section}",
      ),

      Text(
        "Beat : ${widget.application.beat}",
      ),

    ],

  ),

),

if (generatedDocuments.isNotEmpty)
  Padding(
    padding: const EdgeInsets.fromLTRB(
      12,
      10,
      12,
      0,
    ),
    child: Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(
          Icons.folder_special,
          color: Colors.green,
          size: 32,
        ),

        title: const Text(
          "Generated Documents",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),

        subtitle: Text(
          "${generatedDocuments.length} document(s) available",
        ),

        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.visibility),
          label: const Text("VIEW"),
          onPressed: _showGeneratedDocuments,
        ),
      ),
    ),
  ),

          Expanded(

            child: PageView(

              controller: pageController,

              physics:
                  const NeverScrollableScrollPhysics(),

              onPageChanged: (index) {

                setState(() {

                  currentPage = index;

                });

              },

              children: [

                InspectionSummaryStep(

  application: widget.application,

  showNavigationButtons: false,

  onBack: () {},

  onNext: () {},

),

if (isDeferred)

SingleChildScrollView(

  padding: const EdgeInsets.all(16),

  child: Column(

    children: [

      Card(

        child: Padding(

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(

                "Deferred Reasons",

                style: TextStyle(

                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const Divider(),

              if (widget.application.inspectionDecision == "DEFERRED")

                if (selectedDeferredReasons.isEmpty)

  const Text(
    "No deferred reasons found.",
  )

else

  Column(

    crossAxisAlignment:
        CrossAxisAlignment.start,

    children:

        selectedDeferredReasons.map((reason) {

      return Padding(

        padding:
            const EdgeInsets.only(bottom: 8),

        child: Row(

          children: [

            const Icon(

              Icons.check_circle,

              color: Colors.green,

              size: 18,

            ),

            const SizedBox(width: 8),

            Expanded(

              child: Text(

                reason["reasonName"],

                style: const TextStyle(
                  fontSize: 16,
                ),

              ),

            ),

          ],

        ),

      );

    }).toList(),

  ),

            ],

          ),

        ),

      ),

      const SizedBox(height: 15),

      VerificationCard(

        title: "Deferred Verification",

        value: "Verify the deferred inspection.",

        verification: deferredCorrect,

        selectedReason: deferredReason,

        reasons: deferredReasons,

        onReasonChanged: (value) async {

          setState(() {

            deferredReason = value;

          });

          await _saveVerification();

        },

        onChanged: (value) {

          setState(() {

            deferredCorrect = value;

          });

          _saveVerification();

        },

      ),

    ],

  ),

),

                               if (!isDeferred)

SingleChildScrollView(

  child:
  Column(
  crossAxisAlignment:
      CrossAxisAlignment.stretch,
  children: [

VerificationCard(
  title: "Application Type",
  value: applicationTypeDisplay.isEmpty
      ? "Not entered"
      : applicationTypeDisplay,
  threeOptions: true,
  verificationStatus: applicationTypeStatus,
  selectedReason: applicationTypeReason,
  reasons: applicationTypeReasons,
  onStatusChanged: (value) async {
    await _changeVerificationStatus(
      newStatus: value,
      setStatus: (status) {
        applicationTypeStatus = status;
      },
      setLegacyValue: (correct) {
        applicationTypeCorrect = correct;
      },
      clearReason: () {
        applicationTypeReason = null;
      },
    );
  },
  onReasonChanged: (value) async {
    setState(() {
      applicationTypeReason = value;
    });

    await _saveVerification();
  },
  modifyField: DropdownButtonFormField<int>(
    value: applicationTypeList.any((item) {
      final code = item["shortCode"]
              ?.toString()
              .trim()
              .toUpperCase() ??
          "";

      final name = item["applicationType"]
              ?.toString()
              .trim()
              .toUpperCase() ??
          "";

      final currentType = widget
          .application.applicationType
          .trim()
          .toUpperCase();

      return code == currentType ||
          name == currentType;
    })
        ? applicationTypeList
            .firstWhere((item) {
              final code = item["shortCode"]
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "";

              final name = item["applicationType"]
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "";

              final currentType = widget
                  .application.applicationType
                  .trim()
                  .toUpperCase();

              return code == currentType ||
                  name == currentType;
            })["id"] as int
        : null,
    decoration: const InputDecoration(
      labelText: "Correct Application Type",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: applicationTypeList.map((item) {
      return DropdownMenuItem<int>(
        value: item["id"] as int,
        child: Text(
          item["applicationType"]?.toString() ??
              "",
        ),
      );
    }).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      final selectedItem =
          applicationTypeList.firstWhere(
        (item) => item["id"] == selectedId,
      );

      widget.application.applicationType =
          selectedItem["shortCode"]?.toString() ??
              "";

      widget.application.verifiedApplicationType =
          selectedItem["applicationType"]
                  ?.toString() ??
              "";

      final permission =
          await ApplicationTypePermissionMappingRepository()
              .getPermissionForApplicationType(
        selectedId,
      );

      widget.application.permissionTypeId =
          permission?["id"] as int?;

      widget.application.permissionType =
          permission?["permissionType"]
                  ?.toString() ??
              "";

      await _saveCorrectedApplication();
    },
  ),
),

if (isGovernmentCategory) ...[
  const SizedBox(height: 8),

   VerificationCard(
    title: "Government Agency",
    value: governmentAgencyDisplay.isEmpty
        ? "Not entered"
        : governmentAgencyDisplay,
    threeOptions: true,
    verificationStatus: governmentAgencyStatus,
    selectedReason: governmentAgencyReason,
    reasons: applicationTypeReasons,
    onStatusChanged: (value) async {
      await _changeVerificationStatus(
        newStatus: value,
        setStatus: (status) {
          governmentAgencyStatus = status;
        },
        setLegacyValue: (correct) {
          governmentAgencyCorrect = correct;
        },
        clearReason: () {
          governmentAgencyReason = null;
        },
      );
    },
    onReasonChanged: (value) async {
      setState(() {
        governmentAgencyReason = value;
      });

      await _saveVerification();
    },
    modifyField: DropdownButtonFormField<int>(
      value: governmentAgencyList.any(
        (item) =>
            item["id"] ==
            widget.application.governmentAgencyId,
      )
          ? widget.application.governmentAgencyId
          : null,
      decoration: const InputDecoration(
        labelText: "Correct Government Agency",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: governmentAgencyList.map((item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]?.toString() ?? "",
          ),
        );
      }).toList(),
      onChanged: (selectedId) async {
        if (selectedId == null) return;

        widget.application.governmentAgencyId =
            selectedId;

        await _saveCorrectedApplication();
      },
    ),
  ),
],

if (isPrivateCategory) ...[
  const SizedBox(height: 8),

  VerificationCard(
    title: "Urban / Rural",
    value: urbanRuralDisplay.isEmpty
        ? "Not entered"
        : urbanRuralDisplay,
    threeOptions: true,
    verificationStatus: urbanRuralStatus,
    selectedReason: urbanRuralReason,
    reasons: applicationTypeReasons,
    onStatusChanged: (value) async {
      await _changeVerificationStatus(
        newStatus: value,
        setStatus: (status) {
          urbanRuralStatus = status;
        },
        setLegacyValue: (correct) {
          urbanRuralCorrect = correct;
        },
        clearReason: () {
          urbanRuralReason = null;
        },
      );
    },
    onReasonChanged: (value) async {
      setState(() {
        urbanRuralReason = value;
      });

      await _saveVerification();
    },
    modifyField: DropdownButtonFormField<int>(
      value: urbanRuralList.any(
        (item) =>
            item["id"] ==
            widget.application.urbanRuralId,
      )
          ? widget.application.urbanRuralId
          : null,
      decoration: const InputDecoration(
        labelText: "Correct Urban / Rural",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: urbanRuralList.map((item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]?.toString() ?? "",
          ),
        );
      }).toList(),
      onChanged: (selectedId) async {
        if (selectedId == null) return;

        widget.application.urbanRuralId =
            selectedId;

        await _saveCorrectedApplication();
      },
    ),
  ),
],

if (showsAdditionalDetails) ...[
  const SizedBox(height: 8),

  VerificationCard(
    title: "Why Removing",
    value: whyRemovingDisplay.isEmpty
        ? "Not entered"
        : whyRemovingDisplay,
    threeOptions: true,
    verificationStatus: whyRemovingStatus,
    selectedReason: whyRemovingReason,
    reasons: applicationTypeReasons,
    onStatusChanged: (value) async {
      await _changeVerificationStatus(
        newStatus: value,
        setStatus: (status) {
          whyRemovingStatus = status;
        },
        setLegacyValue: (correct) {
          whyRemovingCorrect = correct;
        },
        clearReason: () {
          whyRemovingReason = null;
        },
      );
    },
    onReasonChanged: (value) async {
      setState(() {
        whyRemovingReason = value;
      });

      await _saveVerification();
    },
    modifyField: DropdownButtonFormField<int>(
      value: whyRemovingList.any(
        (item) =>
            item["id"] ==
            widget.application.whyRemovingId,
      )
          ? widget.application.whyRemovingId
          : null,
      decoration: const InputDecoration(
        labelText: "Correct Why Removing",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: whyRemovingList.map((item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]?.toString() ?? "",
          ),
        );
      }).toList(),
      onChanged: (selectedId) async {
        if (selectedId == null) return;

        widget.application.whyRemovingId =
            selectedId;

        _filterPurposeList();

        final currentPurposeIsValid =
            purposeList.any(
          (item) =>
              item["id"] ==
              widget.application.purposeId,
        );

        if (!currentPurposeIsValid) {
          widget.application.purposeId = null;
          widget.application.purpose = "";
          purposeDisplay = "";
          purposeStatus = null;
          purposeCorrect = null;
          purposeReason = null;
        }

        if (!isDevelopmentWork) {
          widget.application.workName = "";
          workNameController.clear();
          workNameStatus = null;
          workNameCorrect = null;
          workNameReason = null;
        }

        await _saveCorrectedApplication();
        await _saveVerification();
      },
    ),
  ),

  const SizedBox(height: 8),

  VerificationCard(
    title: "Purpose",
    value: purposeDisplay.isEmpty
        ? "Not entered"
        : purposeDisplay,
    threeOptions: true,
    verificationStatus: purposeStatus,
    selectedReason: purposeReason,
    reasons: applicationTypeReasons,
    onStatusChanged: (value) async {
      await _changeVerificationStatus(
        newStatus: value,
        setStatus: (status) {
          purposeStatus = status;
        },
        setLegacyValue: (correct) {
          purposeCorrect = correct;
        },
        clearReason: () {
          purposeReason = null;
        },
      );
    },
    onReasonChanged: (value) async {
      setState(() {
        purposeReason = value;
      });

      await _saveVerification();
    },
    modifyField: DropdownButtonFormField<int>(
      value: purposeList.any(
        (item) =>
            item["id"] ==
            widget.application.purposeId,
      )
          ? widget.application.purposeId
          : null,
      decoration: const InputDecoration(
        labelText: "Correct Purpose",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: purposeList.map((item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]?.toString() ?? "",
          ),
        );
      }).toList(),
      onChanged: (selectedId) async {
        if (selectedId == null) return;

        final selectedItem =
            purposeList.firstWhere(
          (item) => item["id"] == selectedId,
        );

        widget.application.purposeId =
            selectedId;

        // Retain the English text for compatibility
        // with existing application and document code.
        widget.application.purpose =
            selectedItem["value"]?.toString() ??
                "";

        await _saveCorrectedApplication();
      },
    ),
  ),

  const SizedBox(height: 8),

   VerificationCard(
    title: "Structure Type",
    value: structureTypeDisplay.isEmpty
        ? "Not entered"
        : structureTypeDisplay,
    threeOptions: true,
    verificationStatus: structureTypeStatus,
    selectedReason: structureTypeReason,
    reasons: applicationTypeReasons,
    onStatusChanged: (value) async {
      await _changeVerificationStatus(
        newStatus: value,
        setStatus: (status) {
          structureTypeStatus = status;
        },
        setLegacyValue: (correct) {
          structureTypeCorrect = correct;
        },
        clearReason: () {
          structureTypeReason = null;
        },
      );
    },
    onReasonChanged: (value) async {
      setState(() {
        structureTypeReason = value;
      });

      await _saveVerification();
    },
    modifyField: DropdownButtonFormField<int>(
      value: structureTypeList.any(
        (item) =>
            item["id"] ==
            widget.application.structureTypeId,
      )
          ? widget.application.structureTypeId
          : null,
      decoration: const InputDecoration(
        labelText: "Correct Structure Type",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: structureTypeList.map((item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]?.toString() ?? "",
          ),
        );
      }).toList(),
      onChanged: (selectedId) async {
        if (selectedId == null) return;

        widget.application.structureTypeId =
            selectedId;

        await _saveCorrectedApplication();
      },
    ),
  ),

  const SizedBox(height: 8),

   if (showsNameOfWork) 
   VerificationCard(
    title: "Name of Work",
    value: widget.application.workName
            .trim()
            .isEmpty
        ? "Not entered"
        : widget.application.workName,
    threeOptions: true,
    verificationStatus: workNameStatus,
    selectedReason: workNameReason,
    reasons: applicationTypeReasons,
    onStatusChanged: (value) async {
      await _changeVerificationStatus(
        newStatus: value,
        setStatus: (status) {
          workNameStatus = status;
        },
        setLegacyValue: (correct) {
          workNameCorrect = correct;
        },
        clearReason: () {
          workNameReason = null;
        },
      );
    },
    onReasonChanged: (value) async {
      setState(() {
        workNameReason = value;
      });

      await _saveVerification();
    },
    modifyField: TextFormField(
      controller: workNameController,
      decoration: InputDecoration(
        labelText: "Correct Name of Work",
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          tooltip: "Save corrected name",
          icon: const Icon(Icons.save),
          onPressed: () async {
            final correctedName =
                workNameController.text.trim();

            if (correctedName.isEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    "Please enter Name of Work.",
                  ),
                ),
              );
              return;
            }

            widget.application.workName =
                correctedName;

            await _saveCorrectedApplication();
          },
        ),
      ),
      onFieldSubmitted: (value) async {
        final correctedName = value.trim();

        if (correctedName.isEmpty) return;

        widget.application.workName =
            correctedName;

        await _saveCorrectedApplication();
      },
    ),
  ),
],

const SizedBox(height: 8),

VerificationCard(
  title: "GPS",
  value: widget.application.gpsCoordinates
          .trim()
          .isEmpty
      ? "GPS not entered"
      : widget.application.gpsCoordinates,
  threeOptions: true,
  verificationStatus: gpsStatus,
  selectedReason: gpsReason,
  reasons: gpsReasons,
  onStatusChanged: (value) async {
    await _changeVerificationStatus(
      newStatus: value,
      setStatus: (status) {
        gpsStatus = status;
      },
      setLegacyValue: (correct) {
        gpsCorrect = correct;
      },
      clearReason: () {
        gpsReason = null;
      },
    );
  },
  onReasonChanged: (value) async {
    setState(() {
      gpsReason = value;
    });

    await _saveVerification();
  },
  modifyField: TextFormField(
    controller: gpsController,
    decoration: InputDecoration(
      labelText: "Correct GPS Coordinates",
      hintText: "Latitude, Longitude",
      border: const OutlineInputBorder(),
      isDense: true,
      suffixIcon: IconButton(
        tooltip: "Save corrected GPS",
        icon: const Icon(Icons.save),
        onPressed: () async {
          final correctedGps =
              gpsController.text.trim();

          if (correctedGps.isEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Please enter GPS coordinates.",
                ),
              ),
            );
            return;
          }

          widget.application.gpsCoordinates =
              correctedGps;

          await _saveCorrectedApplication();
        },
      ),
    ),
    onFieldSubmitted: (value) async {
      final correctedGps = value.trim();

      if (correctedGps.isEmpty) return;

      widget.application.gpsCoordinates =
          correctedGps;

      await _saveCorrectedApplication();
    },
  ),
),

const SizedBox(height: 8),

VerificationCard(
  title: "Inspection Photos",
  value: "${photos.length} Photo(s)",
  threeOptions: true,
  verificationStatus: photosStatus,
  selectedReason: photosReason,
  reasons: photoReasons,
  onStatusChanged: (value) async {
    await _changeVerificationStatus(
      newStatus: value,
      setStatus: (status) {
        photosStatus = status;
      },
      setLegacyValue: (correct) {
        photosCorrect = correct;
      },
      clearReason: () {
        photosReason = null;
      },
    );
  },
  onReasonChanged: (value) async {
    setState(() {
      photosReason = value;
    });

    await _saveVerification();
  },
  onView: _showPhotos,
  modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text("Edit Inspection Photos"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (routeContext) => PhotoStep(
              application: widget.application,
              onBack: () {
                Navigator.pop(routeContext);
              },
              onNext: () {
                Navigator.pop(routeContext);
              },
            ),
          ),
        );

        photos = await photoRepository.getPhotos(
          widget.application.id!,
        );

        if (mounted) {
          setState(() {});
        }
      },
    ),
  ),
),

const SizedBox(height: 8),

VerificationCard(
  title: "Uploaded Documents",
  value: "${documents.length} Document(s)",
  threeOptions: true,
  verificationStatus: documentsStatus,
  selectedReason: documentsReason,
  reasons: documentReasons,
  onStatusChanged: (value) async {
    await _changeVerificationStatus(
      newStatus: value,
      setStatus: (status) {
        documentsStatus = status;
      },
      setLegacyValue: (correct) {
        documentsCorrect = correct;
      },
      clearReason: () {
        documentsReason = null;
      },
    );
  },
  onReasonChanged: (value) async {
    setState(() {
      documentsReason = value;
    });

    await _saveVerification();
  },
  onView: _showDocuments,
  modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text("Edit Uploaded Documents"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (routeContext) => DocumentStep(
              application: widget.application,
              onBack: () {
                Navigator.pop(routeContext);
              },
              onNext: () {
                Navigator.pop(routeContext);
              },
            ),
          ),
        );

        documents =
            await documentRepository.getDocuments(
          widget.application.id!,
        );

        if (mounted) {
          setState(() {});
        }
      },
    ),
  ),
),

        ],
  ),

),

             if (!isDeferred)
  (isTreeCount
      ? TreeCountVerificationScreen(
          key: treeCountVerificationKey,
          application: widget.application,
        )
      : TreeVerificationScreen(
          key: treeVerificationKey,
          application: widget.application,
        )),

if (!isDeferred && needsRevenueOpinion)
  RevenueOpinionVerificationScreen(
    key: revenueOpinionVerificationKey,
    application: widget.application,
  ),

if (!isDeferred && needsMahazar)
  MahazarVerificationScreen(
    key: mahazarVerificationKey,
    application: widget.application,
  ),

if (!isDeferred &&
    needsOverallRemarkVerification)
  _buildOverallRemarkVerificationPage(),

if (!isDeferred && !hasAnyReInspection())
  GenerateDocumentsScreen(
    application: widget.application,
    onBack: () {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    },
    onSaveDraft: () async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Draft Saved Successfully.",
          ),
        ),
      );
    },
    onForward: () {},
  ),
                

              ],

            ),

          ),

        Container(

  padding: const EdgeInsets.all(15),

  child: Row(

    children: [

      if (currentPage > 0)

        Expanded(

          child: OutlinedButton(

            style: OutlinedButton.styleFrom(

              minimumSize: const Size.fromHeight(55),

              shape: RoundedRectangleBorder(

                borderRadius:
                    BorderRadius.circular(18),

              ),

            ),

            onPressed: () {

              if (currentPage == 3 && isDeferred) {

                pageController.jumpToPage(1);

                return;

              }

              pageController.previousPage(

                duration:
                    const Duration(milliseconds: 300),

                curve: Curves.easeInOut,

              );

            },

            child: const Text(

              "PREVIOUS",

              textAlign: TextAlign.center,

              style: TextStyle(

                fontSize: 15,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

        ),

      if (currentPage > 0)

        const SizedBox(width: 15),

      if (isDeferred &&
          currentPage == 1 &&
          deferredCorrect == false)

        Expanded(

          child: ElevatedButton(

            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.orange,

              minimumSize:
                  const Size.fromHeight(55),

              shape: RoundedRectangleBorder(

                borderRadius:
                    BorderRadius.circular(18),

              ),

            ),

            onPressed: () async {

              if (!validateDeferredVerification()) {

                return;

              }

              await workflowService.returnToBFO(

                application: widget.application,

                actionBy:
                    SessionService.instance.name,

              );

              if (!mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(

                const SnackBar(

                  content: Text(

                    "Returned for Re-inspection.",

                  ),

                ),

              );

              Navigator.pop(context, true);

            },

            child: Text(

              widget.application
                          .assignedBFOId ==
                      0

                  ? "RETURN TO SELF INSPECT"

                  : "RETURN TO BFO",

              textAlign: TextAlign.center,

              style: const TextStyle(

                fontSize: 15,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

        )

      else if (
        currentPage <
            (documentsPageIndex -
                (hasAnyReInspection() ? 1 : 0))
      )

        Expanded(

          child: ElevatedButton(

            style: ElevatedButton.styleFrom(

              minimumSize:
                  const Size.fromHeight(55),

              shape: RoundedRectangleBorder(

                borderRadius:
                    BorderRadius.circular(18),

              ),

            ),

            onPressed: () async {

                            //--------------------------------------------------
              // Deferred Verification
              //--------------------------------------------------

              if (isDeferred && currentPage == 1) {
  if (!validateDeferredVerification()) {
    return;
  }

  if (deferredCorrect == true) {
  // ==========================================================
  // GENERATE DRFO DEFERRED LETTER
  // ==========================================================

  await documentService.generateDocumentsForApplication(
    widget.application,
  );

  // ==========================================================
  // FORWARD APPLICATION TO RFO
  // ==========================================================

  await workflowService.forwardToRFO(
    application: widget.application,
    actionBy: SessionService.instance.name,
  );

  if (!mounted) return;

  // ==========================================================
  // OPEN FORWARDED APPLICATION SCREEN
  // ==========================================================

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DRFOForwardedApplicationScreen(
        application: widget.application,
      ),
    ),
  );
}

  return;
}

              //--------------------------------------------------
              // Application Verification
              //--------------------------------------------------

              if (!isDeferred && currentPage == 1) {

                if (!validateApplicationVerification()) {
                  return;
                }

              }

              //--------------------------------------------------
              // Tree Verification
              //--------------------------------------------------

             if (currentPage == 2) {

  final applicationReinspect =
    hasApplicationReInspection();

  bool verificationReinspect = false;

  if (isTreeCount) {

    final valid =
        treeCountVerificationKey.currentState
                ?.validateVerification() ??
            false;

    if (!valid) return;

    verificationReinspect =
        treeCountVerificationKey.currentState!
                .verification ==
            "Re-inspect";

  } else {

    final valid =
        treeVerificationKey.currentState
                ?.validateVerification() ??
            false;

    if (!valid) return;

    verificationReinspect =
        treeVerificationKey.currentState!
            .verificationStatus
            .values
            .contains("Re-inspect");

  }

 await loadTreeRequirements();
 if (!mounted) return;
 setState(() {});
 }

//==================================================
// Revenue Opinion Verification
//==================================================

if (currentPage == 3 && needsRevenueOpinion) {

  final valid =
      revenueOpinionVerificationKey.currentState
              ?.validateVerification() ??
          false;

  if (!valid) return;

  final reInspect =
      revenueOpinionVerificationKey.currentState!
              .verification ==
          "Re-inspect";

  if (!mounted) return;

}

//==================================================
// Mahazar Verification
//==================================================

if (

currentPage ==

(needsRevenueOpinion ? 4 : 3)

&&

needsMahazar

) {

  final valid =
      mahazarVerificationKey.currentState
              ?.validateVerification() ??
          false;

  if (!valid) return;

  final reInspect =
      mahazarVerificationKey.currentState!
              .verification ==
          "Re-inspect";

 if (!mounted) return;

}

//==================================================
// Inspecting Officer Overall Remarks Verification
//==================================================

if (!isDeferred &&
    needsOverallRemarkVerification &&
    currentPage == overallRemarkPageIndex) {
  if (!validateOverallRemarkVerification()) {
    return;
  }

  await _saveVerification();

  if (!mounted) return;
}


// Move to next verification page
  pageController.nextPage(

    duration: const Duration(milliseconds: 300),

    curve: Curves.easeInOut,

  );

  return;

            },

            child: const Text(

              "NEXT",

              textAlign: TextAlign.center,

              style: TextStyle(

                fontSize: 15,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

        )

      else

        Expanded(

          child: Row(

            children: [

              Expanded(

                child: OutlinedButton(

                  style: OutlinedButton.styleFrom(

                    minimumSize:
                        const Size.fromHeight(55),

                    shape: RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(18),

                    ),

                  ),

                  onPressed: () async {

  await _saveVerification();

  await ApplicationRepository().touchForSync(
    widget.application.id!,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

    const SnackBar(

      content: Text(
        "Draft Saved Successfully.",
      ),

    ),

  );

},

                  child: const Text(

                    "SAVE DRAFT",

                    textAlign: TextAlign.center,

                    style: TextStyle(

                      fontSize: 15,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ),

              ),

              const SizedBox(width: 15),

              Expanded(

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    minimumSize:
                        const Size.fromHeight(55),

                    shape: RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(18),

                    ),

                  ),

                  onPressed: () async {

final applicationReinspect =
    hasApplicationReInspection();

bool treeReinspect = false;

if (isTreeCount) {

  treeReinspect =
      treeCountVerificationKey.currentState
              ?.verification ==
          "Re-inspect";

} else {

  treeReinspect =
      treeVerificationKey.currentState
              ?.verificationStatus
              .values
              .contains("Re-inspect") ??
          false;

}

bool revenueReinspect = false;

if (needsRevenueOpinion) {

  revenueReinspect =
      revenueOpinionVerificationKey
              .currentState
              ?.verification ==
          "Re-inspect";

}

bool mahazarReinspect = false;

if (needsMahazar) {

  mahazarReinspect =
      mahazarVerificationKey
              .currentState
              ?.verification ==
          "Re-inspect";

}

bool hasReinspect =

    applicationReinspect ||

    treeReinspect ||

    revenueReinspect ||

    mahazarReinspect;

                    if (hasReinspect) {

  if (widget.application.assignedBFOId == 0) {

    await workflowService.returnToSelfInspection(

      application: widget.application,

      actionBy: SessionService.instance.name,

    );

  } else {

    await workflowService.returnToBFO(

      application: widget.application,

      actionBy: SessionService.instance.name,

    );

  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

    const SnackBar(

      content: Text(

        "Application Returned for Re-inspection.",

      ),

    ),

  );

 Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) =>
        DRFOForwardedApplicationScreen(
      application: widget.application,
    ),
  ),
);

  return;

}

if (!hasReinspect) {

  // ==========================================================
  // AUTOMATIC DOCUMENT GENERATION
  // ==========================================================
  //
  // NON-RTC:
  //
  // DEFERRED:
  //     DRFO Deferred Letter ONLY
  //
  // COMPLETED:
  //     DRFO Recommended Letter
  //     + Mahazar if available
  //     + Tree Enumeration if available
  //
  // RTC:
  //     Not handled by the non-RTC document bundle.
  // ==========================================================

  try {

// ==========================================================
// MARK DRFO INSPECTION AS COMPLETED
// ==========================================================

if (widget.application.inspectionDecision
        .trim()
        .toUpperCase() !=
    "DEFERRED") {

  if (widget.application.drfoInspectionDate.isEmpty) {
    widget.application.drfoInspectionDate =
        DateTime.now().toIso8601String();
  }
}

// ==========================================================
// SAVE DRFO INSPECTION DATA
// ==========================================================

await ApplicationRepository()
    .updateApplication(
  widget.application,
);

// ==========================================================
// GENERATE DOCUMENTS
// ==========================================================

await documentService
    .generateDocumentsForApplication(
  widget.application,
);

// ==========================================================
// FORWARD TO RFO
// ==========================================================

await workflowService.forwardToRFO(
  application: widget.application,
  actionBy: SessionService.instance.name,
);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Documents generated and application forwarded to RFO.",
        ),
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Document generation failed. Application was not forwarded to RFO.\n$e",
        ),
      ),
    );

  }
}

                  },

child: Text(

  hasAnyReInspection()
      ? (widget.application.assignedBFOId == 0
          ? "RETURN TO SELF INSPECT"
          : "RETURN TO BFO")
      : "FORWARD TO RFO",

  textAlign: TextAlign.center,

  style: const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  ),

),

),

                                ),

            ],

          ),
                  ),
          ],

        ),

      ),
      ],
    ),
    );

  }

}