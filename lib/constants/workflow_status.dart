class WorkflowStatus {
  WorkflowStatus._();

  static const draft = "Draft";

  static const pendingDRFOAssignment =
      "Pending DRFO Assignment";

  static const pendingBFOInspection =
      "Pending BFO Inspection";

  static const pendingDRFOSelfInspection =
      "Pending DRFO Self Inspection";

static const pendingDRFOReSelfInspection =
    "Pending DRFO Re-Self Inspection";

  static const pendingDRFOVerification =
      "Pending DRFO Verification";

  static const pendingRFOApproval =
      "Pending RFO Approval";

  static const pendingRevenueOpinion =
    "Pending Revenue Opinion";

  static const pendingGovernmentLandApprovals = "Pending Government land approvals";

  static const approved = "Approved";

  static const completed = "Completed";

  static const rejected = "Rejected";

  static const returnedToCaseWorker =
      "Returned to Case Worker";

  static const returnedToBFO =
      "Returned to BFO";

  static const returnedToDRFO =
      "Returned to DRFO";

  static const returnedByRFO =
      "Returned by RFO";
}