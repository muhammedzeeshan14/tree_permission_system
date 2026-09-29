import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../constants/workflow_status.dart';
import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';

/// Records successful final-letter actions in shared history, scoped to approval.
class ApplicationCompletionRepository {
  final Database? databaseOverride;
  ApplicationCompletionRepository({this.databaseOverride});
  static const event = 'Final decision document viewed/printed';
  static String documentName(String path) =>
      path.split(RegExp(r'[/\\]')).last.toUpperCase();

  static bool isFinalDocument(String path) {
    final name = documentName(path);
    if (!name.endsWith('.PDF') || !name.contains('_RFO_')) return false;
    return !name.contains('REVENUE_OPINION_REQUEST') &&
        !name.contains('DOCUMENT_REQUEST') && !name.contains('APPLY_ONLINE');
  }

  void _authorize(Map<String, Object?> app) {
    final session = SessionService.instance;
    if (session.role != 'Case Worker' || session.userId == null ||
        app['createdBy'] != session.userId) {
      throw StateError('Only the assigned caseworker can complete this application.');
    }
  }

  String? _requestDestination(List<Map<String, Object?>> government,
      List<Map<String, Object?>> revenue, String document) {
    if (government.isNotEmpty && government.single['stage'] == 'pending' &&
        documentName(government.single['requestLetterPath'] as String? ?? '') == document) {
      return WorkflowStatus.pendingGovernmentLandApprovals;
    }
    if (revenue.isNotEmpty && {'pending', 'printing'}.contains(revenue.first['stage'])) {
      final reply = revenue.first;
      final finalPath = reply['finalLetterPath'] as String? ?? '';
      final request = finalPath.toUpperCase().contains('APPLY_ONLINE')
          ? finalPath : reply['requestLetterPath'] as String? ?? '';
      if (documentName(request) == document) return WorkflowStatus.pendingRevenueOpinion;
    }
    return null;
  }

  Set<String> _required(Map<String, Object?> app,
      List<Map<String, Object?>> government, List<Map<String, Object?>> revenue,
      String document) {
    // An unrelated/stale PDF must not finish an active information-request cycle.
    if (government.any((r) => {'pending', 'review'}.contains(r['stage'])) ||
        revenue.any((r) => {'pending', 'printing', 'review'}.contains(r['stage']))) return {};
    // Direct RTC, deferred, not-recommended, branch and government sandal letters.
    const direct = [
      '_RFO_APPROVED_RTC.PDF', '_RFO_DEFERRED_RTC.PDF',
      '_RFO_NOT_RECOMMENDED_NON_RTC.PDF', '_RFO_DEFERRED_NON_RTC.PDF',
      '_RFO_PRIVATE_LAND_BRANCH_PERMISSION.PDF', '_RFO_APPROVED_SGL.PDF',
    ];
    if (direct.any(document.endsWith)) return {document};
    if (government.isNotEmpty) {
      final record = government.single;
      if (record['stage'] != 'completed') return {};
      final paths = List<String>.from(jsonDecode(record['finalPaths'] as String? ?? '[]'));
      final auction = record['permissionType'] == 'Auction' ||
          (jsonDecode(record['answers'] as String? ?? '{}') as Map)['nature'] == 'Not satisfied';
      final names = paths.map(documentName).toSet();
      if (auction && (!names.any((n) => n.endsWith('_RFO_GL_DO.PDF')) ||
          !names.any((n) => n.endsWith('_RFO_GL_TAGGU_BELE_PATTI.PDF')))) {
        throw StateError('Both auction documents must be generated before completion.');
      }
      return names;
    }
    if (revenue.isNotEmpty) {
      final reply = revenue.first;
      if (reply['stage'] != 'completed') return {};
      final path = reply['finalLetterPath'] as String? ?? '';
      return isFinalDocument(path) ? {documentName(path)} : {};
    }
    return {};
  }

  bool _allHandled(List<Map<String, Object?>> rows, Set<String> required,
      String approval) {
    final handled = <String>{};
    for (final row in rows) {
      try {
        final data = jsonDecode(row['remarks'] as String? ?? '{}') as Map;
        if (data['approval'] == approval) handled.add(data['document'].toString());
      } catch (_) {
        // Earlier history entries may contain plain text.
      }
    }
    return required.isNotEmpty && handled.containsAll(required);
  }

