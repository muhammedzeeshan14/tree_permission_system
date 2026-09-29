import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tree_permission_system/constants/workflow_status.dart';
import 'package:tree_permission_system/repositories/government_approval_repository.dart';
import 'package:tree_permission_system/repositories/revenue_reply_repository.dart';
import 'package:tree_permission_system/repositories/application_completion_repository.dart';
import 'package:tree_permission_system/services/online_mode.dart';
import 'package:tree_permission_system/services/session_service.dart';

void main() {
  late Database db;
  late GovernmentApprovalRepository repo;
  setUp(() async {
    sqfliteFfiInit();
    OnlineMode.forceOffline = true;
    SessionService.instance.userId = 1;
    SessionService.instance.role = 'RFO';
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE applications(id INTEGER PRIMARY KEY, applicationType TEXT, status TEXT, createdBy INTEGER, officeNumber TEXT, rfoApprovalDate TEXT)');
    await db.execute('CREATE TABLE application_history(officeNumber TEXT, action TEXT, remarks TEXT, actionBy TEXT, actionDate TEXT)');
    await db.execute('CREATE TABLE tree_officer_master(id INTEGER PRIMARY KEY)');
    await db.execute('CREATE TABLE trees(id INTEGER, applicationId INTEGER, recommendationTypeId INTEGER)');
    await db.execute('CREATE TABLE master_data(id INTEGER, code TEXT)');
    await db.execute('CREATE TABLE rfo_item_approvals(applicationId INTEGER, itemKey TEXT, itemId INTEGER, decision TEXT)');
    await GovernmentApprovalRepository.createTable(db);
    await RevenueReplyRepository.createTable(db);
    await db.insert('applications', {'id':1, 'applicationType':'GL', 'status':WorkflowStatus.pendingRFOApproval, 'createdBy':2, 'officeNumber':'TEST'});
    await db.insert('tree_officer_master', {'id':1});
    await db.insert('trees', {'id':1,'applicationId':1,'recommendationTypeId':1});
    await db.insert('master_data', {'id':1,'code':'FULL'});
    await db.insert('rfo_item_approvals', {'applicationId':1,'itemKey':'TREE','itemId':1,'decision':'Approve'});
    repo = GovernmentApprovalRepository(databaseOverride: db);
  });
  tearDown(() async { await db.close(); SessionService.instance.logout(); OnlineMode.forceOffline = false; });
  Future<String> status() async => (await db.query('applications')).single['status'] as String;

  test('Auction final approval waits for caseworker, not Completed', () async {
    final record = await repo.saveOptions(1, 'Auction', null, 1);
    await repo.finishInitial(record, ['do.pdf', 'patti.pdf'], '2026-09-29');
    expect(await status(), WorkflowStatus.approved);
  });
  test('Direct valuation and MCC final approval wait for caseworker', () async {
    await db.update('applications', {'applicationType':'MCC'});
    final record = await repo.saveOptions(1, 'Valuation', true, 1);
    await repo.finishInitial(record, ['valuation.pdf'], '2026-09-29');
    expect(await status(), WorkflowStatus.approved);
  });
  test('Khata request goes through print queue before pending details', () async {
    final record = await repo.saveOptions(1, 'Valuation', false, 1);
    await repo.finishInitial(record, ['TEST_RFO_GL_DOCUMENT_REQUEST.pdf'], '2026-09-29');
    expect(await status(), WorkflowStatus.approved);
    SessionService.instance.userId = 2;
    SessionService.instance.role = 'Case Worker';
    expect(await ApplicationCompletionRepository(databaseOverride:db).recordSuccessfulAction(
      applicationId:1,path:'TEST_RFO_GL_DOCUMENT_REQUEST.pdf',approvalDate:'2026-09-29',action:'View'), true);
    expect(await status(), WorkflowStatus.pendingGovernmentLandApprovals);
  });
  for (final nature in ['Satisfied', 'Not satisfied']) {
    test('Reviewed $nature reply becomes Approved, not Completed', () async {
      await db.insert('government_approvals', {
        'applicationId':1,'permissionType':'Valuation','khataGiven':0,
        'treeOfficerId':1,'stage':'review','requestLetterPath':'request.pdf',
        'answers':jsonEncode({'authority':'Authority','letterNumber':'1','letterDate':'2026-09-28','receivedDate':'2026-09-29','nature':nature}),
        'approvedFields':jsonEncode(['authority','letterNumber','letterDate','receivedDate','nature']),
      });
      await repo.finishReviewDocuments((await repo.get(1))!, nature == 'Satisfied' ? ['valuation.pdf'] : ['do.pdf','patti.pdf'], '2026-09-29');
      expect(await status(), WorkflowStatus.approved);
    });
  }
}
