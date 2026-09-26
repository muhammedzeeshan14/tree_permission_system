import 'package:flutter/material.dart';
import '../../repositories/officer_repository.dart';

class OfficerDirectoryScreen extends StatefulWidget {
  const OfficerDirectoryScreen({super.key});
  @override
  State<OfficerDirectoryScreen> createState()=>_OfficerDirectoryScreenState();
}
class _OfficerDirectoryScreenState extends State<OfficerDirectoryScreen> {
  final repository=OfficerRepository();
  List<Map<String,dynamic>> officers=[];
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try {final result=await repository.getAll();if(mounted)setState((){officers=result;loading=false;error=null;});}
    catch(e){if(mounted)setState((){error=e.toString();loading=false;});}
  }
  Future<void> edit([Map<String,dynamic>? item]) async {
    final name=TextEditingController(text:item?['name']?.toString()??'');
    final designation=TextEditingController(text:item?['designation']?.toString()??'');
    final address=TextEditingController(text:item?['postingAddress']?.toString()??'');
    String? role=item?['role'] as String?;
    final key=GlobalKey<FormState>();bool saving=false;String? saveError;
    await showDialog<void>(context:context,barrierDismissible:false,builder:(dialogContext)=>StatefulBuilder(builder:(context,setDialogState)=>PopScope(
      canPop:!saving,
      child:AlertDialog(
        title:Text(item==null?'Add Officer':'Edit Officer'),
        content:SizedBox(width:500,child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextFormField(controller:name,enabled:!saving,decoration:const InputDecoration(labelText:'Name'),validator:(v)=>v==null||v.trim().isEmpty?'Enter name':null),
          TextFormField(controller:designation,enabled:!saving,decoration:const InputDecoration(labelText:'Designation'),validator:(v)=>v==null||v.trim().isEmpty?'Enter designation':null),
          TextFormField(controller:address,enabled:!saving,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Officer posting address'),validator:(v)=>v==null||v.trim().isEmpty?'Enter posting address':null),
          DropdownButtonFormField<String>(initialValue:role,decoration:const InputDecoration(labelText:'Role'),items:OfficerRepository.roles.map((r)=>DropdownMenuItem(value:r,child:Text(r))).toList(),onChanged:saving?null:(v)=>setDialogState(()=>role=v),validator:(v)=>v==null?'Select role':null),
          if(saveError!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(saveError!,style:const TextStyle(color:Colors.red))),
        ])))),
        actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),FilledButton(onPressed:saving?null:() async {
          if(!key.currentState!.validate())return;
          setDialogState((){saving=true;saveError=null;});
          try{await repository.save(id:item?['id'] as int?,name:name.text,designation:designation.text,postingAddress:address.text,role:role!);if(dialogContext.mounted)Navigator.pop(dialogContext);}
          catch(e){if(dialogContext.mounted)setDialogState((){saving=false;saveError=e.toString();});}
        },child:Text(saving?'Saving...':'Save'))],
      ),
    )));
    // Let the dialog finish its exit animation before disposing its fields.
    await Future<void>.delayed(const Duration(milliseconds:300));
    name.dispose();designation.dispose();address.dispose();
    if(mounted)await load();
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Officers')),
    floatingActionButton:FloatingActionButton.extended(onPressed:loading?null:()=>edit(),icon:const Icon(Icons.add),label:const Text('Add Officer')),
    body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.fromLTRB(16,16,16,100),children:[
      const Text('Map an officer to each role. Letter addresses use designation and posting address.',style:TextStyle(fontSize:16)),
      const SizedBox(height:12),
      if(officers.isEmpty)const Text('No officers added yet.'),
      for(final officer in officers)Card(child:ListTile(
        title:Text(officer['name'].toString()+' — '+officer['role'].toString()),
        subtitle:Text(OfficerRepository.formatAddress(officer)),isThreeLine:true,
        trailing:IconButton(tooltip:'Edit officer',icon:const Icon(Icons.edit),onPressed:()=>edit(officer)),
        onTap:()=>edit(officer),
      )),
    ]),
  );
}
