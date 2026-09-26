import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/government_approval_model.dart';
import '../constants/workflow_status.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';
import '../services/session_service.dart';

class GovernmentApprovalRepository {
  final Database? databaseOverride;
  GovernmentApprovalRepository({this.databaseOverride});
  Future<Database> get _db async=>databaseOverride??await DatabaseHelper.instance.database;
  static Future<void> createTable(DatabaseExecutor db) async {
    await db.execute("CREATE TABLE IF NOT EXISTS government_approvals (applicationId INTEGER PRIMARY KEY, permissionType TEXT NOT NULL DEFAULT '', khataGiven INTEGER, treeOfficerId INTEGER, stage TEXT NOT NULL DEFAULT 'draft', requestDate TEXT NOT NULL DEFAULT '', requestLetterPath TEXT NOT NULL DEFAULT '', answers TEXT NOT NULL DEFAULT '{}', approvedFields TEXT NOT NULL DEFAULT '[]', finalPaths TEXT NOT NULL DEFAULT '[]', finalDate TEXT NOT NULL DEFAULT '', revision INTEGER NOT NULL DEFAULT 0)");
  }
  Future<GovernmentApproval?> get(int id) async {
    if (OnlineMode.enabled) {
      try {
        final rows=await OnlineDatabase.select('government_approvals',equals:{'applicationId':id},limit:1);
        return rows.isEmpty?null:GovernmentApproval.fromMap(rows.single);
      } catch (e) {
        debugPrint('online get government_approvals failed, falling back to local: $e');
      }
    }
    final rows=await (await _db).query('government_approvals',where:'applicationId=?',whereArgs:[id]);
    return rows.isEmpty?null:GovernmentApproval.fromMap(rows.single);
  }
  Future<Map<String,Object?>> _authorize(DatabaseExecutor db,int id,String role,String status) async {
    final rows=await db.query('applications',where:'id=?',whereArgs:[id]);
    if(rows.isEmpty)throw StateError('Application not found.');
    final app=rows.single;final session=SessionService.instance;
    if(session.role!=role||session.userId==null||(role=='Case Worker'&&app['createdBy']!=session.userId))throw StateError('Application is not available to this login.');
    if(!GovernmentApproval.isGovernment(app['applicationType'].toString())||app['status']!=status)throw StateError('Application has moved to another stage. Reopen it.');
    return app;
  }
  Future<void> _check(DatabaseExecutor db,GovernmentApproval record,String role,String stage) async {
    await _authorize(db,record.applicationId,role,stage=='pending'?WorkflowStatus.pendingGovernmentLandApprovals:WorkflowStatus.pendingRFOApproval);
    final rows=await db.query('government_approvals',where:'applicationId=?',whereArgs:[record.applicationId]);
    if(rows.isEmpty||rows.single['stage']!=stage||rows.single['revision']!=record.revision)throw StateError('Details changed. Reopen the application.');
  }
  Future<void> _officer(DatabaseExecutor db,int? id) async {
    if(id==null||(await db.query('tree_officer_master',where:'id=?',whereArgs:[id])).isEmpty)throw StateError('Select Tree officer.');
  }
  Future<GovernmentApproval> _update(DatabaseExecutor db,GovernmentApproval record,Map<String,Object?> values) async {
    await db.update('government_approvals',{...values,'revision':record.revision+1},where:'applicationId=?',whereArgs:[record.applicationId]);
    return GovernmentApproval.fromMap((await db.query('government_approvals',where:'applicationId=?',whereArgs:[record.applicationId])).single);
  }
  Future<void> _audit(DatabaseExecutor db,int id,String action,{String details=''}) async {
    final app=(await db.query('applications',where:'id=?',whereArgs:[id])).single;
    await db.insert('application_history',{'officeNumber':app['officeNumber'],'action':action,'remarks':details,'actionBy':SessionService.instance.name,'actionDate':DateTime.now().toIso8601String()});
  }
  Future<Map<String,dynamic>> _onlineAuthorize(int id,String role,String status) async {
    final rows=await OnlineDatabase.select('applications',equals:{'id':id},limit:1);
    if(rows.isEmpty)throw StateError('Application not found.');
    final app=rows.single;final session=SessionService.instance;
    if(session.role!=role||session.userId==null||(role=='Case Worker'&&app['createdBy']!=session.userId))throw StateError('Application is not available to this login.');
    if(!GovernmentApproval.isGovernment(app['applicationType'].toString())||app['status']!=status)throw StateError('Application has moved to another stage. Reopen it.');
    return app;
  }
  Future<void> _onlineCheck(GovernmentApproval record,String role,String stage) async {
    await _onlineAuthorize(record.applicationId,role,stage=='pending'?WorkflowStatus.pendingGovernmentLandApprovals:WorkflowStatus.pendingRFOApproval);
    final rows=await OnlineDatabase.select('government_approvals',equals:{'applicationId':record.applicationId},limit:1);
    if(rows.isEmpty||rows.single['stage']!=stage||rows.single['revision']!=record.revision)throw StateError('Details changed. Reopen the application.');
  }
  Future<void> _onlineOfficer(int? id) async {
    if(id==null)throw StateError('Select Tree officer.');
    final rows=await OnlineDatabase.select('tree_officer_master',equals:{'id':id},limit:1);
    if(rows.isEmpty)throw StateError('Select Tree officer.');
  }
  Future<GovernmentApproval> _onlineUpdate(GovernmentApproval record,Map<String,Object?> values) async {
    final current=await OnlineDatabase.select('government_approvals',equals:{'applicationId':record.applicationId},limit:1);
    final merged=Map<String,dynamic>.from(current.single)..addAll(Map<String,dynamic>.from(values));
    merged['revision']=record.revision+1;
    merged.remove('id');
    await OnlineDatabase.delete('government_approvals',column:'applicationId',value:record.applicationId);
    await OnlineDatabase.insert('government_approvals',merged);
    return GovernmentApproval.fromMap((await OnlineDatabase.select('government_approvals',equals:{'applicationId':record.applicationId},limit:1)).single);
  }
  Future<void> _onlineAudit(int id,String action,{String details=''}) async {
    final app=(await OnlineDatabase.select('applications',equals:{'id':id},limit:1)).single;
    await OnlineDatabase.insert('application_history',{'officeNumber':app['officeNumber'],'action':action,'remarks':details,'actionBy':SessionService.instance.name,'actionDate':DateTime.now().toIso8601String()});
  }
  Future<bool> _onlineHasApprovedTree(int applicationId) async {
    final trees=await OnlineDatabase.select('trees',equals:{'applicationId':applicationId});
    if(trees.isEmpty)return false;
    final masters=await OnlineDatabase.select('master_data');
    final codeById=<int,String>{for(final m in masters)(m['id'] as num).toInt():(m['code']?.toString()??'')};
    final approvals=await OnlineDatabase.select('rfo_item_approvals',equals:{'applicationId':applicationId});
    for(final t in trees){
      final code=(codeById[(t['recommendationTypeId'] as num?)?.toInt()]??'').trim().toUpperCase();
      if(!{'FULL','BRANCH','TWIG','TOP'}.contains(code))continue;
      final treeId=(t['id'] as num?)?.toInt();
      final ok=approvals.any((a)=>a['itemKey']=='TREE'&&(a['itemId'] as num?)?.toInt()==treeId&&(a['decision']=='Approve'||a['decision']=='Modify'));
      if(ok)return true;
    }
    return false;
  }
  Future<GovernmentApproval> saveOptions(int id,String type,bool? khata,int? officer) async {
    if (OnlineMode.enabled) {
      try {
        await _onlineAuthorize(id,'RFO',WorkflowStatus.pendingRFOApproval);
        if(type.isNotEmpty&&!GovernmentApproval.types.contains(type))throw ArgumentError('Select Auction or Valuation.');
        final rows=await OnlineDatabase.select('government_approvals',equals:{'applicationId':id},limit:1);
        if(rows.isNotEmpty&&rows.single['stage']!='draft')throw StateError('Open the government document reply workflow.');
        if(officer!=null)await _onlineOfficer(officer);
        if(rows.isEmpty)await OnlineDatabase.insert('government_approvals',{'applicationId':id});
        final record=GovernmentApproval.fromMap((await OnlineDatabase.select('government_approvals',equals:{'applicationId':id},limit:1)).single);
        return _onlineUpdate(record,{'permissionType':type,'khataGiven':type=='Valuation'&&khata!=null?(khata?1:0):null,'treeOfficerId':officer});
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online saveOptions government_approvals failed, falling back to local: $e');
      }
    }
    final db=await _db;
    return db.transaction((tx) async {
      await _authorize(tx,id,'RFO',WorkflowStatus.pendingRFOApproval);
      if(type.isNotEmpty&&!GovernmentApproval.types.contains(type))throw ArgumentError('Select Auction or Valuation.');
      final rows=await tx.query('government_approvals',where:'applicationId=?',whereArgs:[id]);
      if(rows.isNotEmpty&&rows.single['stage']!='draft')throw StateError('Open the government document reply workflow.');
      if(officer!=null)await _officer(tx,officer);
      if(rows.isEmpty)await tx.insert('government_approvals',{'applicationId':id});
      final record=GovernmentApproval.fromMap((await tx.query('government_approvals',where:'applicationId=?',whereArgs:[id])).single);
      return _update(tx,record,{'permissionType':type,'khataGiven':type=='Valuation'&&khata!=null?(khata?1:0):null,'treeOfficerId':officer});
    });
  }
  static String? validateOptions(GovernmentApproval record) {
    if(!GovernmentApproval.types.contains(record.permissionType))return 'Select RFO permission type: Auction or Valuation.';
    if(record.treeOfficerId==null)return 'Select Tree officer.';
    if(record.permissionType=='Valuation'&&record.khataGiven==null)return 'Select whether khata details are given and select Tree officer.';
    return null;
  }
  Future<void> finishInitial(GovernmentApproval record,List<String> paths,String date) async {
    final error=validateOptions(record);if(error!=null)throw StateError(error);
    final pending=record.permissionType=='Valuation'&&record.khataGiven==false;
    if(paths.length!=(record.permissionType=='Auction'?2:1)||paths.any((p)=>p.isEmpty))throw StateError('Generate all required letters first.');
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(record,'RFO','draft');
        await _onlineOfficer(record.treeOfficerId);
        if(!await _onlineHasApprovedTree(record.applicationId))throw StateError('At least one recommended tree must be approved by RFO.');
        await _onlineUpdate(record,pending?{'stage':'pending','requestDate':date,'requestLetterPath':paths.single}:{'stage':'completed','finalDate':date,'finalPaths':jsonEncode(paths)});
        await OnlineDatabase.update('applications',record.applicationId,{'status':pending?WorkflowStatus.pendingGovernmentLandApprovals:WorkflowStatus.completed,'rfoApprovalDate':date});
        await _onlineAudit(record.applicationId,pending?'Government valuation documents requested':'Government ${record.permissionType} approved; application completed');
        return;
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online finishInitial government_approvals failed, falling back to local: $e');
      }
    }
    await (await _db).transaction((tx) async {
      await _check(tx,record,'RFO','draft');
      await _officer(tx,record.treeOfficerId);
      final trees=await tx.rawQuery("SELECT t.id FROM trees t JOIN master_data m ON m.id=t.recommendationTypeId JOIN rfo_item_approvals a ON a.applicationId=t.applicationId AND a.itemKey='TREE' AND a.itemId=t.id WHERE t.applicationId=? AND UPPER(TRIM(m.code)) IN ('FULL','BRANCH','TWIG','TOP') AND a.decision IN ('Approve','Modify')",[record.applicationId]);
      if(trees.isEmpty)throw StateError('At least one recommended tree must be approved by RFO.');
      await _update(tx,record,pending?{'stage':'pending','requestDate':date,'requestLetterPath':paths.single}:{'stage':'completed','finalDate':date,'finalPaths':jsonEncode(paths)});
      await tx.update('applications',{'status':pending?WorkflowStatus.pendingGovernmentLandApprovals:WorkflowStatus.completed,'rfoApprovalDate':date},where:'id=?',whereArgs:[record.applicationId]);
      await _audit(tx,record.applicationId,pending?'Government valuation documents requested':'Government ${record.permissionType} approved; application completed');
    });
  }
  Future<GovernmentApproval> saveAnswers(GovernmentApproval record,Map<String,String> answers,{bool rfo=false,bool submit=false}) async {
    final values={for(final key in GovernmentApproval.questions.keys)key:(answers[key]??'').trim()};
    if(submit){final error=GovernmentApproval.validateAnswers(values);if(error!=null)throw StateError(error);}
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(record,rfo?'RFO':'Case Worker',rfo?'review':'pending');
        final changed=jsonEncode(values)!=jsonEncode(record.answers);
        final next=await _onlineUpdate(record,{'answers':jsonEncode(values),if(changed)'approvedFields':'[]',if(submit&&!rfo)'stage':'review'});
        if(submit&&!rfo) {
          await OnlineDatabase.update('applications',record.applicationId,{'status':WorkflowStatus.pendingRFOApproval});
          await _onlineAudit(record.applicationId,'Government document reply sent for RFO approval',details:jsonEncode(values));
        }
        return next;
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online saveAnswers government_approvals failed, falling back to local: $e');
      }
    }
    return (await _db).transaction((tx) async {
      await _check(tx,record,rfo?'RFO':'Case Worker',rfo?'review':'pending');
      final changed=jsonEncode(values)!=jsonEncode(record.answers);
      final next=await _update(tx,record,{'answers':jsonEncode(values),if(changed)'approvedFields':'[]',if(submit&&!rfo)'stage':'review'});
      if(submit&&!rfo) {
        await tx.update('applications',{'status':WorkflowStatus.pendingRFOApproval},where:'id=?',whereArgs:[record.applicationId]);
        await _audit(tx,record.applicationId,'Government document reply sent for RFO approval',details:jsonEncode(values));
      }
      return next;
    });
  }
  Future<GovernmentApproval> approveField(GovernmentApproval record,String field,bool approved) async {
    if(!GovernmentApproval.questions.containsKey(field))throw ArgumentError('Unknown field.');
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(record,'RFO','review');final fields={...record.approvedFields};
        if(approved) {
          fields.add(field);
        } else {
          fields.remove(field);
        }
        return _onlineUpdate(record,{'approvedFields':jsonEncode(fields.toList())});
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online approveField government_approvals failed, falling back to local: $e');
      }
    }
    return (await _db).transaction((tx) async {
      await _check(tx,record,'RFO','review');final fields={...record.approvedFields};
      if(approved) {
        fields.add(field);
      } else {
        fields.remove(field);
      }
      return _update(tx,record,{'approvedFields':jsonEncode(fields.toList())});
    });
  }
  Future<GovernmentApproval> saveReviewOfficer(GovernmentApproval record,int id) async {
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(record,'RFO','review');await _onlineOfficer(id);return _onlineUpdate(record,{'treeOfficerId':id});
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online saveReviewOfficer government_approvals failed, falling back to local: $e');
      }
    }
    return (await _db).transaction((tx) async {
    await _check(tx,record,'RFO','review');await _officer(tx,id);return _update(tx,record,{'treeOfficerId':id});
  });}
  Future<void> returnForCorrection(GovernmentApproval record) async {
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(record,'RFO','review');await _onlineUpdate(record,{'stage':'pending','approvedFields':'[]'});
        await OnlineDatabase.update('applications',record.applicationId,{'status':WorkflowStatus.pendingGovernmentLandApprovals});
        await _onlineAudit(record.applicationId,'Government document reply returned for correction',details:jsonEncode(record.answers));
        return;
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online returnForCorrection government_approvals failed, falling back to local: $e');
      }
    }
    await (await _db).transaction((tx) async {
      await _check(tx,record,'RFO','review');await _update(tx,record,{'stage':'pending','approvedFields':'[]'});
      await tx.update('applications',{'status':WorkflowStatus.pendingGovernmentLandApprovals},where:'id=?',whereArgs:[record.applicationId]);
      await _audit(tx,record.applicationId,'Government document reply returned for correction',details:jsonEncode(record.answers));
    });
  }
  Future<void> finishReview(GovernmentApproval record,String path,String date) => finishReviewDocuments(record,[path],date);
  Future<void> finishReviewDocuments(GovernmentApproval record,List<String> paths,String date) async {
    final auction=record.answers['nature']=='Not satisfied';
    if(!record.allApproved||paths.length!=(auction?2:1)||paths.any((path)=>path.isEmpty))throw StateError('Approve all reply fields and generate all required letters first.');
    if(record.permissionType!='Valuation'||record.khataGiven!=false||record.requestLetterPath.isEmpty)throw StateError('A saved valuation document request is required.');
    if (OnlineMode.enabled) {
      try {
        await _onlineCheck(record,'RFO','review');await _onlineOfficer(record.treeOfficerId);
        await _onlineUpdate(record,{'stage':'completed','finalPaths':jsonEncode(paths),'finalDate':date});
        await OnlineDatabase.update('applications',record.applicationId,{'status':WorkflowStatus.completed,'rfoApprovalDate':date});
        await _onlineAudit(record.applicationId,auction?'Government document reply not satisfied; auction DO and Taggu Bele Patti approved; application completed':'Government valuation approved after document reply; application completed',details:jsonEncode(record.answers));
        return;
      } catch (e) {
        if(e is StateError||e is ArgumentError)rethrow;
        debugPrint('online finishReviewDocuments government_approvals failed, falling back to local: $e');
      }
    }
    await (await _db).transaction((tx) async {
      await _check(tx,record,'RFO','review');await _officer(tx,record.treeOfficerId);
      await _update(tx,record,{'stage':'completed','finalPaths':jsonEncode(paths),'finalDate':date});
      await tx.update('applications',{'status':WorkflowStatus.completed,'rfoApprovalDate':date},where:'id=?',whereArgs:[record.applicationId]);
      await _audit(tx,record.applicationId,auction?'Government document reply not satisfied; auction DO and Taggu Bele Patti approved; application completed':'Government valuation approved after document reply; application completed',details:jsonEncode(record.answers));
    });
  }
}
