import '../../repositories/revenue_reply_repository.dart';
import '../../repositories/government_approval_repository.dart';
import '../../models/government_approval_model.dart';
import '../../repositories/tree_officer_repository.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/application_model.dart';
import '../../models/tree_model.dart';
import '../../repositories/tree_repository.dart';
import '../../widgets/tree_inspection_table.dart';
import '../bfo/tree/tree_count_summary_card.dart';
import '../../constants/history_actions.dart';
import '../../constants/workflow_status.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/history_repository.dart';
import '../../services/session_service.dart';
import '../../repositories/rfo_item_approval_repository.dart';
import '../../repositories/rfo_deferred_letter_recipient_repository.dart';
import '../../repositories/forwarded_source_repository.dart';
import '../../repositories/master_repository.dart';
import '../../repositories/application_type_repository.dart';
import '../../repositories/application_type_permission_mapping_repository.dart';
import '../../widgets/verification_card.dart';
import '../../widgets/responsive_actions.dart';
import '../../models/photo_model.dart';
import '../../models/document_model.dart';
import '../../repositories/photo_repository.dart';
import '../../repositories/document_repository.dart';
import '../../models/revenue_opinion_model.dart';
import '../../models/application_revenue_opinion_model.dart';
import '../../repositories/revenue_opinion_repository.dart';
import '../../repositories/application_revenue_opinion_repository.dart';
import '../../repositories/inspection_defer_reason_repository.dart';
import '../../services/drfo_document_service.dart';
import '../../services/workflow_service.dart';
import '../bfo/wizard/inspection_summary_step.dart';
import '../bfo/wizard/photo_step.dart';
import '../bfo/wizard/document_step.dart';
import '../bfo/wizard/inspection_decision_step.dart';
import '../bfo/wizard/mahazar_step.dart';
import '../../repositories/mahazar_repository.dart';
import '../bfo/tree/add_edit_tree_screen.dart';
import '../bfo/tree/tree_count_home_screen.dart';

class RFODecisionScreen extends StatefulWidget {

  final ApplicationModel application;

  const RFODecisionScreen({

    super.key,

    required this.application,

  });

  @override
  State<RFODecisionScreen> createState() =>
      _RFODecisionScreenState();

}

