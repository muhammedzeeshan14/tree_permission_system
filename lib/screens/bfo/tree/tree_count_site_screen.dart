import '../../../widgets/tree_count_species_dialog.dart';
import 'package:tree_permission_system/widgets/adaptive_layout.dart';
import '../../../widgets/workflow_action.dart';
import 'package:flutter/material.dart';

import '../../../models/tree_count_detail_model.dart';
import '../../../models/tree_count_site_model.dart';
import '../../../repositories/master_repository.dart';
import '../../../repositories/tree_count_detail_repository.dart';
import '../../../repositories/tree_count_site_repository.dart';

class TreeCountSiteScreen extends StatefulWidget {

  final int applicationId;
  final int? siteId;

  const TreeCountSiteScreen({

  super.key,

  required this.applicationId,

  this.siteId,

});

  @override
  State<TreeCountSiteScreen> createState() =>
      _TreeCountSiteScreenState();

}

class _TreeCountSiteScreenState
    extends State<TreeCountSiteScreen> {

  final siteRepo = TreeCountSiteRepository();

  final detailRepo = TreeCountDetailRepository();

  final speciesRepo = MasterRepository();

  final TextEditingController siteController =
      TextEditingController();

  List<Map<String,dynamic>> speciesList=[];

  List<TreeCountDetailModel> rows=[];

  final List<TextEditingController>
    countControllers = [];

  @override
  void initState() {

    super.initState();

    load();

  }

  Future<void> load() async {

  final allSpecies =
      await speciesRepo.getSpecies();

  // Show each species once (timber record preferred); pole/timber
  // category is decided later by measurements.
  final Map<String, Map<String, dynamic>> unique = {};

  for (final species in allSpecies) {
    final name = species["value"]
            ?.toString()
            .trim()
            .toLowerCase() ??
        "";

    if (name.isEmpty) continue;

    final existing = unique[name];

    if (existing == null) {
      unique[name] = species;
      continue;
    }

    final existingGroup = existing["speciesGroup"]
            ?.toString()
            .trim()
            .toUpperCase() ??
        "";

    final currentGroup = species["speciesGroup"]
            ?.toString()
            .trim()
            .toUpperCase() ??
        "";

    if (existingGroup != "TIMBER" &&
        currentGroup == "TIMBER") {
      unique[name] = species;
    }
  }

  speciesList = unique.values.toList();

  if (widget.siteId != null) {

    final sites =
        await siteRepo.getSites(
      widget.applicationId,
    );

    final site = sites.firstWhere(
      (e) => e.id == widget.siteId,
    );

    siteController.text =
        site.siteDetails;

    rows =
        await detailRepo.getBySite(
      widget.siteId!,
    );

    countControllers.clear();

for (final row in rows) {

  countControllers.add(

    TextEditingController(

      text: row.treeCount == 0
          ? ""
          : row.treeCount.toString(),

    ),

  );

}

  } else {

    rows = [

      TreeCountDetailModel(

        siteId: 0,

        speciesId: 0,

        treeCount: 0,

        displayOrder: 1,

      ),

    ];

countControllers.clear();

countControllers.add(

  TextEditingController(),

);

  }

  if (mounted) {
    setState(() {});
  }

}

  void addRow(){

    setState(() {

      rows.add(

        TreeCountDetailModel(

          siteId:0,

          speciesId:0,

          treeCount:0,

          displayOrder:rows.length+1,

        ),

      );

    });
countControllers.add(
  TextEditingController(),
);

  }

  void deleteRow(int index){

    setState(() {

      rows.removeAt(index);

      countControllers[index].dispose();

countControllers.removeAt(index);

    });

  }

  Future<void> saveSite() async {

  try {

    int currentSiteId;

    if (widget.siteId == null) {

      currentSiteId =
          await siteRepo.insert(

        TreeCountSiteModel(

          applicationId:
              widget.applicationId,

          siteDetails:
              siteController.text.trim(),

          displayOrder: 1,

        ),

      );

    } else {

      currentSiteId =
          widget.siteId!;

      await siteRepo.update(

        TreeCountSiteModel(

          id: currentSiteId,

          applicationId:
              widget.applicationId,

          siteDetails:
              siteController.text.trim(),

          displayOrder: 1,

        ),

      );

    }

    await detailRepo.saveAll(

      siteId: currentSiteId,

      items: rows,

    );

    if (!mounted) return;

    Navigator.pop(context, true);

  } catch (e) {

    debugPrint(e.toString());

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(
          e.toString(),
        ),

      ),

    );

  }

}

