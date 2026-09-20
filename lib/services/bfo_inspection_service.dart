import '../models/application_model.dart';
import '../repositories/inspection_defer_reason_repository.dart';
import 'workflow_service.dart';

class BFOInspectionService {
  final WorkflowService _workflowService =
      WorkflowService();

  final InspectionDeferredReasonRepository
      _reasonRepository =
          InspectionDeferredReasonRepository();

  Future<void> saveDraft(
      ApplicationModel application) async {

    await _workflowService.saveDraft(application);

    await _reasonRepository.saveReasons(
      applicationId: application.id!,
      reasons: application.deferredReasonIds
          .map((id) => {"id": id})
          .toList(),
    );
  }

  Future<void> submit(
      ApplicationModel application) async {

    await _workflowService.submitToDRFO(
      application,
    );

    await _reasonRepository.saveReasons(
      applicationId: application.id!,
      reasons: application.deferredReasonIds
          .map((id) => {"id": id})
          .toList(),
    );
  }
}