class _RFODecisionScreenState
    extends State<RFODecisionScreen> {

  final PageController pageController =
      PageController();

  int currentPage = 0;

  final remarksController =
      TextEditingController();

final workNameController =
    TextEditingController();

final gpsController =
    TextEditingController();

final ApplicationRepository applicationRepository =
    ApplicationRepository();

final HistoryRepository historyRepository =
    HistoryRepository();

final RfoItemApprovalRepository
    rfoApprovalRepository =
    RfoItemApprovalRepository();

final RfoDeferredLetterRecipientRepository
    rfoDeferredRecipientRepository =
    RfoDeferredLetterRecipientRepository();

final ForwardedSourceRepository
    forwardedSourceRepository =
    ForwardedSourceRepository();

final MasterRepository masterRepository =
    MasterRepository();

final ApplicationTypeRepository
    applicationTypeRepository =
    ApplicationTypeRepository();

List<Map<String, dynamic>>
    deferredRfoRecipientOptions = [];

String? selectedDeferredRfoToKey;

final List<String>
    selectedDeferredRfoCopyKeys = [];

bool loadingDeferredRfoRecipients = true;

final Map<String, String?> approvalDecisions =
    {};

final Map<String, String?> approvalReasons =
    {};

List<String> applicationReasons = [];
List<String> gpsReasons = [];
List<String> photoReasons = [];
List<String> documentReasons = [];
List<String> treeReasons = [];

List<String> deferredVerificationReasons = [];

List<Map<String, dynamic>>
    selectedDeferredReasons = [];

final InspectionDeferredReasonRepository
    inspectionDeferredReasonRepository =
    InspectionDeferredReasonRepository();

bool loadingApprovals = true;
final governmentRepository = GovernmentApprovalRepository();
GovernmentApproval? governmentApproval;
String governmentPermission = '';
bool? governmentKhata;
int? governmentOfficerId;
bool governmentBusy = false;
bool get needsGovernmentFinal => GovernmentApproval.isGovernment(widget.application.applicationType) && !isDeferredApplication && !allTreesNotRecommended;

final treeOfficerRepository = TreeOfficerRepository();
List<Map<String, dynamic>> treeOfficerOptions = [];
int? selectedTreeOfficerId;
bool savingTreeOfficer = false;

String governmentAgencyDisplay = "";
String urbanRuralDisplay = "";
String whyRemovingDisplay = "";
String purposeDisplay = "";
String structureTypeDisplay = "";
String overallRemarkDisplay = "";

List<Map<String, dynamic>>
    applicationTypeOptions = [];

List<Map<String, dynamic>>
    governmentAgencyOptions = [];

List<Map<String, dynamic>>
    urbanRuralOptions = [];

List<Map<String, dynamic>>
    whyRemovingOptions = [];

List<Map<String, dynamic>>
    allPurposeOptions = [];

List<Map<String, dynamic>>
    purposeOptions = [];

List<Map<String, dynamic>>
    structureTypeOptions = [];

List<Map<String, dynamic>>
    overallRemarkOptions = [];

List<TreeModel> trees = [];

Map<int, String> speciesMap = {};
Map<int, String> treeStatusMap = {};
Map<int, String> recommendationTypeMap = {};
Map<int, String> recommendationReasonMap = {};

List<PhotoModel> photos = [];
List<DocumentModel> documents = [];

final PhotoRepository photoRepository =
    PhotoRepository();

final DocumentRepository documentRepository =
    DocumentRepository();

final MahazarRepository mahazarRepository =
    MahazarRepository();

final ApplicationRevenueOpinionRepository
    applicationRevenueOpinionRepository =
    ApplicationRevenueOpinionRepository();

final RevenueOpinionRepository revenueOpinionRepository =
    RevenueOpinionRepository();

RevenueOpinionModel? selectedRevenueOpinion;
List<RevenueOpinionModel>
    revenueOpinionOptions = [];
bool allTreesNotRecommended = false;
bool allTreesBranchOnly = false;
bool hasFullTreeRecommendation = false;

final DrfoDocumentService documentService =
    DrfoDocumentService();

final WorkflowService workflowService =
    WorkflowService();

List<File> generatedDocuments = [];

bool get needsDeferredRfoRecipientSelection =>
    !isRtcApplication &&
    (isDeferredApplication ||
        allTreesNotRecommended);


bool get isDeferredApplication =>
    widget.application.inspectionDecision
        .trim()
        .toUpperCase() ==
    "DEFERRED";

bool get isRtcApplication =>
    widget.application.applicationType
        .trim()
        .toUpperCase() ==
    "RTC";

bool get isMccApplication =>
    widget.application.applicationType
        .trim()
        .toUpperCase() ==
    "MCC";

bool get isSandalGovernmentApplication =>
    widget.application.applicationType
        .trim()
        .toUpperCase() ==
    "SGL";

bool get isSandalApplication {
  final type = widget.application.applicationType
      .trim()
      .toUpperCase();
  return type == "SPL" || type == "SGL";
}

String sandalDestinationText = "Not entered";

Future<void> loadSandalDestinationText() async {
  final custom =
      widget.application.sandalDestinationCustom.trim();
  final id = widget.application.sandalDestinationId;
  if (id == null) {
    sandalDestinationText =
        custom.isEmpty ? "Not entered" : custom;
    return;
  }
  final item = await masterRepository.getMasterById(id);
  if (item == null) {
    sandalDestinationText =
        custom.isEmpty ? "Not entered" : custom;
    return;
  }
  final kannada = item["kannadaName"]?.toString().trim() ?? "";
  final value = item["value"]?.toString().trim() ?? "";
  if (value.isNotEmpty && kannada.isNotEmpty) {
    sandalDestinationText = "$value ($kannada)";
  } else if (value.isNotEmpty) {
    sandalDestinationText = value;
  } else {
    sandalDestinationText =
        kannada.isEmpty ? "Not entered" : kannada;
  }
}

bool get isGovernmentApplication {
  final type =
      widget.application.applicationType
          .trim()
          .toUpperCase();

  return type == "GL" ||
      type == "STGL" ||
      type == "CGL" ||
      type == "SGL" ||
      type == "MCC";
}

bool get isPrivateApplication {
  final type =
      widget.application.applicationType
          .trim()
          .toUpperCase();

  return type == "PL" ||
      type == "SPL";
}

bool get needsBranchPermission =>
    isPrivateApplication && !isDeferredApplication && allTreesBranchOnly;

bool get needsRevenueOpinionRequest {
  final type =
      widget.application.applicationType
          .trim()
          .toUpperCase();

  return (type == "PL" || type == "SPL") &&
      !isDeferredApplication &&
      !allTreesNotRecommended &&
      hasFullTreeRecommendation;
}

bool get needsRevenueOpinion {
  final type =
      widget.application.applicationType
          .trim()
          .toUpperCase();

  return !isRtcApplication &&
      !allTreesNotRecommended &&
      !allTreesBranchOnly &&
      (type == "PL" || type == "SPL");
}

bool get needsMahazar {
  return !isRtcApplication &&
      !allTreesNotRecommended;
}

String get applicationTypeDisplay {
  switch (widget.application.applicationType
      .trim()
      .toUpperCase()) {
    case "RTC":
      return "RTC Entry";
    case "PL":
      return "Private Land";
    case "STGL":
      return "State Government Land";
    case "CGL":
      return "Central Government Land";
    case "GL":
      return "Government Land";
    case "SPL":
      return "Sandal Private";
    case "SGL":
      return "Sandal Government";
    default:
      return widget.application.applicationType;
  }
}

  @override
  void initState() {

    super.initState();

    remarksController.text =
        widget.application.rfoOverallRemarks;

    workNameController.text =
    widget.application.workName;

    gpsController.text =
    widget.application.gpsCoordinates;

   _loadRfoDecisionData();

  }

  Future<void> _loadRfoDecisionData() async {
  await _loadApprovals();

  if (!mounted) return;

  await loadSandalDestinationText();

  if (!mounted) return;

  await _loadDeferredRfoRecipients();
}

Future<void> _loadDeferredRfoRecipients() async {
  if (!needsDeferredRfoRecipientSelection) {
    if (mounted) {
      setState(() {
        loadingDeferredRfoRecipients = false;
      });
    }
    return;
  }

  final options =
      <Map<String, dynamic>>[];

  final addedKeys = <String>{};

  void addOption({
    required String key,
    required int? sourceId,
    String sourceKind = 'SOURCE',
    required String text,
    required String label,
  }) {
    if (text.trim().isEmpty ||
        addedKeys.contains(key)) {
      return;
    }

    options.add({
      "key": key,
      "sourceId": sourceId,
      "sourceKind": sourceKind,
      "text": text.trim(),
      "label": label.trim(),
    });

    addedKeys.add(key);
  }

  final applicantName =
      widget.application.applicantName.trim();

  final applicantAddress =
      widget.application.applicantAddress.trim();

  final applicantText = [
    applicantName,
    applicantAddress,
  ].where((value) => value.isNotEmpty).join("\n");

  addOption(
    key: "APPLICANT",
    sourceId: null,
    text: applicantText,
    label: [
      "Applicant",
      applicantName,
      applicantAddress,
    ].where((value) => value.isNotEmpty).join(" - "),
  );

  final isForwarded =
      widget.application.applicationSource
          .trim()
          .toUpperCase() ==
      "FORWARDED";

  if (isForwarded) {
    for (final reference
        in widget.application.forwardingReferences) {
      final sourceName =
          reference.forwardedBy.trim();

      addOption(
        key:
            "${reference.sourceKind}_${reference.sourceId}",
        sourceId: reference.sourceId,
        sourceKind: reference.sourceKind,
        text: sourceName,
        label: sourceName,
      );
    }

    final allSources =
        await forwardedSourceRepository
            .getSources();

    for (final source in allSources) {
      final shortCode =
          source["shortCode"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              "";

      if (shortCode != "ACF" &&
          shortCode != "DCF") {
        continue;
      }

      final sourceId =
          source["id"] as int?;

      final sourceName =
          source["sourceName"]
                  ?.toString()
                  .trim() ??
              "";

      if (sourceId == null) {
        continue;
      }

      addOption(
        key: "SOURCE_$sourceId",
        sourceId: sourceId,
        text: sourceName,
        label: sourceName,
      );
    }
  }

  final applicationId =
      widget.application.id;

  List<RfoDeferredLetterRecipient>
      savedRecipients = [];

  if (applicationId != null) {
    savedRecipients =
        await rfoDeferredRecipientRepository
            .getRecipients(applicationId);
  }

  String? savedPrimaryKey;

  for (final recipient in savedRecipients) {
    if (recipient.isPrimary) {
      savedPrimaryKey =
          recipient.recipientKey;
      break;
    }
  }

  final validKeys = options
      .map(
        (option) =>
            option["key"].toString(),
      )
      .toSet();

  final directApplication =
      !isForwarded;

  final resolvedPrimaryKey =
      directApplication
          ? "APPLICANT"
          : validKeys.contains(savedPrimaryKey)
              ? savedPrimaryKey
              : null;

  final savedCopyKeys = savedRecipients
      .where(
        (recipient) =>
            !recipient.isPrimary &&
            validKeys.contains(
              recipient.recipientKey,
            ) &&
            recipient.recipientKey !=
                resolvedPrimaryKey,
      )
      .map(
        (recipient) =>
            recipient.recipientKey,
      )
      .toList();

  if (!mounted) return;

  setState(() {
    deferredRfoRecipientOptions = options;

    selectedDeferredRfoToKey =
        resolvedPrimaryKey;

    selectedDeferredRfoCopyKeys
      ..clear()
      ..addAll(
        directApplication
            ? <String>[]
            : savedCopyKeys,
      );

    loadingDeferredRfoRecipients = false;
  });
}


  String _approvalMapKey(
  String itemKey, [
  int itemId = 0,
]) {
  return "${itemKey}_$itemId";
}

Future<String> _masterDisplay(
  int? masterId, {
  String fallback = "",
}) async {
  if (masterId == null) {
    return fallback;
  }

  final item =
      await masterRepository.getMasterById(
    masterId,
  );

  final value =
      item?["value"]?.toString().trim() ?? "";

  return value.isNotEmpty
      ? value
      : fallback;
}

bool get isDevelopmentWorkSelected {
  for (final item in whyRemovingOptions) {
    if (item["id"] ==
        widget.application.whyRemovingId) {
      return item["code"]
              ?.toString()
              .trim()
              .toUpperCase() ==
          "WORKS";
    }
  }

  return false;
}

void _filterRfoPurposeOptions() {
  String whyRemovingCode = "";

  for (final item in whyRemovingOptions) {
    if (item["id"] ==
        widget.application.whyRemovingId) {
      whyRemovingCode =
          item["code"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              "";
      break;
    }
  }

  if (whyRemovingCode.isEmpty) {
    purposeOptions = [];
    return;
  }

  purposeOptions =
      allPurposeOptions.where(
    (item) {
      final parentCode =
          item["parentCode"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              "";

      return parentCode ==
          whyRemovingCode;
    },
  ).toList();
}

Future<void> _loadEditableMasterOptions() async {
  final applicationTypes =
      await applicationTypeRepository.getAll();

  final savedApplicationType =
      widget.application.applicationType
          .trim()
          .toUpperCase();

  applicationTypeOptions =
      applicationTypes.where(
    (item) {
      final isActive =
          item["isActive"] == 1;

      final shortCode =
          item["shortCode"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              "";

      final name =
          item["applicationType"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              "";

      return isActive ||
          shortCode == savedApplicationType ||
          name == savedApplicationType;
    },
  ).toList();

  List<Map<String, dynamic>>
      activeOrSelected(
    List<Map<String, dynamic>> items,
    int? selectedId,
  ) {
    return items.where(
      (item) =>
          item["isActive"] == 1 ||
          item["id"] == selectedId,
    ).toList();
  }

  governmentAgencyOptions =
      activeOrSelected(
    await masterRepository.getMasters(
      "Government Agency",
    ),
    widget.application.governmentAgencyId,
  );

  urbanRuralOptions =
      activeOrSelected(
    await masterRepository.getMasters(
      "Urban Rural",
    ),
    widget.application.urbanRuralId,
  );

  whyRemovingOptions =
      activeOrSelected(
    await masterRepository.getMasters(
      "Why Removing",
    ),
    widget.application.whyRemovingId,
  );

  allPurposeOptions =
      activeOrSelected(
    await masterRepository.getMasters(
      "Purpose",
    ),
    widget.application.purposeId,
  );

  structureTypeOptions =
      activeOrSelected(
    await masterRepository.getMasters(
      "Structure Type",
    ),
    widget.application.structureTypeId,
  );

  overallRemarkOptions =
      activeOrSelected(
    await masterRepository.getMasters(
      "Inspecting Officer Overall Remark",
    ),
    widget.application.overallRemarkId,
  );

  _filterRfoPurposeOptions();
}

Future<void> _loadApprovals() async {
  final applicationId =
      widget.application.id;

  if (applicationId == null) {
    if (mounted) {
      setState(() {
        loadingApprovals = false;
      });
    }
    return;
  }

governmentApproval = await governmentRepository.get(applicationId);
governmentPermission = governmentApproval?.permissionType ?? '';
governmentKhata = governmentApproval?.khataGiven;
governmentOfficerId = governmentApproval?.treeOfficerId;
treeOfficerOptions = await treeOfficerRepository.getAll();
selectedTreeOfficerId = await treeOfficerRepository.getSelection(applicationId);
await _loadEditableMasterOptions();
trees = await TreeRepository().getTrees(
  applicationId,
);

allTreesNotRecommended =
    await TreeRepository()
        .areAllTreesNotRecommended(
  applicationId,
);

revenueOpinionOptions =
    await revenueOpinionRepository.getActive();

final revenueSelection =
    await applicationRevenueOpinionRepository
        .getByApplication(
  applicationId,
);

if (revenueSelection != null) {
  selectedRevenueOpinion =
      await revenueOpinionRepository.getById(
    revenueSelection.revenueOpinionId,
  );
} else {
  selectedRevenueOpinion = null;
}

photos = await photoRepository.getPhotos(
  applicationId,
);

documents =
    await documentRepository.getDocuments(
  applicationId,
);

generatedDocuments =
    await documentService.getGeneratedDocuments(
  widget.application.officeNumber,
);

final species =
    await masterRepository.getSpecies();

speciesMap = {
  for (final item in species)
    item["id"] as int:
        item["value"].toString(),
};

final treeStatuses =
    await masterRepository.getMasters(
  "Tree Status",
);

treeStatusMap = {
  for (final item in treeStatuses)
    item["id"] as int:
        item["value"].toString(),
};

final recommendationTypes =
    await masterRepository.getMasters(
  "Recommendation Type",
);

final fullRecommendationTypeIds =
    recommendationTypes
        .where(
          (item) =>
              item["code"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ==
              "FULL",
        )
        .map(
          (item) => item["id"] as int,
        )
        .toSet();

hasFullTreeRecommendation = trees.any(
  (tree) => fullRecommendationTypeIds
      .contains(
    tree.recommendationTypeId,
  ),
);

allTreesBranchOnly = TreeRepository.hasOnlyBranchRecommendations(trees, recommendationTypes, allowNotRecommended:widget.application.applicationType.trim().toUpperCase() == 'PL');

recommendationTypeMap = {
  for (final item in recommendationTypes)
    item["id"] as int:
        item["value"].toString(),
};

final recommendationReasons =
    await masterRepository.getMasters(
  "Recommendation Reason",
);

recommendationReasonMap = {
  for (final item in recommendationReasons)
    item["id"] as int:
        item["value"].toString(),
};

  applicationReasons =
      await masterRepository
          .getVerificationReasons(
    "APPLICATION_TYPE",
  );

  gpsReasons =
      await masterRepository
          .getVerificationReasons(
    "GPS",
  );

  photoReasons =
      await masterRepository
          .getVerificationReasons(
    "PHOTO",
  );

  documentReasons =
      await masterRepository
          .getVerificationReasons(
    "DOCUMENT",
  );

  treeReasons =
      await masterRepository
          .getVerificationReasons(
    "TREE",
  );

  deferredVerificationReasons =
    await masterRepository
        .getVerificationReasons(
  "DEFERRED",
);

selectedDeferredReasons =
    await inspectionDeferredReasonRepository
        .getReasons(
  applicationId,
);

governmentAgencyDisplay =
    await _masterDisplay(
  widget.application.governmentAgencyId,
);

urbanRuralDisplay =
    await _masterDisplay(
  widget.application.urbanRuralId,
);

whyRemovingDisplay =
    await _masterDisplay(
  widget.application.whyRemovingId,
);

purposeDisplay =
    await _masterDisplay(
  widget.application.purposeId,
  fallback:
      widget.application.purpose,
);

structureTypeDisplay =
    await _masterDisplay(
  widget.application.structureTypeId,
);

overallRemarkDisplay =
    await _masterDisplay(
  widget.application.overallRemarkId,
  fallback:
      widget.application.overallRemarks,
);

  final savedDecisions =
      await rfoApprovalRepository
          .getApplicationDecisions(
    applicationId,
  );

  approvalDecisions.clear();
  approvalReasons.clear();

  for (final row in savedDecisions) {
    final itemKey =
        row["itemKey"]?.toString() ?? "";

    final itemId =
        row["itemId"] as int? ?? 0;

    final mapKey =
        _approvalMapKey(
      itemKey,
      itemId,
    );

    approvalDecisions[mapKey] =
        row["decision"]?.toString();

    approvalReasons[mapKey] =
        row["reason"]?.toString();
  }

  if (mounted) {
    setState(() {
      loadingApprovals = false;
    });
  }
}

Future<void> _saveApprovalDecision({
  required String itemKey,
  int itemId = 0,
  required String? decision,
  String? reason,
}) async {
  final applicationId =
      widget.application.id;

  if (applicationId == null ||
      decision == null) {
    return;
  }

  final mapKey =
      _approvalMapKey(
    itemKey,
    itemId,
  );

  setState(() {
    approvalDecisions[mapKey] =
        decision;

    approvalReasons[mapKey] =
        decision == "Re-inspect"
            ? reason
            : null;
  });

  await rfoApprovalRepository.saveDecision(
    applicationId: applicationId,
    itemKey: itemKey,
    itemId: itemId,
    decision: decision,
    reason:
        decision == "Re-inspect"
            ? reason
            : null,
    approvedBy:
        SessionService.instance.name,
  );
}

Future<void> _saveModifiedRevenueOpinion(
  int? revenueOpinionId,
) async {
  final applicationId =
      widget.application.id;

  if (applicationId == null ||
      revenueOpinionId == null) {
    return;
  }

  RevenueOpinionModel? selected;

  for (final option
      in revenueOpinionOptions) {
    if (option.id == revenueOpinionId) {
      selected = option;
      break;
    }
  }

  if (selected == null) {
    return;
  }

  await applicationRevenueOpinionRepository.save(
    ApplicationRevenueOpinionModel(
      applicationId: applicationId,
      revenueOpinionId:
          revenueOpinionId,
    ),
  );

  if (!mounted) return;

  setState(() {
    selectedRevenueOpinion = selected;
  });
}

Widget _approvalCard({
  required String itemKey,
  int itemId = 0,
  required String title,
  required String value,
  required List<String> reasons,
  VoidCallback? onView,
  Widget? modifyField,
  bool verticalOptions = false,
}) {
  final mapKey =
      _approvalMapKey(
    itemKey,
    itemId,
  );

  return VerificationCard(
    title: title,
    value:
        value.trim().isEmpty
            ? "-"
            : value,
    approvalOptions: true,
    approvalOptionsVertical:
    verticalOptions,
    verificationStatus:
        approvalDecisions[mapKey],
    selectedReason:
        approvalReasons[mapKey],
    reasons: reasons,
    onView: onView,
    modifyField: modifyField,
    onStatusChanged: (decision) async {
      await _saveApprovalDecision(
        itemKey: itemKey,
        itemId: itemId,
        decision: decision,
      );
    },
    onReasonChanged: (reason) async {
      await _saveApprovalDecision(
        itemKey: itemKey,
        itemId: itemId,
        decision:
            approvalDecisions[mapKey],
        reason: reason,
      );
    },
  );
}

  @override
  void dispose() {

workNameController.dispose();

gpsController.dispose();

    remarksController.dispose();

    pageController.dispose();

    super.dispose();

  }
List<String> _requiredApprovalKeys() {
  if (isDeferredApplication) {
    return [
      _approvalMapKey("DEFERRED"),
    ];
  }

  final keys = <String>[
    _approvalMapKey("APPLICATION_TYPE"),
    _approvalMapKey("GPS"),
    _approvalMapKey("PHOTOS"),
    _approvalMapKey("DOCUMENTS"),
  ];

  if (!isRtcApplication) {
    if (isGovernmentApplication) {
      keys.add(
        _approvalMapKey("GOVERNMENT_AGENCY"),
      );
    }

    if (isPrivateApplication) {
      keys.add(
        _approvalMapKey("URBAN_RURAL"),
      );
    }

    keys.addAll([
      _approvalMapKey("WHY_REMOVING"),
      _approvalMapKey("PURPOSE"),
      _approvalMapKey("STRUCTURE_TYPE"),
    ]);

  if (isDevelopmentWorkSelected) {
      keys.add(
        _approvalMapKey("WORK_NAME"),
      );
    }
  }

  if (isRtcApplication) {
  keys.add(
    _approvalMapKey("TREE_COUNT"),
  );
} else {
  for (final tree in trees) {
    if (tree.id != null) {
      keys.add(
        _approvalMapKey(
          "TREE",
          tree.id!,
        ),
      );
    }
  }
}

  if (needsRevenueOpinion) {
    keys.add(
      _approvalMapKey("REVENUE_OPINION"),
    );
  }

  if (needsMahazar) {
    keys.add(
      _approvalMapKey("MAHAZAR"),
    );
  }

  if (isSandalApplication) {
    keys.add(
      _approvalMapKey("SANDAL_DESTINATION"),
    );
  }

  if (!isRtcApplication) {
    keys.add(
      _approvalMapKey("OVERALL_REMARK"),
    );
  }

  return keys;
}

bool get _hasRfoReinspection {
  return _requiredApprovalKeys().any(
    (key) =>
        approvalDecisions[key] == "Re-inspect",
  );
}

bool get _deferredRfoRecipientReady =>
    !needsDeferredRfoRecipientSelection ||
    (selectedDeferredRfoToKey != null &&
        selectedDeferredRfoToKey!
            .trim()
            .isNotEmpty);


bool get _allRfoItemsApproved {
  final requiredKeys = _requiredApprovalKeys();

return requiredKeys.isNotEmpty &&
    requiredKeys.every(
      (key) {
        final decision =
            approvalDecisions[key];

        return decision == "Approve" ||
            decision == "Modify";
      },
    );
}

Future<bool> _saveDeferredRfoRecipients({
  required bool requirePrimary,
}) async {
  if (!needsDeferredRfoRecipientSelection) {
    return true;
  }

  final applicationId =
      widget.application.id;

  if (applicationId == null) {
    return false;
  }

  final primaryKey =
      selectedDeferredRfoToKey;

  if (primaryKey == null ||
      primaryKey.trim().isEmpty) {
    if (requirePrimary && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Select the To recipient before Final Approval.",
          ),
        ),
      );
    }

    return !requirePrimary;
  }

  final primaryOption =
      _deferredRecipientOption(primaryKey);

  if (primaryOption == null) {
    return false;
  }

  final copyRecipients =
      <RfoDeferredLetterRecipient>[];

  for (int index = 0;
      index < selectedDeferredRfoCopyKeys.length;
      index++) {
    final copyKey =
        selectedDeferredRfoCopyKeys[index];

    if (copyKey == primaryKey) {
      continue;
    }

    final copyOption =
        _deferredRecipientOption(copyKey);

    if (copyOption == null) {
      continue;
    }

    copyRecipients.add(
      RfoDeferredLetterRecipient(
        recipientKey: copyKey,
        sourceId:
            copyOption["sourceId"] as int?,
        sourceKind:
            copyOption["sourceKind"]?.toString() ??
                "SOURCE",
        recipientText:
            copyOption["text"]?.toString() ??
                "",
        isPrimary: false,
        displayOrder: index + 1,
      ),
    );
  }

  await rfoDeferredRecipientRepository
      .saveRecipients(
    applicationId: applicationId,
    primaryRecipient:
        RfoDeferredLetterRecipient(
      recipientKey: primaryKey,
      sourceId:
          primaryOption["sourceId"] as int?,
      sourceKind:
          primaryOption["sourceKind"]?.toString() ??
              "SOURCE",
      recipientText:
          primaryOption["text"]?.toString() ??
              "",
      isPrimary: true,
      displayOrder: 0,
    ),
    copyRecipients: copyRecipients,
  );

  return true;
}

Future<bool> _saveGovernmentOptions() async {
  if (governmentBusy) return false;
  setState(() => governmentBusy = true);
  try {
    governmentApproval = await governmentRepository.saveOptions(widget.application.id!, governmentPermission, governmentKhata, governmentOfficerId);
    return true;
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    return false;
  } finally { if (mounted) setState(() => governmentBusy = false); }
}

Widget _governmentFinalPage() {
  // MCC follows valuation workflow only (no auction) with khata
  // treated as given (no khata question).
  if (isMccApplication && governmentPermission.isEmpty) {
    governmentPermission = 'Valuation';
  }
  if (isMccApplication) {
    governmentKhata = true;
  }
  // Sandal Government: direct DCF letter, no valuation/auction,
  // no khata question, no tree-officer selection.
  if (isSandalGovernmentApplication) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Government Sandal — Final Approval',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      const Text(
          'Final Approval generates the RFO sandal approval letter addressed to the DCF officer and completes the application.'),
      const SizedBox(height: 16),
      const Text(
          'Finalized letters will be available to the caseworker for printing.'),
      if (governmentBusy) const LinearProgressIndicator(),
    ]);
  }
  return ListView(padding: const EdgeInsets.all(20), children: [
  const Text('Government Land — Final Approval', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
  const SizedBox(height: 20),
  if (isMccApplication)
    const InputDecorator(
      decoration: InputDecoration(
          labelText: 'Permission type for RFO',
          border: OutlineInputBorder()),
      child: Text('Valuation'),
    )
  else
    DropdownButtonFormField<String>(initialValue: governmentPermission.isEmpty ? null : governmentPermission,
    isExpanded: true, decoration: const InputDecoration(labelText: 'Select permission type for RFO', border: OutlineInputBorder()),
    items: GovernmentApproval.types.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: governmentBusy ? null : (v) async {setState(() {governmentPermission = v ?? '';}); await _saveGovernmentOptions();},
  ),
  if (governmentPermission == 'Valuation' && !isMccApplication) ...[
    const SizedBox(height: 20),
    DropdownButtonFormField<bool>(initialValue: governmentKhata, decoration: const InputDecoration(labelText: 'Whether khata details given?', border: OutlineInputBorder()),
      items: const [DropdownMenuItem(value: true, child: Text('Yes')), DropdownMenuItem(value: false, child: Text('No'))],
      onChanged: governmentBusy ? null : (v) async {setState(() => governmentKhata = v); await _saveGovernmentOptions();},
    ),
    const SizedBox(height: 20),
    Text(governmentKhata == false ? 'Final Approval generates a document request to the applicant and moves the case to Pending Government land approvals.' : 'Final Approval generates the RFO GL valuation letter to the selected Tree Officer and completes the application.'),
  ],
  if (governmentPermission == 'Valuation' && isMccApplication) ...[
    const SizedBox(height: 20),
    const Text('Final Approval generates the RFO GL valuation letter to the selected Tree Officer and completes the application.'),
  ],
  if (GovernmentApproval.types.contains(governmentPermission)) ...[
    const SizedBox(height: 20),
    DropdownButtonFormField<int>(initialValue: governmentOfficerId, isExpanded: true, decoration: const InputDecoration(labelText: 'Select Tree officer', border: OutlineInputBorder()),
      items: treeOfficerOptions.map((row) => DropdownMenuItem(value: row['id'] as int, child: Text(row['name'].toString()))).toList(),
      onChanged: governmentBusy ? null : (v) async {setState(() => governmentOfficerId = v); await _saveGovernmentOptions();},
    ),
  ],
  if (governmentPermission == 'Auction') ...[
    const SizedBox(height: 20), const Text('Final Approval generates the RFO DO letter and Taggu Bele Patti, then completes the application.'),
  ],
  const SizedBox(height: 16), const Text('Finalized letters will be available to the caseworker for printing.'),
  if (governmentBusy) const LinearProgressIndicator(),
  ]);
}

Future<void> _finalizeGovernmentApproval() async {
  if (governmentBusy) return;
  setState(() => governmentBusy = true);
  final previousDate = widget.application.rfoApprovalDate;
  try {
    // Sandal Government: direct DCF approval letter, no options.
    if (isSandalGovernmentApplication) {
      final date = DateTime.now().toIso8601String();
      widget.application.rfoApprovalDate = date;
      await documentService.generateRfoSandalGovtApprovalLetter(
        widget.application,
      );
      widget.application.status = WorkflowStatus.completed;
      await applicationRepository.updateApplication(
        widget.application,
      );
      await historyRepository.addHistory(
        officeNumber: widget.application.officeNumber,
        action: HistoryActions.approved,
        remarks: "Sandal government application approved by RFO.",
        actionBy: SessionService.instance.name,
      );
      if (mounted) Navigator.pop(context, true);
      return;
    }
    final record = await governmentRepository.saveOptions(widget.application.id!, governmentPermission, governmentKhata, governmentOfficerId);
    final error = GovernmentApprovalRepository.validateOptions(record);
    if (error != null) throw StateError(error);
    final date = DateTime.now().toIso8601String();
    widget.application.rfoApprovalDate = date;
    final files = await documentService.generateGovernmentLandLetters(widget.application, record);
    await governmentRepository.finishInitial(record, files.map((f) => f.path).toList(), date);
    widget.application.status = record.permissionType == 'Valuation' && record.khataGiven == false ? WorkflowStatus.pendingGovernmentLandApprovals : WorkflowStatus.completed;
    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    widget.application.rfoApprovalDate = previousDate;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  } finally { if (mounted) setState(() => governmentBusy = false); }
}

Future<void> _saveRfoDraft() async {
  if (needsGovernmentFinal && !await _saveGovernmentOptions()) return;
  final saved =
      await _saveDeferredRfoRecipients(
    requirePrimary: false,
  );

  if (!saved || !mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "RFO approval draft saved.",
      ),
    ),
  );
}

