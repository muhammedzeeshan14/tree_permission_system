import 'package:tree_permission_system/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/section_repository.dart';
import '../../repositories/beat_repository.dart';
import '../../services/session_service.dart';
import '../../widgets/workflow_action.dart';
import '../../widgets/application_refresh_button.dart';

class UserMasterScreen extends StatefulWidget {
  const UserMasterScreen({super.key});
  @override
  State<UserMasterScreen> createState() => _UserMasterScreenState();
}
class _UserMasterScreenState extends State<UserMasterScreen> {
  final repository = UserRepository();
  List<Map<String,dynamic>> users = [];
  bool loading = true;
  String? error;
  bool get canEdit => SessionService.instance.role == 'RFO';
  @override
  void initState() { super.initState(); loadUsers(); }
  Future<void> loadUsers() async {
    try {
      final result = await repository.getAll();
      if (mounted) setState(() { users = result; error = null; });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    if (mounted) setState(() => loading = false);
  }
  Future<void> edit([Map<String,dynamic>? user]) async {
    if (!canEdit) return;
    late List<Map<String, dynamic>> sections;
    late List<Map<String, dynamic>> allBeats;
    try {
      sections = await SectionRepository().getActive();
      allBeats = await BeatRepository().getAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load sections and beats: $e')));
      return;
    }
    if (!mounted) return;
    final name = TextEditingController(text: user?['name']?.toString() ?? '');
    final login = TextEditingController(text: user?['username']?.toString() ?? '');
    final password = TextEditingController();
    String role = user?['role']?.toString() ?? 'BFO';
    int? section = (user?['sectionId'] as num?)?.toInt();
    int? beat = (user?['beatId'] as num?)?.toInt();
    bool active = (user?['isActive'] ?? 1) == 1, visible = false, saving = false;
    String? message;
    if (!sections.any((s) => s['id'] == section)) section = null;
    await showDialog<void>(context: context, barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (context, update) {
        final beats = allBeats.where((b) => b['sectionId'] == section).toList();
        if (!beats.any((b) => b['id'] == beat)) beat = null;
        return AlertDialog(title: Text(user == null ? 'Add User' : 'Edit User'),
          content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, enabled: !saving, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: login, enabled: !saving, decoration: const InputDecoration(labelText: 'Login ID / Username')),
            TextField(controller: password, enabled: !saving, obscureText: !visible, autocorrect: false, enableSuggestions: false,
              decoration: InputDecoration(labelText: user == null ? 'Password' : 'New password (leave blank to keep current)',
                suffixIcon: IconButton(onPressed: () => update(() => visible = !visible), icon: Icon(visible ? Icons.visibility_off : Icons.visibility)))),
            DropdownButtonFormField<String>(
 itemHeight: null,
 isExpanded: true,value: role, decoration: const InputDecoration(labelText: 'Role'),
              items: ['RFO','DRFO','BFO','Case Worker'].map((r) => DropdownMenuItem(value:r,child:Text(r))).toList(),
              onChanged: saving ? null : (v) => update(() { role=v!; if (!{'BFO','DRFO'}.contains(role)) {section=null;beat=null;} })),
            if ({'BFO','DRFO'}.contains(role)) DropdownButtonFormField<int>(key: ValueKey('section-$role-$section'),value: section,isExpanded:true,
              decoration: const InputDecoration(labelText:'Section'),
              items: sections.map((s)=>DropdownMenuItem(value:(s['id'] as num).toInt(),child:Text(s['sectionName'].toString()))).toList(),
              onChanged:saving?null:(v)=>update((){section=v;beat=null;})),
            if(role=='BFO') DropdownButtonFormField<int>(key:ValueKey('beat-$section-$beat'),value:beat,isExpanded:true,
              decoration:const InputDecoration(labelText:'Beat'),
              items:beats.map((b)=>DropdownMenuItem(value:(b['id'] as num).toInt(),child:Text(b['beatName'].toString()))).toList(),
              onChanged:saving?null:(v)=>update(()=>beat=v)),
            SwitchListTile(title:const Text('Active login'),value:active,onChanged:saving?null:(v)=>update(()=>active=v)),
            if(message!=null) Text(message!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
          ]))),
          actions:[
            TextButton(onPressed:saving?null:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
            FilledButton(onPressed:saving?null:() async {
              update((){saving=true;message=null;});
              try {
                final secret=password.text.isEmpty && user!=null ? user['password'].toString() : password.text;
                if(user==null) {
                  await repository.insert(name:name.text.trim(),username:login.text.trim(),password:secret,role:role,sectionId:section,beatId:role=='BFO'?beat:null,isActive:active);
                } else {
                  await repository.update(id:(user['id'] as num).toInt(),name:name.text.trim(),username:login.text.trim(),password:secret,role:role,sectionId:section,beatId:role=='BFO'?beat:null,isActive:active);
                }
                if(dialogContext.mounted) Navigator.pop(dialogContext);
              } catch(e) {if(dialogContext.mounted) update((){saving=false;message=e.toString();});}
            },child:Text(saving?'Saving…':'Save User')),
          ]);
      }));
    name.dispose();login.dispose();password.dispose();
    await loadUsers();
  }
  Future<void> remove(Map<String,dynamic> user) async {
    final confirm=await showDialog<bool>(context:context,builder:(dialogContext)=>AlertDialog(
      title:const Text('Delete User'),content:Text('Delete ${user['name']}? Users linked to applications will be deactivated instead, preserving their records.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('Delete'))]));
    if(confirm!=true)return;
    await repository.delete((user['id'] as num).toInt());
    await loadUsers();
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('User Master'),actions:[ApplicationRefreshButton(onRefresh:loadUsers)]),
    floatingActionButton:canEdit?FloatingActionButton.extended(onPressed:workflowAction(context,()=>edit()),icon:const Icon(Icons.person_add),label:const Text('Add User')):null,
    body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.fromLTRB(12,12,12,90),children:[
      for(final user in users) Card(child:AdaptiveDocumentTile(title:Text(user['name'].toString()),
        subtitle:Text('Login ID: ${user['username']} • ${user['role']}\n${user['sectionName'] ?? ''} ${user['beatName'] ?? ''} • ${user['isActive']==1?'Active':'Inactive'}'),
        trailing:canEdit?Row(mainAxisSize:MainAxisSize.min,children:[IconButton(tooltip:'Edit user',icon:const Icon(Icons.edit),onPressed:workflowAction(context,()=>edit(user))),IconButton(tooltip:'Delete user',icon:const Icon(Icons.delete),onPressed:workflowAction(context,()=>remove(user)))]):null)),
    ]),
  );
}