Future<Map<String, dynamic>?> _showSpeciesSearchDialog() =>
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TreeCountSpeciesDialog(species: speciesList),
    );

  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar:AppBar(

        title:const Text("Tree Count Site"),

      ),

      body:Padding(

        padding:const EdgeInsets.all(16),

        child:Column(

          children:[

            TextField(

              controller:siteController,

              minLines:3,

              maxLines:5,

              decoration:const InputDecoration(

                labelText:"Site Details",

                border:OutlineInputBorder(),

              ),

            ),

            const SizedBox(height:20),

const SizedBox(height: 20),

if (MediaQuery.sizeOf(context).width >= 600) const Row(

  children: [

    SizedBox(
      width: 50,
      child: Text(
        "Sl.No.",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    Expanded(
      flex: 5,
      child: Text(
        "Species",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    SizedBox(
      width: 120,
      child: Text(
        "No. of Trees",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    SizedBox(width: 40),

  ],

),

const Divider(),

            Expanded(

              child:ListView.builder(

                itemCount:rows.length,

                itemBuilder:(context,index){

                  final row=rows[index];

                  final countController =
    countControllers[index];

                  return Card(

                    child:Padding(

                      padding:
                          const EdgeInsets.all(10),

                      child:AdaptiveRow(

                        children:[

                          SizedBox(

                            width:40,

                            child:Text(

                              "${index+1}",

                            ),

                          ),

                          Expanded(

                            flex:4,

                            child:
                                InkWell(

  onTap: () async {

    final selected =
        await _showSpeciesSearchDialog();

    if (!mounted || selected == null) {
      return;
    }

    setState(() {

      row.speciesId =
          (selected["id"] as num).toInt();

    });

  },

  child: InputDecorator(

    decoration:
        const InputDecoration(

      labelText:
          "Species",

      border:
          OutlineInputBorder(),

      suffixIcon:
          Icon(Icons.search),

    ),

    child: Text(

      row.speciesId == 0

          ? "Select Species"

          : speciesList.firstWhere(
              (e) =>
                  e["id"] ==
                  row.speciesId,
              orElse: () =>
                  <String, dynamic>{},
            )["value"] ??
              "Select Species",

    ),

  ),

),

                          ),

                          const SizedBox(width:10),

                          SizedBox(

  width: 80,

  child: TextField(

    controller: countController,

    keyboardType: TextInputType.number,

    decoration: const InputDecoration(
 labelText: 'No. of Trees',

      isDense: true,

    ),

    onChanged: (v) {

      row.treeCount =
          int.tryParse(v) ?? 0;

    },

  ),

),

                          IconButton(

                            onPressed:workflowAction(context, (){

                              deleteRow(index);

                            }),

                            icon:const Icon(

                              Icons.delete,

                              color:Colors.red,

                            ),

                          ),

                        ],

                      ),

                    ),

                  );

                },

              ),

            ),

            SizedBox(

              width:double.infinity,

              child:ElevatedButton.icon(

                onPressed:workflowAction(context, addRow),

                icon:const Icon(Icons.add),

                label:const Text(

                  "ADD SPECIES",

                ),

              ),

            ),

            const SizedBox(height:10),

            SizedBox(

              width:double.infinity,

              child:ElevatedButton(

                onPressed:workflowAction(context, saveSite),

                child:const Text(

                  "FINISH",

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

@override
void dispose() {

  siteController.dispose();

  for (final controller
      in countControllers) {

    controller.dispose();

  }

  super.dispose();

}

}