Future<void> _finalizeRfoApproval() async {
  try {
    await _finalizeRfoApprovalUnsafe();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Final approval failed: $e",
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}

Future<void> _finalizeRfoApprovalUnsafe() async {
  final requiredKeys = _requiredApprovalKeys();

  final missingDecision = requiredKeys.any(
    (key) =>
        approvalDecisions[key] == null ||
        approvalDecisions[key]!.trim().isEmpty,
  );

  if (missingDecision) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Approve or select Re-inspect for every item.",
        ),
      ),
    );
    return;
  }

  final reinspectionKeys = requiredKeys.where(
    (key) =>
        approvalDecisions[key] == "Re-inspect",
  ).toList();

  final missingReason = reinspectionKeys.any(
    (key) =>
        approvalReasons[key] == null ||
        approvalReasons[key]!.trim().isEmpty,
  );

  if (missingReason) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Select a reason for every Re-inspect item.",
        ),
      ),
    );
    return;
  }

  if (reinspectionKeys.isNotEmpty) {
    final reasons = reinspectionKeys
        .map(
          (key) => approvalReasons[key]!.trim(),
        )
        .toSet()
        .join(", ");

    final assignedBfoId =
        widget.application.assignedBFOId ?? 0;

    if (assignedBfoId > 0) {
      widget.application.status =
          WorkflowStatus.returnedToBFO;
    } else {
      widget.application.status =
          WorkflowStatus
              .pendingDRFOReSelfInspection;
    }

    await applicationRepository.updateApplication(
      widget.application,
    );

    await historyRepository.addHistory(
      officeNumber:
          widget.application.officeNumber,
      action: assignedBfoId > 0
          ? "Returned by RFO to BFO for Re-inspection"
          : "Returned by RFO to DRFO Self Inspection",
      remarks: reasons,
      actionBy: SessionService.instance.name,
    );

    if (!mounted) return;

    Navigator.pop(context, true);
    return;
  }

