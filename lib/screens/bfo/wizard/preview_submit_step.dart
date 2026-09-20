import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

import '../../../constants/workflow_status.dart';
import '../../../models/application_model.dart';

import '../../../repositories/application_repository.dart';
import '../../../repositories/document_repository.dart';
import '../../../repositories/history_repository.dart';
import '../../../repositories/photo_repository.dart';
import '../../../repositories/tree_repository.dart';

import '../../../services/bfo_inspection_service.dart';
import '../../../services/drfo_document_service.dart';
import '../../../repositories/mahazar_repository.dart';

class PreviewSubmitStep extends StatefulWidget {

  final ApplicationModel application;

  final VoidCallback onBack;

  final bool isDRFOSelfInspection;

  const PreviewSubmitStep({

    super.key,

    required this.application,

    required this.onBack,

    this.isDRFOSelfInspection = false,

  });

  @override
  State<PreviewSubmitStep> createState() =>
      _PreviewSubmitStepState();

}

class _PreviewSubmitStepState
    extends State<PreviewSubmitStep> {

  final BFOInspectionService
      _bfoInspectionService =
          BFOInspectionService();

  final ApplicationRepository
      applicationRepository =
          ApplicationRepository();

  final HistoryRepository historyRepo =
      HistoryRepository();

  final TreeRepository treeRepo =
      TreeRepository();

  final PhotoRepository photoRepo =
      PhotoRepository();

  final DocumentRepository documentRepo =
      DocumentRepository();

        final MahazarRepository mahazarRepo =
      MahazarRepository();

  final DrfoDocumentService documentService =
      DrfoDocumentService();

  bool allTreesNotRecommended = false;
  bool submitting = false;
  bool submitted = false;

  File? generatedMahazar;

  int totalTrees = 0;
  int totalPhotos = 0;
  int totalDocuments = 0;

  bool get isRTC {
    final type = widget.application.applicationType
        .trim()
        .toUpperCase();

    return type == "RTC" ||
        widget.application.permissionType ==
            "Tree Count";
  }

  bool get isDeferred =>
      widget.application.inspectionDecision
          .trim()
          .toUpperCase() ==
      "DEFERRED";

  bool get requiresMahazar =>
      !isRTC &&
      !isDeferred &&
      totalTrees > 0 &&
      !allTreesNotRecommended;

  @override
  void initState() {

    super.initState();

    loadSummary();

  }

  Future<void> loadSummary() async {

    totalTrees =
        await treeRepo.totalTrees(
      widget.application.id!,
    );

        if (!isRTC && totalTrees > 0) {
      allTreesNotRecommended =
          await treeRepo.areAllTreesNotRecommended(
        widget.application.id!,
      );
    } else {
      allTreesNotRecommended = false;
    }

    totalPhotos =
        await photoRepo.totalPhotos(
      widget.application.id!,
    );

    totalDocuments =
        await documentRepo.totalDocuments(
      widget.application.id!,
    );

    if (mounted) {

      setState(() {});

    }

  }

 Future<void> saveDraft() async {

  if (widget.isDRFOSelfInspection) {

    widget.application.status =
        WorkflowStatus.pendingDRFOSelfInspection;

    await applicationRepository.updateApplication(
      widget.application,
    );

    await historyRepo.addHistory(

      officeNumber:
          widget.application.officeNumber,

      action: "Draft Saved",

      remarks:
          "DRFO Self Inspection Draft Saved.",

      actionBy: "DRFO",

    );

  } else {

    await _bfoInspectionService.saveDraft(
      widget.application,
    );

  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

    const SnackBar(

      content: Text(
        "Inspection Draft Saved Successfully",
      ),

    ),

  );

  Navigator.pop(context);

}

Future<void> submitToDRFO() async {
    if (submitting || submitted) return;

  if (widget.application.inspectionDecision.isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Please complete Inspection Decision.",
        ),

      ),

    );

    return;

  }

  // ===========================
  // Deferred Inspection
  // ===========================

  if (widget.application.inspectionDecision ==
      "DEFERRED") {

    if (widget.isDRFOSelfInspection) {

      widget.application.status =
          WorkflowStatus.pendingDRFOVerification;

      widget.application.drfoInspectionDate =
          DateTime.now().toIso8601String();

      await applicationRepository
          .updateApplication(
        widget.application,
      );

      await historyRepo.addHistory(

        officeNumber:
            widget.application.officeNumber,

        action:
            "DRFO Self Inspection Completed",

        remarks:
            "DRFO self inspection completed and sent for verification.",

        actionBy: "DRFO",

      );

    } else {

      await _bfoInspectionService.submit(
        widget.application,
      );

    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(

          widget.isDRFOSelfInspection

              ? "Application Submitted for DRFO Verification"

              : "Deferred inspection submitted to DRFO",

        ),

      ),

    );

    Navigator.pop(context);

    return;

  }

  // ===========================
  // Normal Inspection Validation
  // ===========================

  if (widget.application.gpsCoordinates.isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Please capture GPS.",
        ),

      ),

    );

    return;

  }

  if (widget.application.permissionType !=
        "Tree Count" &&
    totalTrees == 0) {

  ScaffoldMessenger.of(context).showSnackBar(

    const SnackBar(

      content: Text(
        "Please inspect at least one tree.",
      ),

    ),

  );

  return;

}

  File? mahazarFile;

  if (requiresMahazar) {
    setState(() {
      submitting = true;
    });

    try {
      final mahazar =
          await mahazarRepo.getByApplication(
        widget.application.id!,
      );

      if (mahazar == null) {
        if (mounted) {
          setState(() {
            submitting = false;
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Mahazar details are not available. "
                "Please go back and complete Mahazar entry.",
              ),
            ),
          );
        }

        return;
      }

      mahazarFile =
          await documentService.generateMahazar(
        widget.application,
        mahazar,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          submitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Mahazar generation failed: $error",
            ),
          ),
        );
      }

      return;
    }
  }

  // ===========================
  // Submit
  // ===========================

  if (widget.isDRFOSelfInspection) {

    widget.application.status =
        WorkflowStatus.pendingDRFOVerification;

    widget.application.drfoInspectionDate =
        DateTime.now().toIso8601String();

    await applicationRepository
        .updateApplication(
      widget.application,
    );

    await historyRepo.addHistory(

      officeNumber:
          widget.application.officeNumber,

      action:
          "DRFO Self Inspection Completed",

      remarks:
          "DRFO self inspection completed and sent for verification.",

      actionBy: "DRFO",

    );

  } else {

    await _bfoInspectionService.submit(
      widget.application,
    );

  }

  if (!mounted) return;

  setState(() {
    generatedMahazar = mahazarFile;
    submitted = true;
    submitting = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        mahazarFile != null
            ? "Mahazar generated and application "
                "submitted for DRFO Verification"
            : widget.isDRFOSelfInspection
                ? "Application Submitted for "
                    "DRFO Verification"
                : "Application Submitted to DRFO",
      ),
    ),
  );

  // Keep this page open when a Mahazar was generated,
  // allowing the inspecting officer to view or print it.
  if (mahazarFile == null) {
    Navigator.pop(context);
  }

}

 @override
