import '../../../widgets/revenue_reply_history_card.dart';
import '../../../widgets/responsive_actions.dart';
import '../../../widgets/government_approval_history_card.dart';
import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../repositories/document_repository.dart';
import '../../../repositories/photo_repository.dart';
import '../../../repositories/tree_repository.dart';
import '../../../repositories/master_repository.dart';
import '../../../repositories/inspection_defer_reason_repository.dart';
import '../../../models/tree_model.dart';
import '../../../models/photo_model.dart';
import '../../../models/document_model.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../../../widgets/tree_inspection_table.dart';
import '../../../repositories/mahazar_repository.dart';
import '../../../models/mahazar_model.dart';
import '../../../repositories/tree_count_site_repository.dart';
import '../../../repositories/tree_count_detail_repository.dart';
import '../../../models/tree_count_site_model.dart';
import '../../../models/tree_count_detail_model.dart';
import '../tree/tree_count_summary_card.dart';
import '../../../repositories/application_revenue_opinion_repository.dart';
import '../../../repositories/revenue_opinion_repository.dart';
import '../../../models/application_revenue_opinion_model.dart';
import '../../../models/revenue_opinion_model.dart';


class InspectionSummaryStep extends StatefulWidget {

  final bool showNavigationButtons;

  final ApplicationModel application;

  final VoidCallback onBack;

  final VoidCallback onNext;

  const InspectionSummaryStep({
  super.key,
  required this.application,
  required this.onBack,
  required this.onNext,
  this.showNavigationButtons = true,
});

  @override
  State<InspectionSummaryStep> createState() =>
      _InspectionSummaryStepState();
}

