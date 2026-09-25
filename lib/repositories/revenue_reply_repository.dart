import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'tree_officer_repository.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../constants/workflow_status.dart';
import '../models/application_model.dart';
import '../models/revenue_reply_model.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';
import '../services/session_service.dart';

class RevenueReplyRepository {
  final Database? databaseOverride;
  RevenueReplyRepository({this.databaseOverride});
  Future<Database> get _db async =>
      databaseOverride ?? await DatabaseHelper.instance.database;

  static Future<void> createTable(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS revenue_reply_cycles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      applicationId INTEGER NOT NULL,
      cycle INTEGER NOT NULL,
      requestedAt TEXT NOT NULL,
      requestAuthority TEXT NOT NULL,
      requestLetterPath TEXT NOT NULL DEFAULT '',
      printedAt TEXT NOT NULL DEFAULT '',
      stage TEXT NOT NULL DEFAULT 'printing',
      answers TEXT NOT NULL DEFAULT '{}',
      decisions TEXT NOT NULL DEFAULT '{}',
      nextAuthorityId INTEGER,
      finalLetterPath TEXT NOT NULL DEFAULT '',
      revision INTEGER NOT NULL DEFAULT 0,
      UNIQUE(applicationId, cycle)
    )''');
  }

  Future<List<RevenueReply>> history(int id) async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          'revenue_reply_cycles',
          equals: {'applicationId': id},
          orderBy: 'cycle',
          descending: true,
        );
        rows.sort(
          (a, b) => ((b['cycle'] as num?)?.toInt() ?? 0).compareTo(
            (a['cycle'] as num?)?.toInt() ?? 0,
          ),
        );
        return rows.map(RevenueReply.fromMap).toList();
      } catch (e) {
        debugPrint(
          'online history revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    return (await (await _db).query(
      'revenue_reply_cycles',
      where: 'applicationId=?',
      whereArgs: [id],
      orderBy: 'cycle DESC',
    )).map(RevenueReply.fromMap).toList();
  }

  Future<RevenueReply?> current(int id) async {
    final rows = await history(id);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _audit(
    DatabaseExecutor tx,
    Map<String, Object?> app,
    String action,
  ) async {
    await tx.insert('application_history', {
      'officeNumber': app['officeNumber'],
      'action': action,
      'remarks': 'Revenue opinion workflow',
      'actionBy': SessionService.instance.name,
      'actionDate': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, Object?>> _application(DatabaseExecutor tx, int id) async {
    final rows = await tx.query('applications', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Application no longer exists.');
    return rows.first;
  }

  void _authorize(Map<String, Object?> app, String role) {
    final session = SessionService.instance;
    if (session.role != role ||
        session.userId == null ||
        (role == 'Case Worker' && app['createdBy'] != session.userId)) {
      throw StateError('This application is not available to your login.');
    }
  }

  Future<void> _check(
    DatabaseExecutor tx,
    RevenueReply reply,
    String role,
    String stage,
  ) async {
    final app = await _application(tx, reply.applicationId);
    _authorize(app, role);
    final status = stage == 'review'
        ? WorkflowStatus.pendingRFOApproval
        : WorkflowStatus.pendingRevenueOpinion;
    if (app['status'] != status)
      throw StateError('Application has moved to another stage. Reopen it.');
    final rows = await tx.query(
      'revenue_reply_cycles',
      where: 'applicationId=?',
      whereArgs: [reply.applicationId],
      orderBy: 'cycle DESC',
      limit: 1,
    );
    if (rows.isEmpty ||
        rows.first['id'] != reply.id ||
        rows.first['revision'] != reply.revision ||
        rows.first['stage'] != stage) {
      throw StateError(
        'These details changed. Reopen the application before continuing.',
      );
    }
  }

  Future<RevenueReply> _updated(
    DatabaseExecutor tx,
    RevenueReply reply,
    Map<String, Object?> values,
  ) async {
    await tx.update(
      'revenue_reply_cycles',
      {...values, 'revision': reply.revision + 1},
      where: 'id=?',
      whereArgs: [reply.id],
    );
    return RevenueReply.fromMap(
      (await tx.query(
        'revenue_reply_cycles',
        where: 'id=?',
        whereArgs: [reply.id],
      )).first,
    );
  }

  String _address(Map<String, Object?> row) => [
    row['officeName'],
    row['officeAddress'],
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join('\n');

  Future<Map<String, dynamic>> _onlineApplication(int id) async {
    final rows = await OnlineDatabase.select(
      'applications',
      equals: {'id': id},
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Application no longer exists.');
    return rows.first;
  }

  Future<void> _onlineAudit(
    Map<String, Object?> app,
    String action,
  ) async {
    await OnlineDatabase.insert('application_history', {
      'officeNumber': app['officeNumber'],
      'action': action,
      'remarks': 'Revenue opinion workflow',
      'actionBy': SessionService.instance.name,
      'actionDate': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onlineCheck(
    RevenueReply reply,
    String role,
    String stage,
  ) async {
    final app = await _onlineApplication(reply.applicationId);
    _authorize(app, role);
    final status = stage == 'review'
        ? WorkflowStatus.pendingRFOApproval
        : WorkflowStatus.pendingRevenueOpinion;
    if (app['status'] != status)
      throw StateError('Application has moved to another stage. Reopen it.');
    final rows = await OnlineDatabase.select(
      'revenue_reply_cycles',
      equals: {'applicationId': reply.applicationId},
      orderBy: 'cycle',
      descending: true,
      limit: 1,
    );
    if (rows.isEmpty ||
        rows.first['id'] != reply.id ||
        rows.first['revision'] != reply.revision ||
        rows.first['stage'] != stage) {
      throw StateError(
        'These details changed. Reopen the application before continuing.',
      );
    }
  }

  Future<RevenueReply> _onlineUpdated(
    RevenueReply reply,
    Map<String, Object?> values,
  ) async {
    await OnlineDatabase.update(
      'revenue_reply_cycles',
      reply.id,
      {...values, 'revision': reply.revision + 1},
    );
    final rows = await OnlineDatabase.select(
      'revenue_reply_cycles',
      equals: {'id': reply.id},
      limit: 1,
    );
    return RevenueReply.fromMap(rows.first);
  }

  Future<String> _onlineRequestAuthority(int applicationId) async {
    final selections = await OnlineDatabase.select(
      'application_revenue_opinion',
      equals: {'applicationId': applicationId},
    );
    if (selections.isEmpty) return '';
    final masters = await OnlineDatabase.select(
      'revenue_opinion_master',
      equals: {'id': selections.first['revenueOpinionId']},
    );
    if (masters.isEmpty) return '';
    return _address(masters.first);
  }

  Future<PrivateLandOutcome> _onlineCompletionOutcome(
    int applicationId,
  ) async {
    final links = await OnlineDatabase.select(
      'application_tree_officer',
      equals: {'applicationId': applicationId},
    );
    if (links.isEmpty)
      throw StateError('Select Tree officer before final approval.');
    final officers = await OnlineDatabase.select(
      'tree_officer_master',
      equals: {'id': links.first['treeOfficerId']},
    );
    if (officers.isEmpty)
      throw StateError('Select Tree officer before final approval.');
    return TreeOfficerRepository.outcomeFor(officers.first);
  }

  Future<void> startRequest(ApplicationModel application, String path) async {
    if (OnlineMode.enabled) {
      try {
        final app = await _onlineApplication(application.id!);
        _authorize(app, 'RFO');
        if (app['status'] != WorkflowStatus.pendingRFOApproval)
          throw StateError('Application is no longer pending RFO approval.');
        final existing = await OnlineDatabase.select(
          'revenue_reply_cycles',
          equals: {'applicationId': application.id},
        );
        if (existing.isNotEmpty)
          throw StateError(
            'A revenue request already exists. Open its review workflow.',
          );
        final authority = await _onlineRequestAuthority(application.id!);
        await OnlineDatabase.insert('revenue_reply_cycles', {
          'applicationId': application.id,
          'cycle': 1,
          'requestedAt': application.rfoApprovalDate,
          'requestAuthority': authority,
          'requestLetterPath': path,
        });
        await OnlineDatabase.update(
          'applications',
          application.id!,
          {
            'status': WorkflowStatus.pendingRevenueOpinion,
            'rfoApprovalDate': application.rfoApprovalDate,
          },
        );
        await _onlineAudit(app, 'Revenue opinion requested by RFO');
        application.status = WorkflowStatus.pendingRevenueOpinion;
        return;
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online startRequest revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    await db.transaction((tx) async {
      final app = await _application(tx, application.id!);
      _authorize(app, 'RFO');
      if (app['status'] != WorkflowStatus.pendingRFOApproval)
        throw StateError('Application is no longer pending RFO approval.');
      final existing = await tx.query(
        'revenue_reply_cycles',
        where: 'applicationId=?',
        whereArgs: [application.id],
      );
      if (existing.isNotEmpty)
        throw StateError(
          'A revenue request already exists. Open its review workflow.',
        );
      final selection = await tx.rawQuery(
        '''SELECT m.officeName, m.officeAddress FROM application_revenue_opinion s
        JOIN revenue_opinion_master m ON m.id=s.revenueOpinionId WHERE s.applicationId=?''',
        [application.id],
      );
      await tx.insert('revenue_reply_cycles', {
        'applicationId': application.id,
        'cycle': 1,
        'requestedAt': application.rfoApprovalDate,
        'requestAuthority': selection.isEmpty ? '' : _address(selection.first),
        'requestLetterPath': path,
      });
      await tx.update(
        'applications',
        {
          'status': WorkflowStatus.pendingRevenueOpinion,
          'rfoApprovalDate': application.rfoApprovalDate,
        },
        where: 'id=?',
        whereArgs: [application.id],
      );
      await _audit(tx, app, 'Revenue opinion requested by RFO');
    });
    application.status = WorkflowStatus.pendingRevenueOpinion;
  }

  Future<RevenueReply> ensureLegacyRequest(
    ApplicationModel application,
    String path,
  ) async {
    if (OnlineMode.enabled) {
      try {
        final app = await _onlineApplication(application.id!);
        _authorize(app, 'Case Worker');
        if (app['status'] != WorkflowStatus.pendingRevenueOpinion)
          throw StateError('Application is not pending revenue opinion.');
        var rows = await OnlineDatabase.select(
          'revenue_reply_cycles',
          equals: {'applicationId': application.id},
          orderBy: 'cycle',
          descending: true,
        );
        if (rows.isEmpty) {
          final authority = await _onlineRequestAuthority(application.id!);
          await OnlineDatabase.insert('revenue_reply_cycles', {
            'applicationId': application.id,
            'cycle': 1,
            'requestedAt': app['rfoApprovalDate'] ?? '',
            'requestAuthority': authority,
            'requestLetterPath': path,
          });
          rows = await OnlineDatabase.select(
            'revenue_reply_cycles',
            equals: {'applicationId': application.id},
            orderBy: 'cycle',
            descending: true,
          );
        }
        return RevenueReply.fromMap(rows.first);
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online ensureLegacyRequest revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    return db.transaction((tx) async {
      final app = await _application(tx, application.id!);
      _authorize(app, 'Case Worker');
      if (app['status'] != WorkflowStatus.pendingRevenueOpinion)
        throw StateError('Application is not pending revenue opinion.');
      var rows = await tx.query(
        'revenue_reply_cycles',
        where: 'applicationId=?',
        whereArgs: [application.id],
        orderBy: 'cycle DESC',
      );
      if (rows.isEmpty) {
        final selection = await tx.rawQuery(
          '''SELECT m.officeName, m.officeAddress FROM application_revenue_opinion s
          JOIN revenue_opinion_master m ON m.id=s.revenueOpinionId WHERE s.applicationId=?''',
          [application.id],
        );
        await tx.insert('revenue_reply_cycles', {
          'applicationId': application.id,
          'cycle': 1,
          'requestedAt': app['rfoApprovalDate'] ?? '',
          'requestAuthority': selection.isEmpty
              ? ''
              : _address(selection.first),
          'requestLetterPath': path,
        });
        rows = await tx.query(
          'revenue_reply_cycles',
          where: 'applicationId=?',
          whereArgs: [application.id],
        );
      }
      return RevenueReply.fromMap(rows.first);
    });
  }

  Future<void> markPrinted(RevenueReply reply) async {
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(reply, 'Case Worker', 'printing');
        await _onlineUpdated(reply, {
          'stage': 'pending',
          'printedAt': DateTime.now().toIso8601String(),
        });
        await _onlineAudit(
          await _onlineApplication(reply.applicationId),
          'Revenue request letters printed; awaiting reply',
        );
        return;
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online markPrinted revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    await db.transaction((tx) async {
      await _check(tx, reply, 'Case Worker', 'printing');
      await _updated(tx, reply, {
        'stage': 'pending',
        'printedAt': DateTime.now().toIso8601String(),
      });
      await _audit(
        tx,
        await _application(tx, reply.applicationId),
        'Revenue request letters printed; awaiting reply',
      );
    });
  }

  Future<RevenueReply> saveAnswers(
    RevenueReply reply,
    Map<String, String> answers, {
    bool rfo = false,
    bool submit = false,
  }) async {
    final clean = RevenueReply.activeAnswers(answers);
    if (submit) {
      final error = RevenueReply.validate(clean);
      if (error != null) throw StateError(error);
    }
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(
          reply,
          rfo ? 'RFO' : 'Case Worker',
          rfo ? 'review' : 'pending',
        );
        final changed =
            jsonEncode(clean) !=
            jsonEncode(RevenueReply.activeAnswers(reply.answers));
        final next = await _onlineUpdated(reply, {
          'answers': jsonEncode(clean),
          if (changed || submit) 'decisions': '{}',
          if (changed) 'nextAuthorityId': null,
          if (submit) 'stage': 'review',
        });
        if (submit) {
          await OnlineDatabase.update(
            'applications',
            reply.applicationId,
            {'status': WorkflowStatus.pendingRFOApproval},
          );
          await _onlineAudit(
            await _onlineApplication(reply.applicationId),
            'Revenue reply sent for RFO approval',
          );
        }
        return next;
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online saveAnswers revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    return db.transaction((tx) async {
      await _check(
        tx,
        reply,
        rfo ? 'RFO' : 'Case Worker',
        rfo ? 'review' : 'pending',
      );
      final changed =
          jsonEncode(clean) !=
          jsonEncode(RevenueReply.activeAnswers(reply.answers));
      final next = await _updated(tx, reply, {
        'answers': jsonEncode(clean),
        if (changed || submit) 'decisions': '{}',
        if (changed) 'nextAuthorityId': null,
        if (submit) 'stage': 'review',
      });
      if (submit) {
        await tx.update(
          'applications',
          {'status': WorkflowStatus.pendingRFOApproval},
          where: 'id=?',
          whereArgs: [reply.applicationId],
        );
        await _audit(
          tx,
          await _application(tx, reply.applicationId),
          'Revenue reply sent for RFO approval',
        );
      }
      return next;
    });
  }

  Future<RevenueReply> decide(
    RevenueReply reply,
    String field,
    String decision,
  ) async {
    if (!RevenueReply.fields(reply.answers).contains(field) ||
        !['Approve', 'Re-inspect'].contains(decision)) {
      throw ArgumentError('Invalid revenue review decision.');
    }
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(reply, 'RFO', 'review');
        return _onlineUpdated(reply, {
          'decisions': jsonEncode({...reply.decisions, field: decision}),
        });
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online decide revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    return db.transaction((tx) async {
      await _check(tx, reply, 'RFO', 'review');
      return _updated(tx, reply, {
        'decisions': jsonEncode({...reply.decisions, field: decision}),
      });
    });
  }

  Future<RevenueReply> saveAuthority(
    RevenueReply reply,
    int authorityId,
  ) async {
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(reply, 'RFO', 'review');
        final rows = await OnlineDatabase.select(
          'revenue_opinion_master',
          equals: {'id': authorityId},
          limit: 1,
        );
        if (rows.isEmpty ||
            (rows.first['isActive'] != 1 &&
                rows.first['isActive'] != true)) {
          throw StateError('Choose an active revenue authority.');
        }
        return _onlineUpdated(reply, {'nextAuthorityId': authorityId});
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online saveAuthority revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    return db.transaction((tx) async {
      await _check(tx, reply, 'RFO', 'review');
      final rows = await tx.query(
        'revenue_opinion_master',
        where: 'id=? AND isActive=1',
        whereArgs: [authorityId],
      );
      if (rows.isEmpty) throw StateError('Choose an active revenue authority.');
      return _updated(tx, reply, {'nextAuthorityId': authorityId});
    });
  }

  Future<void> finalize(
    RevenueReply reply,
    String letterPath,
    String approvalDate, {
    PrivateLandOutcome? outcomeOverride,
  }) async {
    if (!reply.allApproved)
      throw StateError('Approve every answer before final approval.');
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(reply, 'RFO', 'review');
        final app = await _onlineApplication(reply.applicationId);
        final resend = reply.answers['nature'] == RevenueReply.wrongAuthority;
        final outcome = outcomeOverride ??
            (reply.answers['nature'] == RevenueReply.satisfied
                ? await _onlineCompletionOutcome(reply.applicationId)
                : null);
        final onlinePermission = outcome == PrivateLandOutcome.onlinePermission;
        if (onlinePermission && letterPath.trim().isNotEmpty) {
          throw StateError('RFO online permission completion must not generate a letter.');
        }
        if (!onlinePermission && letterPath.trim().isEmpty) {
          throw StateError('Generate the required letter before completing this application.');
        }
        if (resend) {
          if (reply.nextAuthorityId == null)
            throw StateError('Choose an active revenue authority.');
          final authorities = await OnlineDatabase.select(
            'revenue_opinion_master',
            equals: {'id': reply.nextAuthorityId},
            limit: 1,
          );
          if (authorities.isEmpty ||
              (authorities.first['isActive'] != 1 &&
                  authorities.first['isActive'] != true)) {
            throw StateError('Choose an active revenue authority.');
          }
          await OnlineDatabase.insert('revenue_reply_cycles', {
            'applicationId': reply.applicationId,
            'cycle': reply.cycle + 1,
            'requestedAt': approvalDate,
            'requestAuthority': _address(authorities.first),
            'requestLetterPath': letterPath,
          });
          // Retain the original opinion purpose/content; each cycle stores its recipient.
        }
        await _onlineUpdated(reply, {
          'stage': 'completed',
          'finalLetterPath': letterPath,
        });
        await OnlineDatabase.update(
          'applications',
          reply.applicationId,
          {
            'status': resend
                ? WorkflowStatus.pendingRevenueOpinion
                : WorkflowStatus.completed,
            'rfoApprovalDate': approvalDate,
          },
        );
        await _onlineAudit(
          app,
          resend
              ? 'Revised revenue opinion requested by RFO'
              : onlinePermission
              ? 'Give online permission in Aranya website; application completed (no letter generated)'
              : 'Revenue opinion ' +
                    (reply.answers['nature'] ?? '') +
                    '; application completed',
        );
        return;
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint(
          'online finalize revenue_reply_cycles failed, falling back to local: $e',
        );
      }
    }
    final db = await _db;
    await db.transaction((tx) async {
      await _check(tx, reply, 'RFO', 'review');
      final app = await _application(tx, reply.applicationId);
      final resend = reply.answers['nature'] == RevenueReply.wrongAuthority;
      final outcome = outcomeOverride ??
          (reply.answers['nature'] == RevenueReply.satisfied
              ? await TreeOfficerRepository.completionOutcome(tx, reply.applicationId) : null);
      final onlinePermission = outcome == PrivateLandOutcome.onlinePermission;
      if (onlinePermission && letterPath.trim().isNotEmpty) {
        throw StateError('RFO online permission completion must not generate a letter.');
      }
      if (!onlinePermission && letterPath.trim().isEmpty) {
        throw StateError('Generate the required letter before completing this application.');
      }
      if (resend) {
        if (reply.nextAuthorityId == null)
          throw StateError('Choose an active revenue authority.');
        final authorities = await tx.query(
          'revenue_opinion_master',
          where: 'id=? AND isActive=1',
          whereArgs: [reply.nextAuthorityId],
        );
        if (authorities.isEmpty)
          throw StateError('Choose an active revenue authority.');
        await tx.insert('revenue_reply_cycles', {
          'applicationId': reply.applicationId,
          'cycle': reply.cycle + 1,
          'requestedAt': approvalDate,
          'requestAuthority': _address(authorities.first),
          'requestLetterPath': letterPath,
        });
        // Retain the original opinion purpose/content; each cycle stores its recipient.
      }
      await _updated(tx, reply, {
        'stage': 'completed',
        'finalLetterPath': letterPath,
      });
      await tx.update(
        'applications',
        {
          'status': resend
              ? WorkflowStatus.pendingRevenueOpinion
              : WorkflowStatus.completed,
          'rfoApprovalDate': approvalDate,
        },
        where: 'id=?',
        whereArgs: [reply.applicationId],
      );
      await _audit(
        tx,
        app,
        resend
            ? 'Revised revenue opinion requested by RFO'
            : onlinePermission
            ? 'Give online permission in Aranya website; application completed (no letter generated)'
            : 'Revenue opinion ' +
                  (reply.answers['nature'] ?? '') +
                  '; application completed',
      );
    });
  }
}