final recipientsSaved =
    await _saveDeferredRfoRecipients(
  requirePrimary: true,
);

if (!recipientsSaved) {
  return;
}

if (needsGovernmentFinal) {
  await _finalizeGovernmentApproval();
  return;
}

widget.application.rfoApprovalDate =
    DateTime.now().toIso8601String();

if (needsRevenueOpinionRequest) {
  final letter = await documentService.generateRfoRevenueOpinionRequestLetter(widget.application);
  await RevenueReplyRepository().startRequest(widget.application, letter.path);
  if (!mounted) return;
  Navigator.pop(context, true);
  return;
}

final applicationType =
    widget.application.applicationType
        .trim()
        .toUpperCase();

if (applicationType == "RTC") {
  await documentService
      .generateRfoRtcApprovedLetter(
    widget.application,
  );
} else if (needsBranchPermission) {
  await documentService.generateRfoPrivateLandBranchPermissionLetter(widget.application);
} else if (isDeferredApplication ||
    allTreesNotRecommended) {
  await documentService
      .generateRfoNonRtcDecisionLetter(
    widget.application,
  );
}

widget.application.status =
    WorkflowStatus.completed;

  await applicationRepository.updateApplication(
    widget.application,
  );

  await historyRepository.addHistory(
    officeNumber:
        widget.application.officeNumber,
    action: HistoryActions.approved,
    remarks:
        "All verification items approved by RFO.",
    actionBy: SessionService.instance.name,
  );

  if (!mounted) return;

  Navigator.pop(context, true);
}