class _InspectionSummaryStepState
    extends State<InspectionSummaryStep> {

  final TreeRepository treeRepository = TreeRepository();
final PhotoRepository photoRepository = PhotoRepository();
final DocumentRepository documentRepository =
    DocumentRepository();
final MasterRepository masterRepository =
    MasterRepository();
final InspectionDeferredReasonRepository
    deferredRepository =
        InspectionDeferredReasonRepository();
        final MahazarRepository mahazarRepository =
    MahazarRepository();

MahazarModel? mahazar;
ApplicationRevenueOpinionModel? revenueSelection;

RevenueOpinionModel? revenueOpinion;

List<TreeModel> trees = [];
List<PhotoModel> photos = [];
List<DocumentModel> documents = [];
List<TreeCountSiteModel> treeCountSites = [];

Map<int, List<TreeCountDetailModel>>
    treeCountDetails = {};
List<Map<String, dynamic>> deferredReasons = [];

Map<int, String> speciesMap = {};
Map<int, String> recommendationTypeMap = {};

Map<int, String> recommendationReasonMap = {};
Map<int, String> treeStatusMap = {};
Map<int, String> applicationDetailMasterMap = {};
String selectedWhyRemovingCode = "";

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  @override
  void didUpdateWidget(
    covariant InspectionSummaryStep oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Refresh application-related master values and all
    // inspection records after DRFO modifies any field.
    loadSummary();
  }

  Future<void> loadSummary() async {

  trees = await treeRepository.getTrees(
    widget.application.id!,
  );

  photos = await photoRepository.getPhotos(
    widget.application.id!,
  );

  documents = await documentRepository.getDocuments(
    widget.application.id!,
  );

revenueSelection =
    await ApplicationRevenueOpinionRepository()
        .getByApplication(
  widget.application.id!,
);

if (revenueSelection != null) {

  revenueOpinion =
      await RevenueOpinionRepository()
          .getById(
    revenueSelection!.revenueOpinionId,
  );

}

  if (widget.application.permissionType !=
    "Tree Count") {

  mahazar =
      await mahazarRepository.getByApplication(
    widget.application.id!,
  );

}

if (widget.application.permissionType ==
    "Tree Count") {

  final siteRepo =
      TreeCountSiteRepository();

  final detailRepo =
      TreeCountDetailRepository();

  treeCountSites =
      await siteRepo.getSites(
    widget.application.id!,
  );

  treeCountDetails.clear();

  for (final site in treeCountSites) {

    treeCountDetails[site.id!] =
        await detailRepo.getBySite(
  site.id!,
);

  }

}

  deferredReasons =
      await deferredRepository.getReasons(
    widget.application.id!,
  );

final species =
    await masterRepository.getSpecies();

speciesMap = {
  for (final item in species)
    item["id"] as int:
        item["value"].toString(),
};

//----------------------------------------------------------
// Recommendation Types
//----------------------------------------------------------

final recommendationTypes =
    await masterRepository.getMasters(
  "Recommendation Type",
);

recommendationTypeMap = {

  for (final item in recommendationTypes)

    item["id"] as int:
        item["value"].toString(),

};

//----------------------------------------------------------
// Recommendation Reasons
//----------------------------------------------------------

final recommendationReasons =
    await masterRepository.getMasters(
  "Recommendation Reason",
);

recommendationReasonMap = {
  for (final item in recommendationReasons)
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

final applicationDetailMasterTypes = <String>[
  "Government Agency",
  "Urban Rural",
  "Why Removing",
  "Purpose",
  "Structure Type",
  "Mahazar Location",
];

applicationDetailMasterMap.clear();

for (final masterType in applicationDetailMasterTypes) {
  final items =
      await masterRepository.getMasters(masterType);

  for (final item in items) {
    final id = item["id"] as int?;
    final value =
        item["value"]?.toString().trim() ?? "";

    if (id != null && value.isNotEmpty) {
      applicationDetailMasterMap[id] = value;

      if (masterType == "Why Removing" &&
          id == widget.application.whyRemovingId) {
        selectedWhyRemovingCode =
            item["code"]?.toString().trim().toUpperCase() ?? "";
      }
    }
  }
}

  if (mounted) {
    setState(() {});
  }
}

String get applicationTypeCode =>
    widget.application.applicationType
        .trim()
        .toUpperCase();

bool get isRtcApplication =>
    applicationTypeCode == "RTC";

bool get needsAdditionalDetails =>
    applicationTypeCode == "GL" ||
    applicationTypeCode == "STGL" ||
    applicationTypeCode == "CGL" ||
    applicationTypeCode == "SGL" ||
    applicationTypeCode == "PL" ||
    applicationTypeCode == "SPL";

bool get isGovernmentApplication =>
    applicationTypeCode == "GL" ||
    applicationTypeCode == "STGL" ||
    applicationTypeCode == "CGL" ||
    applicationTypeCode == "SGL";

bool get showNameOfWork =>
    selectedWhyRemovingCode == "WORKS";

String masterDisplayValue(int? id) {
  if (id == null) return "-";

  final value =
      applicationDetailMasterMap[id]?.trim() ?? "";

  return value.isEmpty ? "-" : value;
}

String mahazarBoundaryDisplay(
  int? locationId,
  String additionalText,
) {
  final location = masterDisplayValue(locationId);
  final details = additionalText.trim();

  if (details.isEmpty) return location;
  if (location == "-") return details;

  return "$location - $details";
}

  Widget buildTreeInspectionCard({
  bool showVerification = false,
}) {

  return Card(

    child: Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Tree Inspection",

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),

          const Divider(),

          if (trees.isEmpty)

            const Padding(

              padding: EdgeInsets.all(20),

              child: Center(

                child: Text(
                  "No Trees Added",
                ),

              ),

            )

          else

            TreeInspectionTable(
  trees: trees,
  speciesMap: speciesMap,
  treeStatusMap: treeStatusMap,
  recommendationTypeMap: recommendationTypeMap,
  recommendationReasonMap: recommendationReasonMap,
),

        ],

      ),

    ),

  );

}

Widget buildTreeCountCard() {

  return TreeCountSummaryCard(

    applicationId:
        widget.application.id!,

  );

}

