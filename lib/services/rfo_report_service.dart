import '../constants/workflow_status.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

/// Stage buckets for the RFO monitoring reports.
///
/// Only applications actually created in the selected period are
/// counted (Draft rows are excluded).
class RfoReportBucket {
  int created = 0;
  int pendingAssignment = 0;
  int pendingBFO = 0;
  int pendingDRFOInspection = 0;
  int pendingDRFOVerification = 0;
  int pendingRevenue = 0;
  int pendingGovt = 0;
  int pendingRFO = 0;
  int returned = 0;
  int completed = 0;
  int rejected = 0;

  void add(String status) {
    created++;
    switch (status) {
      case WorkflowStatus.pendingDRFOAssignment:
        pendingAssignment++;
        break;
      case WorkflowStatus.pendingBFOInspection:
        pendingBFO++;
        break;
      case WorkflowStatus.pendingDRFOSelfInspection:
      case WorkflowStatus.pendingDRFOReSelfInspection:
        pendingDRFOInspection++;
        break;
      case WorkflowStatus.pendingDRFOVerification:
        pendingDRFOVerification++;
        break;
      case WorkflowStatus.pendingRevenueOpinion:
        pendingRevenue++;
        break;
      case WorkflowStatus.pendingGovernmentLandApprovals:
        pendingGovt++;
        break;
      case WorkflowStatus.pendingRFOApproval:
        pendingRFO++;
        break;
      case WorkflowStatus.returnedToCaseWorker:
      case WorkflowStatus.returnedToBFO:
      case WorkflowStatus.returnedToDRFO:
      case WorkflowStatus.returnedByRFO:
        returned++;
        break;
      case WorkflowStatus.approved:
      case WorkflowStatus.completed:
        completed++;
        break;
      case WorkflowStatus.rejected:
        rejected++;
        break;
      default:
        break;
    }
  }

  void addBucket(RfoReportBucket other) {
    created += other.created;
    pendingAssignment += other.pendingAssignment;
    pendingBFO += other.pendingBFO;
    pendingDRFOInspection += other.pendingDRFOInspection;
    pendingDRFOVerification += other.pendingDRFOVerification;
    pendingRevenue += other.pendingRevenue;
    pendingGovt += other.pendingGovt;
    pendingRFO += other.pendingRFO;
    returned += other.returned;
    completed += other.completed;
    rejected += other.rejected;
  }

  List<String> toCells() => [
        created.toString(),
        pendingAssignment.toString(),
        pendingBFO.toString(),
        pendingDRFOInspection.toString(),
        pendingDRFOVerification.toString(),
        pendingRevenue.toString(),
        pendingGovt.toString(),
        pendingRFO.toString(),
        returned.toString(),
        completed.toString(),
        rejected.toString(),
      ];

  /// Full column labels for the on-screen tables.
  static List<String> headers() => const [
        'Created',
        'To Assign',
        'BFO Insp.',
        'DRFO Insp.',
        'DRFO Verif.',
        'Revenue Op.',
        'Govt Docs',
        'RFO Appr.',
        'Returned',
        'Completed',
        'Rejected',
      ];

  /// Short column labels so the printed table fits A4 landscape.
  static List<String> shortHeaders() => const [
        'Created',
        'Assign',
        'BFO',
        'DRFO Insp',
        'DRFO Ver',
        'Revenue',
        'Govt',
        'RFO',
        'Retd',
        'Done',
        'Rejtd',
      ];
}

class RfoReportService {
  /// Applications whose created date falls within [from, to]
  /// (date part only, inclusive). Drafts are excluded.
  Future<List<ApplicationModel>> applicationsInPeriod(
    DateTime from,
    DateTime to,
  ) async {
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    final all = await ApplicationRepository().getApplications();
    return all.where((app) {
      if (app.status.trim() == WorkflowStatus.draft) return false;
      final day = DateTime(
        app.createdDate.year,
        app.createdDate.month,
        app.createdDate.day,
      );
      return !day.isBefore(fromDay) && !day.isAfter(toDay);
    }).toList();
  }

  /// Totals grouped by application type, in a fixed type order.
  Map<String, RfoReportBucket> byType(
    List<ApplicationModel> applications,
  ) {
    const order = [
      'RTC',
      'PL',
      'STGL',
      'CGL',
      'GL',
      'SPL',
      'SGL',
      'MCC',
    ];
    final result = <String, RfoReportBucket>{
      for (final type in order) type: RfoReportBucket(),
    };
    for (final app in applications) {
      final type = app.applicationType.trim().toUpperCase();
      result.putIfAbsent(type.isEmpty ? 'OTHER' : type, RfoReportBucket.new);
      result[type.isEmpty ? 'OTHER' : type]!.add(app.status);
    }
    // Drop empty fixed rows so the report stays compact.
    result.removeWhere(
      (key, bucket) => order.contains(key) && bucket.created == 0,
    );
    return result;
  }

  /// Totals grouped by section / beat across all application types.
  Map<String, RfoReportBucket> bySectionBeat(
    List<ApplicationModel> applications,
  ) {
    final result = <String, RfoReportBucket>{};
    for (final app in applications) {
      final section = app.section.trim();
      final beat = app.beat.trim();
      final key = [
        if (section.isNotEmpty) section,
        if (beat.isNotEmpty) beat,
      ].join(' / ');
      final label = key.isEmpty ? '—' : key;
      result.putIfAbsent(label, RfoReportBucket.new);
      result[label]!.add(app.status);
    }
    final sortedKeys = result.keys.toList()..sort();
    return {for (final key in sortedKeys) key: result[key]!};
  }

  RfoReportBucket total(Iterable<RfoReportBucket> buckets) {
    final sum = RfoReportBucket();
    for (final bucket in buckets) {
      sum.addBucket(bucket);
    }
    return sum;
  }
}