Widget _buildInspectionSummaryPage() {
  return InspectionSummaryStep(
    application: widget.application,
    showNavigationButtons: false,
    onBack: () {},
    onNext: () {},
  );
}

Future<void> _regenerateRfoUpdatedMahazar() async {
  if (!needsMahazar ||
      widget.application.id == null) {
    return;
  }

  final mahazar =
      await mahazarRepository.getByApplication(
    widget.application.id!,
  );

  if (mahazar == null) {
    return;
  }

  await documentService.generateMahazar(
    widget.application,
    mahazar,
    isUpdated: true,
  );

  generatedDocuments =
      await documentService.getGeneratedDocuments(
    widget.application.officeNumber,
  );
}

Future<void> _saveRfoModifiedApplication() async {
  await applicationRepository.updateApplication(
    widget.application,
  );

  await _regenerateRfoUpdatedMahazar();

  governmentAgencyDisplay =
      await _masterDisplay(
    widget.application.governmentAgencyId,
  );

  urbanRuralDisplay =
      await _masterDisplay(
    widget.application.urbanRuralId,
  );

  whyRemovingDisplay =
      await _masterDisplay(
    widget.application.whyRemovingId,
  );

  purposeDisplay =
      await _masterDisplay(
    widget.application.purposeId,
    fallback:
        widget.application.purpose,
  );

  structureTypeDisplay =
      await _masterDisplay(
    widget.application.structureTypeId,
  );

  overallRemarkDisplay =
      await _masterDisplay(
    widget.application.overallRemarkId,
    fallback:
        widget.application.overallRemarks,
  );

  if (!mounted) return;

  setState(() {});
}

Widget _buildTreeOfficerSelection() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(children: [
      const Text('Select Tree officer'),
      const SizedBox(width: 16),
      Expanded(child: DropdownButtonFormField<int>(
        value: selectedTreeOfficerId,
        isExpanded: true,
        decoration: const InputDecoration(hintText:'Select officer',border:OutlineInputBorder()),
        items: treeOfficerOptions.map((row)=>DropdownMenuItem<int>(
          value:row['id'] as int, child:Text(row['name'].toString()),
        )).toList(),
        onChanged: savingTreeOfficer ? null : (value) async {
          if(value == null || widget.application.id == null) return;
          setState(()=>savingTreeOfficer=true);
          try {
            await treeOfficerRepository.saveSelection(widget.application.id!, value);
            if(mounted) setState(()=>selectedTreeOfficerId=value);
          } catch(e) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save tree officer: ' + e.toString())));
          } finally { if(mounted) setState(()=>savingTreeOfficer=false); }
        },
      )),
    ]),
  );
}