Widget build(BuildContext context) {

  return Scaffold(

    appBar: AppBar(

      title: const Text(
        "Preview & Submit",
      ),

    ),

   body: SingleChildScrollView(

      padding: const EdgeInsets.all(15),

      child: Column(

        children: [

          Card(

            child: Padding(

              padding: const EdgeInsets.all(15),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    "Office No : ${widget.application.officeNumber}",

                  ),

                  Text(

                    "Applicant : ${widget.application.applicantName}",

                  ),

                  Text(

                    "Application Type : ${widget.application.applicationType}",

                  ),

                  const Divider(),

                  ListTile(

                    leading: Icon(

                      widget.application.gpsCoordinates
                              .isEmpty
                          ? Icons.close
                          : Icons.check_circle,

                      color:
                          widget.application.gpsCoordinates
                                  .isEmpty
                              ? Colors.red
                              : Colors.green,

                    ),

                    title: const Text(
                      "GPS Captured",
                    ),

                  ),

                  ListTile(

                    leading: Icon(

                      totalTrees == 0
                          ? Icons.close
                          : Icons.check_circle,

                      color: totalTrees == 0
                          ? Colors.red
                          : Colors.green,

                    ),

                    title: Text(
                      "Trees : $totalTrees",
                    ),

                  ),

                  ListTile(

                    leading: Icon(

                      totalPhotos == 0
                          ? Icons.warning
                          : Icons.check_circle,

                      color: totalPhotos == 0
                          ? Colors.orange
                          : Colors.green,

                    ),

                    title: Text(
                      "Photos : $totalPhotos",
                    ),

                  ),

                  ListTile(

                    leading: Icon(

                      totalDocuments == 0
                          ? Icons.warning
                          : Icons.check_circle,

                      color: totalDocuments == 0
                          ? Colors.orange
                          : Colors.green,

                    ),

                    title: Text(
                      "Documents : $totalDocuments",
                    ),

                  ),

                ],

              ),

            ),

          ),

const SizedBox(height: 30),

Row(

  children: [

    Expanded(

      child: ElevatedButton(

        onPressed: widget.onBack,

        child: const Text(
          "BACK",
        ),

      ),

    ),

    const SizedBox(width: 15),

    Expanded(

      child: ElevatedButton(

        onPressed: saveDraft,

        child: const Text(
          "SAVE DRAFT",
        ),

      ),

    ),

  ],

),

const SizedBox(height: 15),

SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton(
    onPressed:
        submitting || submitted
            ? null
            : submitToDRFO,
    child: submitting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : Text(
            requiresMahazar
                ? "GENERATE MAHAZAR AND SUBMIT FOR DRFO VERIFICATION"
                : widget.isDRFOSelfInspection
                    ? "SUBMIT FOR DRFO VERIFICATION"
                    : "SUBMIT TO DRFO",
          ),
  ),
),

if (generatedMahazar != null) ...[
  const SizedBox(height: 15),

  Card(
    color: Colors.green.shade50,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Mahazar generated and application submitted for DRFO verification.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.visibility,
                  ),
                  label: const Text(
                    "VIEW MAHAZAR",
                  ),
                  onPressed: () async {
                    await OpenFilex.open(
                      generatedMahazar!.path,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.print,
                  ),
                  label: const Text(
                    "PRINT MAHAZAR",
                  ),
                  onPressed: () async {
                    await documentService.openPdf(
                      generatedMahazar!,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
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
  ),
],

      ],

    ),

  ),

);

}

}