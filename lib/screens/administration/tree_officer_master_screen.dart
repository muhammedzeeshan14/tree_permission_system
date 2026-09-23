import 'package:flutter/material.dart';
import '../../repositories/tree_officer_repository.dart';

class TreeOfficerMasterScreen extends StatefulWidget {
  const TreeOfficerMasterScreen({super.key});
  @override
  State<TreeOfficerMasterScreen> createState() => _TreeOfficerMasterScreenState();
}

class _TreeOfficerMasterScreenState extends State<TreeOfficerMasterScreen> {
  final repository=TreeOfficerRepository();
  final formKey=GlobalKey<FormState>();
  final names=<TextEditingController>[];
  List<Map<String,dynamic>> rows=[];
  bool loading=true, saving=false;
  String? loadError;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final result=await repository.getAll();
      if (!mounted) return;
      for (final c in names) { c.dispose(); }
      names.clear();
      rows=result.map((r)=>Map<String,dynamic>.from(r)).toList();
      names.addAll(rows.map((r)=>TextEditingController(text:r['name'].toString())));
    } catch(e) { loadError=e.toString(); }
    if(mounted) setState(()=>loading=false);
  }
  @override
  void dispose() { for(final c in names) { c.dispose(); } super.dispose(); }
  Future<void> save() async {
    if(!formKey.currentState!.validate()) return;
    setState(()=>saving=true);
    try {
      await repository.saveAll([for(int i=0;i<rows.length;i++) {...rows[i], 'name':names[i].text}]);
      setState(()=>loading=true);
      await load();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tree officer mappings saved.')));
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));
    } finally { if(mounted) setState(()=>saving=false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Tree Officer')),
    body:loading ? const Center(child:CircularProgressIndicator())
      : loadError != null ? Center(child:Text(loadError!))
      : Form(key:formKey, child:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('Felling Permission Mapping',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:16),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:SizedBox(
          width:MediaQuery.sizeOf(context).width < 650 ? 620 : MediaQuery.sizeOf(context).width-32,
          child:Column(children:[for(int i=0;i<rows.length;i++) Padding(
            padding:const EdgeInsets.only(bottom:16),
            child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Expanded(child:TextFormField(controller:names[i],enabled:!saving,
                decoration:InputDecoration(labelText:rows[i]['code'].toString(),border:const OutlineInputBorder()),
                validator:(v)=>v==null || v.trim().isEmpty ? 'Enter officer name' : null)),
              const SizedBox(width:16),
              Expanded(flex:2,child:DropdownButtonFormField<int>(
                value:rows[i]['requiresFellingPermission'] as int?,isExpanded:true,
                decoration:const InputDecoration(labelText:'Felling permission',border:OutlineInputBorder()),
                items:const [
                  DropdownMenuItem(value:1,child:Text('Require felling permission')),
                  DropdownMenuItem(value:0,child:Text('Not required felling permission')),
                ],
                onChanged:saving ? null : (value)=>setState(()=>rows[i]['requiresFellingPermission']=value),
                validator:(v)=>v==null ? 'Select felling permission mapping' : null,
              )),
            ]),
          )]),
        )),
        Align(alignment:Alignment.centerRight,child:ElevatedButton.icon(
          onPressed:saving ? null : save,icon:const Icon(Icons.save),label:Text(saving ? 'Saving...' : 'Save mappings'))),
      ])),
  );
}