Widget _buildApplicationApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (isPrivateApplication) _buildTreeOfficerSelection(),
      const Text(
        "Application Details Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

     _approvalCard(
  itemKey: "APPLICATION_TYPE",
  title: "Application Type",
  value: applicationTypeDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: applicationTypeOptions
            .where(
              (item) {
                final currentType =
                    widget.application
                        .applicationType
                        .trim()
                        .toUpperCase();

                final code =
                    item["shortCode"]
                            ?.toString()
                            .trim()
                            .toUpperCase() ??
                        "";

                final name =
                    item["applicationType"]
                            ?.toString()
                            .trim()
                            .toUpperCase() ??
                        "";

                return code == currentType ||
                    name == currentType;
              },
            )
            .isNotEmpty
        ? applicationTypeOptions
            .firstWhere(
              (item) {
                final currentType =
                    widget.application
                        .applicationType
                        .trim()
                        .toUpperCase();

                final code =
                    item["shortCode"]
                            ?.toString()
                            .trim()
                            .toUpperCase() ??
                        "";

                final name =
                    item["applicationType"]
                            ?.toString()
                            .trim()
                            .toUpperCase() ??
                        "";

                return code == currentType ||
                    name == currentType;
              },
            )["id"] as int
        : null,
    decoration: const InputDecoration(
      labelText: "Application Type",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: applicationTypeOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["applicationType"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      final selectedItem =
          applicationTypeOptions.firstWhere(
        (item) =>
            item["id"] == selectedId,
      );

      widget.application.applicationType =
          selectedItem["shortCode"]
                  ?.toString() ??
              "";

      widget.application
              .verifiedApplicationType =
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

      await _saveRfoModifiedApplication();
    },
  ),
),

      if (!isRtcApplication &&
          isGovernmentApplication &&
          !isMccApplication)
      _approvalCard(
  itemKey: "GOVERNMENT_AGENCY",
  title: "Government Agency",
  value: governmentAgencyDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: governmentAgencyOptions.any(
      (item) =>
          item["id"] ==
          widget.application
              .governmentAgencyId,
    )
        ? widget.application
            .governmentAgencyId
        : null,
    decoration: const InputDecoration(
      labelText: "Government Agency",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: governmentAgencyOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      widget.application
              .governmentAgencyId =
          selectedId;

      await _saveRfoModifiedApplication();
    },
  ),
),
      if (!isRtcApplication &&
          isPrivateApplication)
        _approvalCard(
  itemKey: "URBAN_RURAL",
  title: "Urban / Rural",
  value: urbanRuralDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: urbanRuralOptions.any(
      (item) =>
          item["id"] ==
          widget.application
              .urbanRuralId,
    )
        ? widget.application.urbanRuralId
        : null,
    decoration: const InputDecoration(
      labelText: "Urban / Rural",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: urbanRuralOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      widget.application.urbanRuralId =
          selectedId;

      await _saveRfoModifiedApplication();
    },
  ),
),

      if (!isRtcApplication) ...[
       _approvalCard(
  itemKey: "WHY_REMOVING",
  title: "Why Removing",
  value: whyRemovingDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: whyRemovingOptions.any(
      (item) =>
          item["id"] ==
          widget.application
              .whyRemovingId,
    )
        ? widget.application.whyRemovingId
        : null,
    decoration: const InputDecoration(
      labelText: "Why Removing",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: whyRemovingOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      widget.application.whyRemovingId =
          selectedId;

      widget.application.purposeId =
          null;
      widget.application.purpose = "";

      _filterRfoPurposeOptions();

      await _saveRfoModifiedApplication();
    },
  ),
),

_approvalCard(
  itemKey: "PURPOSE",
  title: "Purpose",
  value: purposeDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: purposeOptions.any(
      (item) =>
          item["id"] ==
          widget.application.purposeId,
    )
        ? widget.application.purposeId
        : null,
    decoration: const InputDecoration(
      labelText: "Purpose",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: purposeOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      final selectedItem =
          purposeOptions.firstWhere(
        (item) =>
            item["id"] == selectedId,
      );

      widget.application.purposeId =
          selectedId;

      widget.application.purpose =
          selectedItem["value"]
                  ?.toString() ??
              "";

      await _saveRfoModifiedApplication();
    },
  ),
),

_approvalCard(
  itemKey: "STRUCTURE_TYPE",
  title: "Structure Type",
  value: structureTypeDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: structureTypeOptions.any(
      (item) =>
          item["id"] ==
          widget.application
              .structureTypeId,
    )
        ? widget.application.structureTypeId
        : null,
    decoration: const InputDecoration(
      labelText: "Structure Type",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: structureTypeOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      widget.application.structureTypeId =
          selectedId;

      await _saveRfoModifiedApplication();
    },
  ),
),

        if (isDevelopmentWorkSelected)
  _approvalCard(
    itemKey: "WORK_NAME",
    title: "Name of Work",
    value:
        widget.application.workName,
    reasons: applicationReasons,
    modifyField: Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller:
              workNameController,
          decoration:
              const InputDecoration(
            labelText: "Name of Work",
            border:
                OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment:
              Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(
              Icons.save,
            ),
            label: const Text(
              "Save",
            ),
            onPressed: () async {
              widget.application.workName =
                  workNameController.text
                      .trim();

              await _saveRfoModifiedApplication();
            },
          ),
        ),
      ],
    ),
  ),
      ],
    ],
  );
}

Future<void> _showInspectionPhotos() async {
  if (photos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No inspection photos available."),
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Inspection Photos"),
        content: SizedBox(
          width: 800,
          height: 500,
          child: GridView.builder(
            itemCount: photos.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Expanded(
                      child: Image.file(
                        File(photo.photoPath),
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Center(
                            child: Text(
                              "Photo file not available",
                            ),
                          );
                        },
                      ),
                    ),
                    if (photo.caption.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          photo.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text("CLOSE"),
          ),
        ],
      );
    },
  );
}

Future<void> _showUploadedDocuments() async {
  if (documents.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No uploaded documents available."),
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Uploaded Documents"),
        content: SizedBox(
          width: 700,
          height: 450,
          child: ListView.separated(
            itemCount: documents.length,
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (context, index) {
              final document = documents[index];

              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(
                  document.documentTypeName.trim().isEmpty
                      ? "Document ${index + 1}"
                      : document.documentTypeName,
                ),
                subtitle: document.remarks.trim().isEmpty
                    ? null
                    : Text(document.remarks),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  await OpenFilex.open(
                    document.filePath,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text("CLOSE"),
          ),
        ],
      );
    },
  );
}

Widget _buildEvidenceApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final gpsValue =
      widget.application.gpsCoordinates.trim();

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Inspection Evidence Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

     _approvalCard(
  itemKey: "GPS",
  title: "GPS",
  value: gpsValue.isEmpty
      ? "No GPS recorded"
      : gpsValue,
  reasons: gpsReasons,
  modifyField: TextFormField(
    controller: gpsController,
    decoration: InputDecoration(
      labelText:
          "Correct GPS Coordinates",
      hintText:
          "Latitude, Longitude",
      border:
          const OutlineInputBorder(),
      isDense: true,
      suffixIcon: IconButton(
        tooltip: "Save corrected GPS",
        icon:
            const Icon(Icons.save),
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

          widget.application
                  .gpsCoordinates =
              correctedGps;

          await _saveRfoModifiedApplication();
        },
      ),
    ),
    onFieldSubmitted: (value) async {
      final correctedGps =
          value.trim();

      if (correctedGps.isEmpty) {
        return;
      }

      widget.application.gpsCoordinates =
          correctedGps;

      await _saveRfoModifiedApplication();
    },
  ),
),

      _approvalCard(
  itemKey: "PHOTOS",
  title: "Inspection Photos",
  value: "${photos.length} Photo(s)",
  reasons: photoReasons,
  onView: _showInspectionPhotos,
  modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text(
        "Edit Inspection Photos",
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (routeContext) =>
                PhotoStep(
              application:
                  widget.application,
              onBack: () {
                Navigator.pop(
                  routeContext,
                );
              },
              onNext: () {
                Navigator.pop(
                  routeContext,
                );
              },
            ),
          ),
        );

        photos =
            await photoRepository.getPhotos(
          widget.application.id!,
        );

        if (mounted) {
          setState(() {});
        }
      },
    ),
  ),
),

     _approvalCard(
  itemKey: "DOCUMENTS",
  title: "Uploaded Documents",
  value: "${documents.length} Document(s)",
  reasons: documentReasons,
  onView: _showUploadedDocuments,
  modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text(
        "Edit Uploaded Documents",
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (routeContext) =>
                DocumentStep(
              application:
                  widget.application,
              onBack: () {
                Navigator.pop(
                  routeContext,
                );
              },
              onNext: () {
                Navigator.pop(
                  routeContext,
                );
              },
            ),
          ),
        );

        documents =
            await documentRepository
                .getDocuments(
          widget.application.id!,
        );

        await loadSandalDestinationText();

        if (mounted) {
          setState(() {});
        }
      },
    ),
  ),
),
      if (isSandalApplication)
      _approvalCard(
  itemKey: "SANDAL_DESTINATION",
  title: "Send Sandal To",
  value: sandalDestinationText,
  reasons: applicationReasons,
),
    ],
  );
}

