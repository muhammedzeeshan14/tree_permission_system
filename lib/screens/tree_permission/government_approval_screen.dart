import 'package:flutter/material.dart';
import '../../models/application_model.dart';
import '../../models/government_approval_model.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/government_approval_repository.dart';
import '../../repositories/tree_officer_repository.dart';
import '../../services/session_service.dart';
import '../../services/drfo_document_service.dart';
import '../../constants/workflow_status.dart';
import '../bfo/wizard/inspection_summary_step.dart';
import '../drfo/drfo_forwarded_application_screen.dart';

class PendingGovernmentApprovalsScreen extends StatefulWidget {
  const PendingGovernmentApprovalsScreen({super.key});
  @override
  State<PendingGovernmentApprovalsScreen> createState()=>_PendingGovernmentApprovalsScreenState();
}
class _PendingGovernmentApprovalsScreenState extends State<PendingGovernmentApprovalsScreen> {
  late Future<List<ApplicationModel>> applications;
  Future<List<ApplicationModel>> load() async => (await ApplicationRepository().getApplications()).where((a)=>a.createdBy==SessionService.instance.userId&&a.status==WorkflowStatus.pendingGovernmentLandApprovals).toList();
  @override
  void initState(){super.initState();applications=load();}
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Pending Government land approvals')),
    body:FutureBuilder<List<ApplicationModel>>(future:applications,builder:(context,snapshot){
      if(snapshot.hasError)return Center(child:Text(snapshot.error.toString()));
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      if(snapshot.data!.isEmpty)return const Center(child:Text('No government applications pending documents.'));
      return ListView(children:[for(final app in snapshot.data!)Card(child:ListTile(title:Text('${app.officeNumber} — ${app.applicantName}'),subtitle:const Text('View request letter / enter received documents'),trailing:const Icon(Icons.chevron_right),onTap:() async {
        await Navigator.push(context,MaterialPageRoute(builder:(_)=>GovernmentApprovalScreen(application:app)));
        if(mounted)setState(()=>applications=load());
      }))]);
    }),
  );
}