  Future<bool> recordSuccessfulAction({
    required int applicationId, required String path,
    required String approvalDate, required String action,
  }) async {
    if (!{'View', 'Print'}.contains(action)) throw ArgumentError('Invalid action.');
    final document = documentName(path);
    if (!document.endsWith('.PDF') || !document.contains('_RFO_')) return false;
    if (OnlineMode.enabled) {
      final apps = await OnlineDatabase.select('applications', equals:{'id':applicationId}, limit:1);
      if (apps.isEmpty) throw StateError('Application not found.');
      final app = apps.single;
      _authorize(app);
      if (app['status'] == WorkflowStatus.completed) return true;
      if (app['status'] != WorkflowStatus.approved ||
          (app['rfoApprovalDate'] ?? '') != approvalDate) return false;
      final government = await OnlineDatabase.select('government_approvals', equals:{'applicationId':applicationId});
      final revenue = await OnlineDatabase.select('revenue_reply_cycles', equals:{'applicationId':applicationId}, orderBy:'cycle', descending:true, limit:1);
      final destination = _requestDestination(government, revenue, document);
      final required = destination != null ? {document}
          : _required(app, government, revenue, document);
      final nextStatus = destination ?? WorkflowStatus.completed;
      if (!required.contains(document)) return false;
      await OnlineDatabase.insert('application_history', {
        'officeNumber':app['officeNumber'], 'action':event,
        'remarks':jsonEncode({'approval':approvalDate,'document':document,'action':action}),
        'actionBy':SessionService.instance.name,'actionDate':DateTime.now().toIso8601String(),
      });
      final rows = await OnlineDatabase.selectAll('application_history',
          equals:{'officeNumber':app['officeNumber'], 'action':event});
      if (!_allHandled(rows, required, approvalDate)) return false;
      // Do not overwrite a newer decision or a reopened clarification cycle.
      dynamic query = SupabaseService.client!.from('applications').update({
        'status':nextStatus, 'updatedAt':DateTime.now().toIso8601String(),
      }).eq('id',applicationId).eq('createdBy',SessionService.instance.userId!)
        .eq('status',WorkflowStatus.approved);
      query = app['rfoApprovalDate'] == null
          ? query.isFilter('rfoApprovalDate', null) : query.eq('rfoApprovalDate', approvalDate);
      final changed = await query.select('id') as List;
      if (changed.isNotEmpty) return true;
      final latest = await OnlineDatabase.select('applications', equals:{'id':applicationId}, limit:1);
      return latest.isNotEmpty && latest.single['status'] == nextStatus;
    }
    final db = databaseOverride ?? await DatabaseHelper.instance.database;
    return db.transaction((tx) async {
      final apps = await tx.query('applications',where:'id=?',whereArgs:[applicationId]);
      if (apps.isEmpty) throw StateError('Application not found.');
      final app = apps.single;
      _authorize(app);
      if (app['status'] == WorkflowStatus.completed) return true;
      if (app['status'] != WorkflowStatus.approved ||
          (app['rfoApprovalDate'] ?? '') != approvalDate) return false;
      final government = await tx.query('government_approvals',where:'applicationId=?',whereArgs:[applicationId]);
      final revenue = await tx.query('revenue_reply_cycles',where:'applicationId=?',whereArgs:[applicationId],orderBy:'cycle DESC',limit:1);
      final destination = _requestDestination(government, revenue, document);
      final required = destination != null ? {document}
          : _required(app, government, revenue, document);
      final nextStatus = destination ?? WorkflowStatus.completed;
      if (!required.contains(document)) return false;
      await tx.insert('application_history', {
        'officeNumber':app['officeNumber'], 'action':event,
        'remarks':jsonEncode({'approval':approvalDate,'document':document,'action':action}),
        'actionBy':SessionService.instance.name,'actionDate':DateTime.now().toIso8601String(),
      });
      final rows = await tx.query('application_history',where:'officeNumber=? AND action=?',whereArgs:[app['officeNumber'],event]);
      if (!_allHandled(rows, required, approvalDate)) return false;
      await tx.update('applications',{'status':nextStatus},where:'id=? AND status=?',whereArgs:[applicationId,WorkflowStatus.approved]);
      return true;
    });
  }
}