File? get _mahazarFile {
  final updatedMahazars =
      generatedDocuments.where((file) {
    final name = file.path
        .split(Platform.pathSeparator)
        .last
        .toUpperCase();

    return name.contains("UPDATED_MAHAZAR");
  }).toList();

  if (updatedMahazars.isNotEmpty) {
    return updatedMahazars.first;
  }

  final mahazars =
      generatedDocuments.where((file) {
    final name = file.path
        .split(Platform.pathSeparator)
        .last
        .toUpperCase();

    return name.contains("MAHAZAR");
  }).toList();

  if (mahazars.isNotEmpty) {
    return mahazars.first;
  }

  return null;
}

Future<void> _openMahazar() async {
  final file = _mahazarFile;

  if (file == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Generated Mahazar is not available.",
        ),
      ),
    );
    return;
  }

  await documentService.refreshOfficerAddresses(file);
    await OpenFilex.open(file.path);
}

Widget _buildMahazarApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final file = _mahazarFile;

  final isUpdated = file != null &&
      file.path
          .split(Platform.pathSeparator)
          .last
          .toUpperCase()
          .contains("UPDATED_MAHAZAR");

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Mahazar Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      _approvalCard(
  itemKey: "MAHAZAR",
  title: isUpdated
      ? "Updated Mahazar"
      : "Mahazar",
  value: file == null
      ? "Generated Mahazar is not available"
      : "Generated Mahazar is available",
  reasons: applicationReasons,
  onView: file == null
      ? null
      : _openMahazar,
  modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text(
        "Edit Mahazar Details",
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (routeContext) =>
                MahazarStep(
              application:
                  widget.application,
              onBack: () {
                Navigator.pop(
                  routeContext,
                );
              },
              onNext: () {
                Navigator.pop(
                  routeContext,
                );
              },
            ),
          ),
        );

        final mahazar =
            await mahazarRepository
                .getByApplication(
          widget.application.id!,
        );

        if (mahazar != null) {
          await documentService.generateMahazar(
            widget.application,
            mahazar,
            isUpdated: true,
          );
        }

        generatedDocuments =
            await documentService
                .getGeneratedDocuments(
          widget.application.officeNumber,
        );

        if (mounted) {
          setState(() {});
        }
      },
    ),
  ),
),
    ],
  );
}

Widget _buildRevenueOpinionApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final opinion = selectedRevenueOpinion;

  final value = opinion == null
      ? "No Revenue Opinion selected"
      : [
          opinion.revenueOpinion,
          if (opinion.officeName.trim().isNotEmpty)
            opinion.officeName,
          if (opinion.officeAddress.trim().isNotEmpty)
            opinion.officeAddress,
          if (opinion.remarks.trim().isNotEmpty)
            opinion.remarks,
        ].join("\n");

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Revenue Opinion Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      _approvalCard(
  itemKey: "REVENUE_OPINION",
  title: "Revenue Opinion",
  value: value,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: revenueOpinionOptions.any(
      (option) =>
          option.id ==
          selectedRevenueOpinion?.id,
    )
        ? selectedRevenueOpinion?.id
        : null,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: "Revenue Opinion",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: revenueOpinionOptions.map(
      (option) {
        final displayText = [
          option.revenueOpinion,
          if (option.officeName
              .trim()
              .isNotEmpty)
            option.officeName,
        ].join(" - ");

        return DropdownMenuItem<int>(
          value: option.id,
          child: Text(
            displayText,
            overflow:
                TextOverflow.ellipsis,
          ),
        );
      },
    ).toList(),
    onChanged:
        _saveModifiedRevenueOpinion,
  ),
),
    ],
  );
}

Widget _buildDeferredApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final deferredText =
      selectedDeferredReasons.isEmpty
          ? "No deferred reasons found."
          : selectedDeferredReasons
              .map(
                (reason) =>
                    reason["reasonName"]
                        ?.toString()
                        .trim() ??
                    "",
              )
              .where(
                (reason) => reason.isNotEmpty,
              )
              .map(
                (reason) => "• $reason",
              )
              .join("\n");

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Deferred Reasons Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

      _approvalCard(
        itemKey: "DEFERRED",
        title: "Deferred Inspection",
        value: deferredText,
        reasons:
            deferredVerificationReasons,
        modifyField: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text(
              "Edit Deferred Reasons",
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (routeContext) =>
                      InspectionDecisionStep(
                    application:
                        widget.application,
                    onBack: () {
                      Navigator.pop(
                        routeContext,
                      );
                    },
                    onNext: () {
                      Navigator.pop(
                        routeContext,
                      );
                    },
                    onDeferred: () {
                      Navigator.pop(
                        routeContext,
                      );
                    },
                  ),
                ),
              );

              await _loadApprovals();

              if (mounted) {
                setState(() {});
              }
            },
          ),
        ),
      ),
    ],
  );
}

Widget _buildRtcTreeCountApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final applicationId =
      widget.application.id;

  if (applicationId == null) {
    return const Center(
      child: Text(
        "RTC tree-count details are not available.",
      ),
    );
  }

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "RTC Tree Count Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

      TreeCountSummaryCard(
        applicationId: applicationId,
      ),

      const SizedBox(height: 12),

      _approvalCard(
  itemKey: "TREE_COUNT",
  title: "RTC Tree Count",
  value:
      "Verify the complete RTC site-wise "
      "species and tree-count details shown above.",
  reasons: treeReasons,
  modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text(
        "Edit RTC Tree Count",
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TreeCountHomeScreen(
              applicationId:
                  widget.application.id!,
            ),
          ),
        );

        if (mounted) {
          setState(() {});
        }
      },
    ),
  ),
),
    ],
  );
}

Widget _buildTreeApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  if (trees.isEmpty) {
    return const Center(
      child: Text(
        "No trees available for approval.",
      ),
    );
  }

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Tree-wise Approval",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      TreeInspectionTable(
        trees: trees,
        speciesMap: speciesMap,
        treeStatusMap: treeStatusMap,
        recommendationTypeMap:
            recommendationTypeMap,
        recommendationReasonMap:
            recommendationReasonMap,
        showVerification: true,
        verificationBuilder: (tree) {
          return _approvalCard(
  itemKey: "TREE",
  itemId: tree.id!,
  title:
      "Tree ${tree.treeNumber}",
  value:
      speciesMap[tree.speciesId] ??
          "-",
reasons: treeReasons,
verticalOptions: true,
modifyField: Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text(
        "Edit Tree",
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddEditTreeScreen(
              tree: tree,
              isEdit: true,
            ),
          ),
        );

        if (!mounted) return;

        setState(() {
          loadingApprovals = true;
        });

        await _loadApprovals();

        // Tree edits can flip the all-NR/deferred state, which
        // controls the To-recipient section on the final page.
        await _loadDeferredRfoRecipients();

await _regenerateRfoUpdatedMahazar();

if (mounted) {
  setState(() {});
}

      },
    ),
  ),
);
        },
      ),
    ],
  );
}

