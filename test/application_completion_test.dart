import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tree_permission_system/constants/workflow_status.dart';
import 'package:tree_permission_system/repositories/application_completion_repository.dart';
import 'package:tree_permission_system/repositories/government_approval_repository.dart';
import 'package:tree_permission_system/repositories/revenue_reply_repository.dart';
import 'package:tree_permission_system/services/online_mode.dart';
import 'package:tree_permission_system/services/session_service.dart';

void main() {
  late Database db;
  late ApplicationCompletionRepository repo;
  const doLetter = 'APP_RFO_GL_DO.pdf';
  const patti = 'APP_RFO_GL_TAGGU_BELE_PATTI.pdf';
  setUp(() async {
    sqfliteFfiInit(); OnlineMode.forceOffline = true;
    SessionService.instance.userId = 2;
    SessionService.instance.role = 'Case Worker';
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE applications(id INTEGER PRIMARY KEY, status TEXT, createdBy INTEGER, officeNumber TEXT, rfoApprovalDate TEXT)');
    await db.execute('CREATE TABLE application_history(officeNumber TEXT, action TEXT, remarks TEXT, actionBy TEXT, actionDate TEXT)');
    await GovernmentApprovalRepository.createTable(db);
    await RevenueReplyRepository.createTable(db);
    await db.insert('applications', {'id':1,'status':WorkflowStatus.approved,'createdBy':2,'officeNumber':'APP','rfoApprovalDate':'approval-1'});
    repo = ApplicationCompletionRepository(databaseOverride:db);
  });
  tearDown(() async { await db.close(); OnlineMode.forceOffline = false; SessionService.instance.logout(); });
  Future<String> status() async => (await db.query('applications')).single['status'] as String;
  Future<bool> handle(String path, {String action='View', String approval='approval-1'}) =>
      repo.recordSuccessfulAction(applicationId:1,path:path,approvalDate:approval,action:action);
  Future<void> auction({bool afterReply=false}) => db.insert('government_approvals', {
    'applicationId':1,'permissionType':afterReply ? 'Valuation':'Auction','stage':'completed',
    'answers':jsonEncode(afterReply ? {'nature':'Not satisfied'} : {}),
    'finalPaths':jsonEncode([doLetter,patti]),
  }).then((_) {});

  test('Auction requires both documents; repeats do not count twice', () async {
    await auction();
    expect(await handle(doLetter), false);
    expect(await handle(doLetter,action:'Print'), false);
    expect(await status(), WorkflowStatus.approved);
    // Recreate repository to model another device using the same stored history.
    repo = ApplicationCompletionRepository(databaseOverride:db);
    expect(await handle('/another/device/APP_RFO_GL_TAGGU_BELE_PATTI.pdf', action:'Print'), true);
    expect(await status(), WorkflowStatus.completed);
  });
  test('Unsatisfied valuation auction also requires both, in either order', () async {
    await auction(afterReply:true);
    expect(await handle(patti), false);
    expect(await handle(doLetter), true);
  });
  test('Old approval actions do not complete a new approval', () async {
    await auction();
    expect(await handle(doLetter), false);
    await db.update('applications', {'rfoApprovalDate':'approval-2'});
    expect(await handle(patti,approval:'approval-2'), false);
    expect(await handle(doLetter,approval:'approval-2'), true);
  });
  test('Stale screen cannot complete a reopened pending cycle', () async {
    await db.update('applications', {'status':WorkflowStatus.pendingRevenueOpinion});
    expect(await handle('APP_RFO_PRIVATE_LAND_BRANCH_PERMISSION.pdf'), false);
    expect(await status(), WorkflowStatus.pendingRevenueOpinion);
  });
  test('Request and attachment PDFs never complete an application', () async {
    for (final file in ['APP_RFO_GL_DOCUMENT_REQUEST.pdf','APP_RFO_REVENUE_OPINION_REQUEST.pdf','APP_RFO_APPLY_ONLINE_PL.pdf','INSPECTION_PHOTOS.pdf']) {
      expect(await handle(file), false);
    }
    expect(await status(), WorkflowStatus.approved);
    expect(await db.query('application_history'), isEmpty);
  });
  for (final suffix in ['APPROVED_RTC','DEFERRED_RTC','NOT_RECOMMENDED_NON_RTC','DEFERRED_NON_RTC','PRIVATE_LAND_BRANCH_PERMISSION','APPROVED_SGL']) {
    test('Direct $suffix completes on successful view', () async {
      expect(await handle('APP_RFO_$suffix.pdf'), true);
      expect(await status(), WorkflowStatus.completed);
    });
  }
  test('Valuation completes from its saved final letter', () async {
    await db.insert('government_approvals', {'applicationId':1,'permissionType':'Valuation','stage':'completed','finalPaths':jsonEncode(['APP_RFO_GL_VALUATION.pdf'])});
    expect(await handle('APP_RFO_GL_VALUATION.pdf'), true);
  });
  test('Revenue completion accepts only latest cycle final letter', () async {
    await db.insert('revenue_reply_cycles', {'applicationId':1,'cycle':2,'requestedAt':'date','requestAuthority':'Authority','stage':'completed','finalLetterPath':'APP_RFO_APPROVED_SPL_CYCLE_2.pdf'});
    expect(await handle('APP_RFO_APPROVED_SPL_CYCLE_1.pdf'), false);
    expect(await handle('APP_RFO_APPROVED_SPL_CYCLE_2.pdf',action:'Print'), true);
  });
  test('Fresh revenue request hands off to pending only after view/print', () async {
    await db.insert('revenue_reply_cycles', {'applicationId':1,'cycle':1,'requestedAt':'date','requestAuthority':'Authority',
      'stage':'pending','requestLetterPath':'APP_RFO_REVENUE_OPINION_REQUEST.pdf'});
    expect(await status(), WorkflowStatus.approved);
    expect(await handle('APP_RFO_PRIVATE_LAND_BRANCH_PERMISSION.pdf'), false);
    expect(await handle('APP_RFO_REVENUE_OPINION_REQUEST.pdf'), true);
    expect(await status(), WorkflowStatus.pendingRevenueOpinion);
  });
  test('Stale request from a previous cycle does not advance the new request', () async {
    await db.insert('revenue_reply_cycles', {'applicationId':1,'cycle':2,'requestedAt':'date','requestAuthority':'Authority',
      'stage':'pending','requestLetterPath':'APP_RFO_REVENUE_OPINION_REQUEST_CYCLE_2.pdf'});
    expect(await handle('APP_RFO_REVENUE_OPINION_REQUEST_CYCLE_1.pdf'), false);
    expect(await status(), WorkflowStatus.approved);
    expect(await handle('APP_RFO_REVENUE_OPINION_REQUEST_CYCLE_2.pdf'), true);
    expect(await status(), WorkflowStatus.pendingRevenueOpinion);
  });
  test('Another caseworker cannot complete this application', () async {
    SessionService.instance.userId = 3;
    await expectLater(handle('APP_RFO_APPROVED_RTC.pdf'), throwsStateError);
    expect(await status(), WorkflowStatus.approved);
  });
}