Widget headerCell(
  String text,
) {

  return Padding(

    padding:
        const EdgeInsets.all(8),

    child: Text(

      text,

      textAlign:
          TextAlign.center,

      style: const TextStyle(

        fontWeight:
            FontWeight.bold,

      ),

    ),

  );

}

Widget tableCell(
  String text,
) {

  return Padding(

    padding:
        const EdgeInsets.all(8),

    child: Text(

      text,

      textAlign:
          TextAlign.center,

    ),

  );

}

//----------------------------------------------------------
// Recommendation Name
//----------------------------------------------------------

String _recommendationName(
    TreeModel tree) {

  return recommendationTypeMap[
          tree.recommendationTypeId] ??
      "-";

}

String _recommendationReasons(
    TreeModel tree) {

  if (tree.recommendationReasonIds
      .isEmpty) {

    return "-";

  }

  return tree.recommendationReasonIds

      .map((id) =>
          recommendationReasonMap[id] ??
          "")

      .where((e) => e.isNotEmpty)

      .join(", ");

}

Widget buildPhotoCard() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Inspection Photos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),

          Text("Total Photos : ${photos.length}"),

          const SizedBox(height: 12),

          if (photos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No Photos Added"),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: photos.map((photo) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return Dialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppBar(
                                automaticallyImplyLeading: false,
                                title: const Text("Photo Preview"),
                              ),
                              InteractiveViewer(
                                child: Image.file(
                                  File(photo.photoPath),
                                  fit: BoxFit.contain,
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
                        );
                      },
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photo.photoPath),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ),
  );
}

Widget buildDocumentCard() {

  return Card(

    child: Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Inspection Documents",

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),

          const Divider(),

          Text(
            "Total Documents : ${documents.length}",
          ),

          const SizedBox(height: 12),

          if (documents.isEmpty)

            const Padding(

              padding: EdgeInsets.all(20),

              child: Center(

                child: Text(
                  "No Documents Uploaded",
                ),

              ),

            )

          else

            Wrap(

              spacing: 12,

              runSpacing: 12,

              children: documents.map((doc) {

                return SizedBox(

                  width: 250,

                  child: Card(

                    elevation: 2,

                    child: Padding(

                      padding:
                          const EdgeInsets.all(12),

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const Row(

                            children: [

                              Icon(
                                Icons.description,
                                color: Colors.blue,
                              ),

                              SizedBox(width: 8),

                              Text(

                                "Document",

                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),

                              ),

                            ],

                          ),

                          const SizedBox(height: 10),

                          Text(

                            doc.documentTypeName,

                            style: const TextStyle(

                              fontWeight:
                                  FontWeight.bold,

                            ),

                          ),

                          const SizedBox(height: 6),

                          Text(

                            doc.remarks.isEmpty
                                ? "-"
                                : doc.remarks,

                          ),

                          const SizedBox(height: 10),

                          SizedBox(

                            width: double.infinity,

                            child: ElevatedButton.icon(

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

                        ],

                      ),

                    ),

                  ),

                );

              }).toList(),

            ),

        ],

      ),

    ),

  );

}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Inspection Summary",
        ),

      ),

      body: Padding(

        padding: const EdgeInsets.all(15),

        child: SingleChildScrollView(

  child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [
if (widget.application.id != null) RevenueReplyHistoryCard(applicationId: widget.application.id!),
if (widget.application.id != null) GovernmentApprovalHistoryCard(applicationId: widget.application.id!),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Application Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        Text(
          "Office No : ${widget.application.officeNumber}",
        ),
        Text(
          "Applicant : ${widget.application.applicantName}",
        ),
        Text(
          "Address : ${widget.application.applicantAddress}",
        ),
        Text(
          "Mobile : ${widget.application.mobile}",
        ),
        Text(
          "Application Type : ${widget.application.applicationType}",
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
),

const SizedBox(height: 12),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inspection Decision",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        Text(widget.application.inspectionDecision),
        if (widget.application.inspectionDecision == "DEFERRED") ...[
          const SizedBox(height: 10),
          const Text(
            "Reasons",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...deferredReasons.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("• ${e["reasonName"]}"),
            ),
          ),
        ],
      ],
    ),
  ),
),

