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

Future<Map<String, dynamic>?> _showSpeciesSearchDialog() async {

  final searchController =
      TextEditingController();

  List<Map<String, dynamic>> filtered =
      List<Map<String, dynamic>>.from(
    speciesList,
  );

  final result =
      await showDialog<Map<String, dynamic>>(
    context: context,

    builder: (dialogContext) {

      return StatefulBuilder(

        builder:
            (dialogContext, setDialogState) {

          void search(String value) {

            final query =
                value.trim().toLowerCase();

            setDialogState(() {

              if (query.isEmpty) {

                filtered =
                    List<Map<String, dynamic>>.from(
                  speciesList,
                );

              } else {

                filtered =
                    speciesList.where((species) {

                  final name =
                      species["value"]
                          ?.toString()
                          .toLowerCase() ??
                      "";

                  return name.contains(query);

                }).toList();

              }

            });

          }

          return AlertDialog(

            title:
                const Text("Select Species"),

            content: SizedBox(

              width: 450,

              height: 500,

              child: Column(

                children: [

                  TextField(

                    controller:
                        searchController,

                    autofocus: true,

                    decoration:
                        const InputDecoration(

                      labelText:
                          "Search Species",

                      hintText:
                          "Type species name",

                      prefixIcon:
                          Icon(Icons.search),

                      border:
                          OutlineInputBorder(),

                    ),

                    onChanged: search,

                  ),

                  const SizedBox(height: 12),

                  Expanded(

                    child:
                        filtered.isEmpty

                            ? const Center(
                                child: Text(
                                  "No species found",
                                ),
                              )

                            : ListView.builder(

                                itemCount:
                                    filtered.length,

                                itemBuilder:
                                    (context, index) {

                                  final species =
                                      filtered[index];

                                  return ListTile(

                                    title: Text(
                                      species["value"]
                                          .toString(),
                                    ),

                                    subtitle:
                                        Text(
                                      species[
                                                  "speciesGroup"]
                                              ?.toString() ??
                                          "",
                                    ),

                                    onTap: () {

                                      Navigator.pop(
                                        dialogContext,
                                        species,
                                      );

                                    },

                                  );

                                },

                              ),

                  ),

                ],

              ),

            ),

            actions: [

              TextButton(

                onPressed: () {

                  Navigator.pop(
                    dialogContext,
                  );

                },

                child:
                    const Text("CANCEL"),

              ),

            ],

          );
        },

      );
    },
  );

  searchController.dispose();

  return result;
}

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

const Row(

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

                      child:Row(

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

    if (selected == null) {
      return;
    }

    setState(() {

      row.speciesId =
          selected["id"];

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

      isDense: true,

    ),

    onChanged: (v) {

      row.treeCount =
          int.tryParse(v) ?? 0;

    },

  ),

),

                          IconButton(

                            onPressed:(){

                              deleteRow(index);

                            },

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

                onPressed:addRow,

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

                onPressed:saveSite,

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