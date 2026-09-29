import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tree_permission_system/constants/workflow_status.dart';
import 'package:tree_permission_system/models/revenue_reply_model.dart';
import 'package:tree_permission_system/repositories/revenue_reply_repository.dart';
import 'package:tree_permission_system/repositories/government_approval_repository.dart';
import 'package:tree_permission_system/repositories/application_completion_repository.dart';
import 'package:tree_permission_system/repositories/tree_officer_repository.dart';
import 'package:tree_permission_system/services/online_mode.dart';
import 'package:tree_permission_system/services/session_service.dart';

void main() {
  late Database db;
  late RevenueReplyRepository repo;
  setUp(() async {
    sqfliteFfiInit();
    OnlineMode.forceOffline = true;
    SessionService.instance.userId = 1;
    SessionService.instance.role = 'RFO';
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE applications(id INTEGER PRIMARY KEY, status TEXT, createdBy INTEGER, officeNumber TEXT, rfoApprovalDate TEXT)');
    await db.execute('CREATE TABLE application_history(officeNumber TEXT, action TEXT, remarks TEXT, actionBy TEXT, actionDate TEXT)');
    await db.execute('CREATE TABLE revenue_opinion_master(id INTEGER PRIMARY KEY, isActive INTEGER, officeName TEXT, officeAddress TEXT)');
    await db.insert('revenue_opinion_master', {'id':1,'isActive':1});
    await RevenueReplyRepository.createTable(db);
    await GovernmentApprovalRepository.createTable(db);
    await db.insert('applications', {'id':1,'status':WorkflowStatus.pendingRFOApproval,'createdBy':2,'officeNumber':'TEST'});
    repo = RevenueReplyRepository(databaseOverride: db);
  });
  tearDown(() async { await db.close(); SessionService.instance.logout(); OnlineMode.forceOffline = false; });
  Future<String> status() async => (await db.query('applications')).single['status'] as String;
  Future<RevenueReply> reply(String nature, {bool applied = true}) async {
    final answers = {'authority':'Authority','letterNumber':'1','letterDate':'2026-09-28','receivedDate':'2026-09-29','nature':nature,
      'onlineApplicationStatus':applied ? RevenueReply.onlineApplied : RevenueReply.onlineNotApplied,
      'onlineApplicationNumber':applied ? 'ONLINE-1' : ''};
    await db.insert('revenue_reply_cycles', {'applicationId':1,'cycle':1,'requestedAt':'2026-09-28','requestAuthority':'Authority',
      'stage':'review','answers':jsonEncode(answers),'decisions':jsonEncode({for(final key in RevenueReply.fields(answers)) key:'Approve'}),'nextAuthorityId':1});
    return (await repo.current(1))!;
  }
  for (final outcome in [PrivateLandOutcome.applicantLetter, PrivateLandOutcome.treeOfficerLetter]) {
    test('Satisfied $outcome waits in Approved for caseworker', () async {
      await repo.finalize(await reply(RevenueReply.satisfied), 'final.pdf','2026-09-29', outcomeOverride:outcome);
      expect(await status(), WorkflowStatus.approved);
    });
  }
  test('RFO online permission completes immediately without a letter', () async {
    await repo.finalize(await reply(RevenueReply.satisfied), '', '2026-09-29',
        outcomeOverride:PrivateLandOutcome.onlinePermission);
    expect(await status(), WorkflowStatus.completed);
  });
  test('Rejected revenue reply waits in Approved for caseworker', () async {
    await repo.finalize(await reply(RevenueReply.notSatisfied), 'reject.pdf','2026-09-29');
    expect(await status(), WorkflowStatus.approved);
  });
  test('Wrong authority starts another pending cycle', () async {
    await repo.finalize(await reply(RevenueReply.wrongAuthority), 'TEST_RFO_REVENUE_OPINION_REQUEST_CYCLE_2.pdf','2026-09-29');
    expect(await status(), WorkflowStatus.approved);
    SessionService.instance.userId = 2;
    SessionService.instance.role = 'Case Worker';
    expect(await ApplicationCompletionRepository(databaseOverride:db).recordSuccessfulAction(
        applicationId:1,path:'TEST_RFO_REVENUE_OPINION_REQUEST_CYCLE_2.pdf',approvalDate:'2026-09-29',action:'View'), true);
    expect(await status(), WorkflowStatus.pendingRevenueOpinion);
    expect((await repo.current(1))!.cycle, 2);
    expect((await repo.current(1))!.stage, 'pending');
  });
  test('Missing online application stays pending and can be resubmitted', () async {
    await repo.finalize(await reply(RevenueReply.satisfied, applied:false), 'TEST_RFO_APPLY_ONLINE_PL.pdf','2026-09-29', outcomeOverride:PrivateLandOutcome.treeOfficerLetter);
    expect(await status(), WorkflowStatus.approved);
    SessionService.instance.userId = 2;
    SessionService.instance.role = 'Case Worker';
    final blocked = (await repo.current(1))!;
    await expectLater(repo.saveAnswers(blocked, blocked.answers), throwsStateError);
    expect(await ApplicationCompletionRepository(databaseOverride:db).recordSuccessfulAction(
        applicationId:1,path:'TEST_RFO_APPLY_ONLINE_PL.pdf',approvalDate:'2026-09-29',action:'Print'), true);
    expect(await status(), WorkflowStatus.pendingRevenueOpinion);
    final pending = (await repo.current(1))!;
    expect(pending.stage, 'pending');
    expect(pending.decisions, isEmpty);
    SessionService.instance.userId = 2;
    SessionService.instance.role = 'Case Worker';
    await repo.saveAnswers(pending, {...pending.answers,'onlineApplicationStatus':RevenueReply.onlineApplied,'onlineApplicationNumber':'ONLINE-2'}, submit:true);
    expect(await status(), WorkflowStatus.pendingRFOApproval);
    expect((await repo.current(1))!.stage, 'review');
  });
}