const SizedBox(height: 12),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Application Type Verification",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        Text(
          "Application Type : ${widget.application.applicationType}",
        ),
        Text(
          "Verified As : ${widget.application.applicationType}",
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

if (needsAdditionalDetails)
  Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verified Application Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),

          Text(
            isGovernmentApplication
                ? "Government Agency : "
                    "${masterDisplayValue(widget.application.governmentAgencyId)}"
                : "Urban / Rural : "
                    "${masterDisplayValue(widget.application.urbanRuralId)}",
          ),

          Text(
            "Why Removing : "
            "${masterDisplayValue(widget.application.whyRemovingId)}",
          ),

          Text(
            "Purpose : "
            "${masterDisplayValue(widget.application.purposeId)}",
          ),

          Text(
            "Structure Type : "
            "${masterDisplayValue(widget.application.structureTypeId)}",
          ),

          if (showNameOfWork)
            Text(
              "Name of Work : "
              "${widget.application.workName.trim().isEmpty ? "-" : widget.application.workName}",
            ),
        ],
      ),
    ),
  ),

if (needsAdditionalDetails)
  const SizedBox(height: 12),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "GPS",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        Text(widget.application.gpsCoordinates),
      ],
    ),
  ),
),

const SizedBox(height: 12),

if (widget.application.permissionType ==
    "Tree Count")
  buildTreeCountCard()
else
  buildTreeInspectionCard(),

const SizedBox(height: 12),

buildPhotoCard(),

const SizedBox(height: 12),

buildDocumentCard(),

const SizedBox(height: 12),

if (revenueOpinion != null)

Card(

  child: Padding(

    padding: const EdgeInsets.all(16),

    child: Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          "Revenue Opinion",

          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),

        ),

        const Divider(),

        Text(
          revenueOpinion!.revenueOpinion,
        ),

      ],

    ),

  ),

),

const SizedBox(height: 12),

if (!isRtcApplication)
  Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Inspecting Officer's Overall Remarks",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Text(
            widget.application.overallRemarks.trim().isEmpty
                ? "-"
                : widget.application.overallRemarks,
          ),
        ],
      ),
    ),
  ),

if (!isRtcApplication)
  const SizedBox(height: 12),

if (widget.application.permissionType !=
        "Tree Count" &&
    mahazar != null)

  Card(

    child: Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Mahazar Details",

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),

          const Divider(),

          Text(
            "Mahazar Date : ${mahazar!.mahazarDate}",
          ),

          Text(
            "Starting Time : ${mahazar!.startTime}",
          ),

          Text(
            "Ending Time : ${mahazar!.endTime}",
          ),

          const SizedBox(height: 10),

          Text(
            "North : ${mahazarBoundaryDisplay(
              mahazar!.northLocationId,
              mahazar!.northBoundary,
            )}",
          ),

          Text(
            "East : ${mahazarBoundaryDisplay(
              mahazar!.eastLocationId,
              mahazar!.eastBoundary,
            )}",
          ),

          Text(
            "South : ${mahazarBoundaryDisplay(
              mahazar!.southLocationId,
              mahazar!.southBoundary,
            )}",
          ),

          Text(
            "West : ${mahazarBoundaryDisplay(
              mahazar!.westLocationId,
              mahazar!.westBoundary,
            )}",
          ),

        ],

      ),

    ),

  ),

const SizedBox(height: 20),

            if (widget.showNavigationButtons) ...[

  const SizedBox(height: 20),

  ResponsiveActions(

    children: [

      ElevatedButton(

          onPressed: widget.onBack,

          child: const Text("BACK"),

        ),



      ElevatedButton(

          onPressed: widget.onNext,

          child: const Text("NEXT"),

        ),


    ],

  ),

],

          ],

                ),

      ),

    ),

  );

  }
}