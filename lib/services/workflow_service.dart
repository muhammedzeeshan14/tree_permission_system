import '../models/application_model.dart';
import '../repositories/application_repository.dart';
import '../repositories/history_repository.dart';
import '../constants/workflow_status.dart';

class WorkflowService {
  final ApplicationRepository applicationRepository =
      ApplicationRepository();

  final HistoryRepository historyRepository =
      HistoryRepository();

  // ============================================================
  // DRFO → Assign Application to BFO
  // ============================================================
  Future<void> assignToBFO({
    required int applicationId,
    required int assignedBFO,
    required String officeNumber,
    required String actionBy,
  }) async {
    await applicationRepository.updateWorkflow(
      applicationId: applicationId,
      status: WorkflowStatus.pendingBFOInspection,
      inspectionMode: "BFO_INSPECTION",
      assignedBFO: assignedBFO,
    );

    await historyRepository.addHistory(
      officeNumber: officeNumber,
      action: "Assigned to BFO",
      remarks: "Application assigned by DRFO.",
      actionBy: actionBy,
    );
  }

Future<void> startDRFOSelfInspection({
  required int applicationId,
  required String officeNumber,
  required String actionBy,
}) async {
  await applicationRepository.updateWorkflow(
    applicationId: applicationId,
    status: WorkflowStatus.pendingDRFOSelfInspection,
    inspectionMode: "DRFO_SELF_INSPECTION",
    assignedBFO: 0,
  );

  await historyRepository.addHistory(
    officeNumber: officeNumber,
    action: "Self Inspection",
    remarks: "DRFO selected self inspection.",
    actionBy: actionBy,
  );
}

  // ============================================================
  // BFO → Save Draft
  // ============================================================
  Future<void> saveDraft(ApplicationModel application) async {
    application.status = WorkflowStatus.pendingBFOInspection;

    await applicationRepository.updateApplication(application);
  }

  // ============================================================
  // BFO → Submit to DRFO
  // ============================================================
  Future<void> submitToDRFO(ApplicationModel application) async {
    application.status = WorkflowStatus.pendingDRFOVerification;

    application.bfoVerificationDate =
        DateTime.now().toIso8601String();

    await applicationRepository.updateApplication(application);
  }

  // ============================================================
  // BFO → Start Inspection
  // ============================================================
  Future<void> startBFOInspection(
      ApplicationModel application) async {
    application.inspectionStarted = true;

    await applicationRepository.updateApplication(application);
  }

 // ============================================================
// DRFO → Return to BFO
// ============================================================
Future<void> returnToBFO({
  required ApplicationModel application,
  required String actionBy,
}) async {

  application.status =
      WorkflowStatus.returnedToBFO;

  await applicationRepository
      .updateApplication(application);

  await historyRepository.addHistory(
    officeNumber: application.officeNumber,
    action: "Returned to BFO",
    remarks:
        "Returned by DRFO for correction.",
    actionBy: actionBy,
  );
}

// ============================================================
// DRFO → Return to Self Inspection
// ============================================================
Future<void> returnToSelfInspection({
  required ApplicationModel application,
  required String actionBy,
}) async {

  application.status =
    WorkflowStatus.pendingDRFOReSelfInspection;

  await applicationRepository
      .updateApplication(application);

  await historyRepository.addHistory(
    officeNumber: application.officeNumber,
    action: "Returned to Self Inspection",
    remarks:
        "Returned by DRFO for self re-inspection.",
    actionBy: actionBy,
  );
}

// ============================================================
// DRFO → Forward to RFO
// ============================================================
Future<void> forwardToRFO({
  required ApplicationModel application,
  required String actionBy,
}) async {

  application.status =
      WorkflowStatus.pendingRFOApproval;

  await applicationRepository
      .updateApplication(application);

  await historyRepository.addHistory(
    officeNumber: application.officeNumber,
    action: "Forwarded to RFO",
    remarks:
        "Application verified and forwarded by DRFO.",
    actionBy: actionBy,
  );
}

}