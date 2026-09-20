import 'package:flutter/material.dart';

import '../../../models/application_model.dart';

import 'application_details_step.dart';
import 'inspection_decision_step.dart';
import 'application_type_step.dart';
import 'application_additional_details_step.dart';
import './gps_step.dart';
import 'tree_step.dart';
import 'photo_step.dart';
import 'document_step.dart';
import 'inspection_summary_step.dart';
import 'preview_submit_step.dart';
import '../../../repositories/inspection_defer_reason_repository.dart';
import 'inspecting_officer_overall_remarks_step.dart';
import 'mahazar_step.dart';
import 'revenue_opinion_step.dart';
import '../../../repositories/tree_repository.dart';

class BFOWizardController extends StatefulWidget {

  final ApplicationModel application;

  const BFOWizardController({
    super.key,
    required this.application,
  });

  @override
  State<BFOWizardController> createState() =>
      _BFOWizardControllerState();
}

class _BFOWizardControllerState
    extends State<BFOWizardController> {

      final InspectionDeferredReasonRepository deferredRepository =
    InspectionDeferredReasonRepository();

  int currentStep = 0;
  final int totalSteps = 13;

  bool allTreesNotRecommended = false;
bool allTreesBranchOnly = false;

bool get isRtcApplication =>
    widget.application.applicationType
        .trim()
        .toUpperCase() ==
    'RTC';

bool get needsAdditionalDetails {
  final type = widget.application.applicationType
      .trim()
      .toUpperCase();

  return type == "GL" ||
      type == "STGL" ||
      type == "CGL" ||
      type == "SGL" ||
      type == "PL" ||
      type == "SPL";
}

bool get needsRevenueOpinion {
  final type = widget.application.applicationType
      .trim()
      .toUpperCase();

  return !isRtcApplication &&
      !allTreesNotRecommended &&
      !allTreesBranchOnly &&
      (type == 'PL' || type == 'SPL');
}

bool get needsMahazar {
  return !isRtcApplication &&
      !allTreesNotRecommended &&
      widget.application.permissionType != 'Tree Count';
}

Future<void> refreshTreeRequirements() async {
  final applicationId = widget.application.id;

  if (applicationId == null || isRtcApplication) {
    allTreesNotRecommended = false;
    allTreesBranchOnly = false;
    return;
  }

  allTreesNotRecommended = await TreeRepository()
      .areAllTreesNotRecommended(applicationId);
  allTreesBranchOnly = await TreeRepository().areAllTreesBranchOnly(applicationId);
}

  Future<void> nextStep() async {
  // Tree entry is now step 5.
  if (currentStep == 5) {
    await refreshTreeRequirements();

    if (!mounted) return;
  }

  int next = currentStep + 1;

  // Skip additional-detail verification for RTC and MCC.
  if (next == 3 && !needsAdditionalDetails) {
    next = 4;
  }

 if (next == 8 && !needsRevenueOpinion) {
  next = 9;
}

// RTC does not require overall remarks or Mahazar.
if (next == 9 && isRtcApplication) {
  next = 11;
}

// Other applications still show overall remarks,
// but Mahazar is skipped when it is not required.
if (next == 10 && !needsMahazar) {
  next = 11;
}

  if (next >= totalSteps) {
    return;
  }

  setState(() {
    currentStep = next;
  });
}

void jumpToPreviewSubmit() {

  setState(() {

    currentStep = 12;

  });

}

 void previousStep() {
 if (currentStep == 11 &&
    widget.application.inspectionDecision ==
        'DEFERRED') {
    setState(() {
      currentStep = 1;
    });
    return;
  }

  if (currentStep == 0) {
    return;
  }

  int previous = currentStep - 1;

  if (previous == 3 &&
      !needsAdditionalDetails) {
    previous = 2;
  }

 if (previous == 10 && !needsMahazar) {
  previous = 9;
}

if (previous == 9 && isRtcApplication) {
  previous = 8;
}

if (previous == 8 &&
    !needsRevenueOpinion) {
  previous = 7;
}

  setState(() {
    currentStep = previous;
  });
}

@override
void initState() {
  super.initState();
  loadDeferredReasons();
}

Future<void> loadDeferredReasons() async {
  if (widget.application.id == null) {
    return;
  }

  widget.application.deferredReasonIds =
      await deferredRepository.getReasonIds(
    widget.application.id!,
  );

  if (mounted) {
    setState(() {});
  }
}

  @override
  Widget build(BuildContext context) {

print(
  ">>> PermissionTypeId=${widget.application.permissionTypeId} "
  "PermissionType=${widget.application.permissionType}",
);

    switch(currentStep){

      case 0:

        return ApplicationDetailsStep(

          application: widget.application,

          onNext: nextStep,

        );

      case 1:

        return InspectionDecisionStep(

          application: widget.application,

          onNext: nextStep,

          onBack: previousStep,

          onDeferred: jumpToPreviewSubmit,

        );
        case 2:

return ApplicationTypeStep(

  application: widget.application,

  onBack: previousStep,

  onNext: nextStep,

);

case 3:
  return ApplicationAdditionalDetailsStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 4:
  return GPSStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 5:
  return TreeStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 6:
  return PhotoStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 7:
  return DocumentStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 8:
  return RevenueOpinionStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 9:
  return InspectingOfficerOverallRemarksStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 10:
  return MahazarStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 11:
  return InspectionSummaryStep(
    application: widget.application,
    onBack: previousStep,
    onNext: nextStep,
  );

case 12:
  return PreviewSubmitStep(
    application: widget.application,
    onBack: previousStep,
  );

      default:

        return const Scaffold(

          body: Center(

            child: Text(

              "Next Step Coming...",

              style: TextStyle(
                fontSize:22,
                fontWeight: FontWeight.bold,
              ),

            ),

          ),

        );

    }

  }

}