class GovernmentApprovalScreen extends StatefulWidget {
  final ApplicationModel application;
  final bool rfo;
  const GovernmentApprovalScreen({super.key,required this.application,this.rfo=false});
  @override
  State<GovernmentApprovalScreen> createState()=>_GovernmentApprovalScreenState();
}
class _GovernmentApprovalScreenState extends State<GovernmentApprovalScreen> {
  final repository=GovernmentApprovalRepository();
  final controllers={for(final key in GovernmentApproval.questions.keys)key:TextEditingController()};
  GovernmentApproval? record;
  List<Map<String,dynamic>> officers=[];
  int step=0;
  bool busy=false,dirty=false;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try {
      final value=await repository.get(widget.application.id!);
      final options=await TreeOfficerRepository().getAll();
      if(!mounted)return;
      if(value==null)throw StateError('Government document request not found.');
      for(final key in controllers.keys){controllers[key]!.text=value.answers[key]??'';}
      setState((){record=value;officers=options;});
    }catch(e){if(mounted)setState(()=>error=e.toString());}
  }
  @override
  void dispose(){for(final c in controllers.values){c.dispose();}super.dispose();}
  Map<String,String> get answers=>{for(final entry in controllers.entries)entry.key:entry.value.text};
  Future<void> run(Future<void> Function() action) async {
    if(busy)return;setState(()=>busy=true);
    try{await action();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> save({bool submit=false}) async {
    record=await repository.saveAnswers(record!,answers,rfo:widget.rfo,submit:submit);dirty=false;
  }
  Future<void> date(String key) async {
    final selected=await showDatePicker(context:context,initialDate:DateTime.tryParse(controllers[key]!.text)??DateTime.now(),firstDate:DateTime(1900),lastDate:DateTime(2100));
    if(selected!=null&&mounted)setState((){controllers[key]!.text=selected.toIso8601String().split('T').first;dirty=true;});
  }
  Widget field(String key) {
    if(key=='nature')return DropdownButtonFormField<String>(initialValue:GovernmentApproval.natures.contains(controllers[key]!.text)?controllers[key]!.text:null,isExpanded:true,items:GovernmentApproval.natures.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:busy?null:(v)=>setState((){controllers[key]!.text=v??'';dirty=true;}),decoration:const InputDecoration(border:OutlineInputBorder()));
    final isDate=key=='letterDate'||key=='receivedDate';
    return TextField(controller:controllers[key],enabled:!busy,readOnly:isDate,onTap:isDate?()=>date(key):null,onChanged:(_)=>setState(()=>dirty=true),decoration:InputDecoration(border:const OutlineInputBorder(),suffixIcon:isDate?const Icon(Icons.calendar_month):null));
  }
  Widget details()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(widget.rfo?'Review government document details':'Enter government document details',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:16),
    for(final entry in GovernmentApproval.questions.entries)Padding(padding:const EdgeInsets.only(bottom:16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(flex:2,child:Padding(padding:const EdgeInsets.only(top:12),child:Text(entry.value))),const SizedBox(width:12),
      Expanded(flex:3,child:Row(children:[Expanded(child:field(entry.key)),if(widget.rfo)Tooltip(message:'Approve this answer',child:Checkbox(value:!dirty&&record!.approvedFields.contains(entry.key),onChanged:busy?null:(value)=>run(() async {await save();record=await repository.approveField(record!,entry.key,value??false);}))),])),
    ])),
    if(widget.rfo)const Text('Tick the box beside each answer to approve it. Editing an answer clears the reply approvals.'),
  ]);
  Future<void> finalize() async {
    if(!record!.allApproved)throw StateError('Approve all reply fields first.');
    final oldDate=widget.application.rfoApprovalDate;final now=DateTime.now().toIso8601String();widget.application.rfoApprovalDate=now;
    try {
      final files=await DrfoDocumentService().generateGovernmentLandLetters(widget.application,record!,afterReply:true);
      await repository.finishReviewDocuments(record!,files.map((file)=>file.path).toList(),now);
      widget.application.status=WorkflowStatus.completed;
      if(mounted)Navigator.pop(context,true);
    }catch(_){widget.application.rfoApprovalDate=oldDate;rethrow;}
  }
  Widget finalPage()=>ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Government land — Final Approval',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:16),
    Text('Reply nature: ${record!.answers['nature']??''}'),const SizedBox(height:16),
    if(GovernmentApproval.natures.contains(record!.answers['nature'])) ...[
      DropdownButtonFormField<int>(initialValue:record!.treeOfficerId,isExpanded:true,decoration:const InputDecoration(labelText:'Select Tree officer',border:OutlineInputBorder()),items:officers.map((r)=>DropdownMenuItem(value:r['id'] as int,child:Text(r['name'].toString()))).toList(),onChanged:busy?null:(id){if(id!=null)run(() async {record=await repository.saveReviewOfficer(record!,id);});}),
      const SizedBox(height:16),Text(record!.answers['nature']=='Not satisfied'?'Final Approval generates the auction DO letter and Taggu Bele Patti and completes the application.':'Final Approval generates the RFO GL valuation letter with the approved reply reference and completes the application.'),
    ] else const Text('Select Satisfied or Not satisfied in the reply details and approve every answer.'),
  ]);
  @override
  Widget build(BuildContext context){
    if(error!=null)return Scaffold(appBar:AppBar(title:const Text('Government land approval')),body:Center(child:Text(error!)));
    if(record==null)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return PopScope(canPop:!busy,child:Scaffold(appBar:AppBar(title:Text('${widget.application.officeNumber} — Government land')),
      body:Column(children:[
        if(!widget.rfo)Padding(padding:const EdgeInsets.all(8),child:OutlinedButton.icon(icon:const Icon(Icons.print),label:const Text('View / Print Request Letter'),onPressed:busy?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DRFOForwardedApplicationScreen(application:widget.application,rfoApprovedOnly:true,screenTitle:'Government Documents Request'))))),
        Expanded(child:step==0?InspectionSummaryStep(application:widget.application,showNavigationButtons:false,onBack:(){},onNext:(){}):step==1?details():finalPage()),
        if(busy)const LinearProgressIndicator(),
        Padding(padding:const EdgeInsets.all(12),child:Wrap(spacing:12,runSpacing:8,alignment:WrapAlignment.end,children:[
          OutlinedButton(onPressed:busy?null:(){if(step>0) {
            setState(()=>step--);
          } else {
            Navigator.pop(context);
          }},child:const Text('Back')),
          if(step>0)OutlinedButton(onPressed:busy?null:()=>run(() async {if(step==1)await save();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Draft saved.')));}),child:const Text('Save Draft')),
          if(widget.rfo&&step>0)OutlinedButton(onPressed:busy?null:()=>run(() async {if(step==1)await save();await repository.returnForCorrection(record!);if(mounted)Navigator.pop(context,true);}),child:const Text('Return for correction')),
          if(step==0)FilledButton(onPressed:busy?null:()=>setState(()=>step=1),child:Text(widget.rfo?'Review document details':'Enter document details')),
          if(step==1&&!widget.rfo)FilledButton(onPressed:busy?null:()=>run(() async {await save(submit:true);if(mounted)Navigator.pop(context,true);}),child:const Text('Send for RFO approval')),
          if(step==1&&widget.rfo)FilledButton(onPressed:busy||dirty||!record!.allApproved?null:()=>setState(()=>step=2),child:const Text('Next')),
          if(step==2&&record!.allApproved)FilledButton(onPressed:busy?null:()=>run(finalize),child:const Text('Final Approval')),
        ])),
      ]),
    ));
  }
}