Widget _buildOverallRemarksApprovalPage() {
  if (loadingApprovals) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        "Inspecting Officer's Overall Remarks",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
     _approvalCard(
  itemKey: "OVERALL_REMARK",
  title: "Overall Remarks",
  value: overallRemarkDisplay,
  reasons: applicationReasons,
  modifyField:
      DropdownButtonFormField<int>(
    value: overallRemarkOptions.any(
      (item) =>
          item["id"] ==
          widget.application
              .overallRemarkId,
    )
        ? widget.application.overallRemarkId
        : null,
    decoration: const InputDecoration(
      labelText:
          "Inspecting Officer's Overall Remarks",
      border: OutlineInputBorder(),
      isDense: true,
    ),
    items: overallRemarkOptions.map(
      (item) {
        return DropdownMenuItem<int>(
          value: item["id"] as int,
          child: Text(
            item["value"]
                    ?.toString() ??
                "",
          ),
        );
      },
    ).toList(),
    onChanged: (selectedId) async {
      if (selectedId == null) return;

      final selectedItem =
          overallRemarkOptions.firstWhere(
        (item) =>
            item["id"] == selectedId,
      );

      widget.application.overallRemarkId =
          selectedId;

      widget.application.overallRemarks =
          selectedItem["value"]
                  ?.toString() ??
              "";

      await _saveRfoModifiedApplication();
    },
  ),
),
    ],
  );
}

Map<String, dynamic>? _deferredRecipientOption(
  String key,
) {
  for (final option
      in deferredRfoRecipientOptions) {
    if (option["key"] == key) {
      return option;
    }
  }

  return null;
}

Widget _buildRfoFinalDecisionPage() {
  if (needsGovernmentFinal) return _governmentFinalPage();
  if (!needsDeferredRfoRecipientSelection) {
    return Center(
      child: Text(
        needsBranchPermission
            ? "Final Approval\nRFO Private Land Branch Permission Letter"
            : "Final Approval",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  if (loadingDeferredRfoRecipients) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final isForwarded =
      widget.application.applicationSource
          .trim()
          .toUpperCase() ==
      "FORWARDED";

  final primaryOption =
      selectedDeferredRfoToKey == null
          ? null
          : _deferredRecipientOption(
              selectedDeferredRfoToKey!,
            );

  final availableCopyOptions =
      deferredRfoRecipientOptions.where(
    (option) {
      final key =
          option["key"]?.toString() ?? "";

      return key.isNotEmpty &&
          key != selectedDeferredRfoToKey &&
          !selectedDeferredRfoCopyKeys
              .contains(key);
    },
  ).toList();

  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        "Final Decision",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 20),

      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "Document to be generated",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
  allTreesNotRecommended
      ? "Non-RTC Not Recommended RFO Letter"
      : "Non-RTC Deferred RFO Letter",
),
              const SizedBox(height: 18),

              if (!isForwarded)
                InputDecorator(
                  decoration:
                      const InputDecoration(
                    labelText: "To",
                    border:
                        OutlineInputBorder(),
                  ),
                  child: Text(
                    primaryOption?["label"]
                            ?.toString() ??
                        "Applicant",
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedDeferredRfoToKey,
                  decoration:
                      const InputDecoration(
                    labelText: "To",
                    border:
                        OutlineInputBorder(),
                  ),
                  items:
                      deferredRfoRecipientOptions
                          .map(
                    (option) {
                      final key =
                          option["key"]
                              .toString();

                      return DropdownMenuItem<
                          String>(
                        value: key,
                        child: Text(
                          option["label"]
                                  ?.toString() ??
                              "",
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDeferredRfoToKey =
                          value;

                      if (value != null) {
                        selectedDeferredRfoCopyKeys
                            .remove(value);
                      }
                    });
                  },
                ),

              if (isForwarded) ...[
                const SizedBox(height: 18),

                if (availableCopyOptions
                    .isNotEmpty)
                 DropdownButtonFormField<
    String>(
  key: ValueKey(
    "rfo_copy_${selectedDeferredRfoToKey ?? 'none'}_"
    "${selectedDeferredRfoCopyKeys.join('_')}",
  ),
  value: null,
                    decoration:
                        const InputDecoration(
                      labelText: "Add Copy To",
                      border:
                          OutlineInputBorder(),
                    ),
                    hint: const Text(
                      "Select recipient",
                    ),
                    items: availableCopyOptions
                        .map(
                      (option) {
                        final key =
                            option["key"]
                                .toString();

                        return DropdownMenuItem<
                            String>(
                          value: key,
                          child: Text(
                            option["label"]
                                    ?.toString() ??
                                "",
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        if (!selectedDeferredRfoCopyKeys
                            .contains(value)) {
                          selectedDeferredRfoCopyKeys
                              .add(value);
                        }
                      });
                    },
                  ),

                if (selectedDeferredRfoCopyKeys
                    .isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    "Copies selected",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        selectedDeferredRfoCopyKeys
                            .map(
                      (key) {
                        final option =
                            _deferredRecipientOption(
                          key,
                        );

                        return Chip(
                          label: Text(
                            option?["label"]
                                    ?.toString() ??
                                key,
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedDeferredRfoCopyKeys
                                  .remove(key);
                            });
                          },
                        );
                      },
                    ).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {

final approvalPages = <Widget>[
  _buildInspectionSummaryPage(),

  if (isDeferredApplication)
    _buildDeferredApprovalPage()
  else ...[
    _buildApplicationApprovalPage(),
    _buildEvidenceApprovalPage(),

    if (isRtcApplication)
      _buildRtcTreeCountApprovalPage()
    else
      _buildTreeApprovalPage(),

    if (needsRevenueOpinion)
      _buildRevenueOpinionApprovalPage(),

    if (needsMahazar)
      _buildMahazarApprovalPage(),

    if (!isRtcApplication)
      _buildOverallRemarksApprovalPage(),
  ],

  _buildRfoFinalDecisionPage(),
];

    return Scaffold(

      appBar: AppBar(

        centerTitle: true,

        title: const Text(

          "RFO Final Decision",

        ),

      ),

      body: Column(

        children: [

          Container(

            width: double.infinity,

            padding:
                const EdgeInsets.all(16),

            color: Colors.green.shade50,

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  widget.application.officeNumber,

                  style: const TextStyle(

                    fontWeight:
                        FontWeight.bold,

                    fontSize: 20,

                  ),

                ),

                const SizedBox(height: 6),

                Text(
                  "Applicant : ${widget.application.applicantName}",
                ),

                Text(
                  "Section : ${widget.application.section}",
                ),

                Text(
                  "Beat : ${widget.application.beat}",
                ),

                Text(
                  "Application Type : ${widget.application.applicationType}",
                ),

              ],

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

              children: approvalPages,

            ),

          ),

          Container(

            padding:
                const EdgeInsets.all(15),

            child: Row(

              children: [

                if (currentPage > 0)

                  ElevatedButton(

                    onPressed: () {

                      pageController.previousPage(

                        duration:
                            const Duration(

                          milliseconds: 300,

                        ),

                        curve:
                            Curves.easeInOut,

                      );

                    },

                    child: const Text(

                      "Previous",

                    ),

                  ),

                const Spacer(),

                if (currentPage < approvalPages.length - 1)

                  ElevatedButton(

                    onPressed: () {

                      pageController.nextPage(

                        duration:
                            const Duration(

                          milliseconds: 300,

                        ),

                        curve:
                            Curves.easeInOut,

                      );

                    },

                    child: const Text(

                      "Next",

                    ),

                  )
                                 
                                 else
  Expanded(
    child: ResponsiveActions(
    children: [
      OutlinedButton.icon(
        icon: const Icon(
          Icons.save,
        ),
        label: const Text(
          "SAVE DRAFT",
        ),
        onPressed: _saveRfoDraft,
      ),

      if (_hasRfoReinspection) ...[
        ElevatedButton.icon(
          icon: const Icon(
            Icons.reply,
          ),
          label: const Text(
            "SEND FOR RE-INSPECTION",
          ),
          onPressed: _finalizeRfoApproval,
        ),
      ] else if (_allRfoItemsApproved) ...[
        ElevatedButton.icon(
          icon: Icon(
  needsRevenueOpinionRequest
      ? Icons.request_page
      : Icons.verified,
),
label: Text(
  needsRevenueOpinionRequest
      ? "GET REVENUE OPINION"
      : "FINAL APPROVAL",
),
                    onPressed:
              _deferredRfoRecipientReady && !governmentBusy
                  ? _finalizeRfoApproval
                  : null,
        ),
      ],
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