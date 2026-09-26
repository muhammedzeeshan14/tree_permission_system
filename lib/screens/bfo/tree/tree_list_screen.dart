import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../database/database_helper.dart';
import '../../../models/application_model.dart';
import '../../../models/tree_model.dart';

import '../../../repositories/application_repository.dart';
import '../../../repositories/master_repository.dart';
import '../../../repositories/tree_repository.dart';

import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

import 'add_edit_tree_screen.dart';
import '../../../services/tree_numbering_service.dart';

class TreeListScreen extends StatefulWidget {
  final int applicationId;

  const TreeListScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<TreeListScreen> createState() =>
      _TreeListScreenState();
}

class _TreeListScreenState
    extends State<TreeListScreen> {

  //----------------------------------------------------------
  // Repositories
  //----------------------------------------------------------

  final TreeRepository _treeRepository =
      TreeRepository();

  final ApplicationRepository
      _applicationRepository =
      ApplicationRepository();

  //----------------------------------------------------------
  // Database
  //----------------------------------------------------------

  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance;

  //----------------------------------------------------------
  // Data
  //----------------------------------------------------------

  ApplicationModel? application;

  List<TreeModel> allTrees = [];

  // Sandal transport destination (SPL/SGL only).
  List<Map<String, dynamic>> sandalDestinations = [];
  int? selectedSandalDestinationId;
  bool sandalDestinationIsOther = false;
  final TextEditingController sandalCustomController =
      TextEditingController();

  List<TreeModel> filteredTrees = [];

  Map<int, String> speciesMap = {};

  Map<int,String> recommendationTypeMap = {};

Map<int,String> recommendationReasonMap = {};

  bool loading = true;

  //----------------------------------------------------------
  // Search
  //----------------------------------------------------------

  final TextEditingController
      searchController =
      TextEditingController();

  //----------------------------------------------------------
  // Init
  //----------------------------------------------------------

  @override
  void initState() {

    super.initState();

    searchController.addListener(
      _searchTrees,
    );

    _initialize();

  }

  //----------------------------------------------------------
  // Dispose
  //----------------------------------------------------------

  @override
  void dispose() {

    searchController.dispose();
    sandalCustomController.dispose();

    super.dispose();

  }

  //----------------------------------------------------------
  // Initialize
  //----------------------------------------------------------

  Future<void> _initialize() async {

    await _loadApplication();

    await _loadSpecies();

    await _loadTrees();

    await _loadSandalDestinations();

    if (mounted) {

      setState(() {

        loading = false;

      });

    }

  }

  bool get _isSandalApplication {
    final type = application?.applicationType
            .trim()
            .toUpperCase() ??
        "";
    return type == "SPL" || type == "SGL";
  }

  Future<void> _loadSandalDestinations() async {
    if (!_isSandalApplication || application == null) return;

    final all = await MasterRepository().getMasters(
      "Sandal Destination",
    );

    final type = application!.applicationType
        .trim()
        .toUpperCase();

    sandalDestinations = all.where((item) {
      if (item["isActive"] != 1 &&
          item["id"] != application!.sandalDestinationId) {
        return false;
      }
      final mapping =
          item["parentCode"]?.toString().trim().toUpperCase() ?? "";
      return mapping.isEmpty ||
          mapping == "BOTH" ||
          mapping == type;
    }).toList();

    if (application!.sandalDestinationId != null &&
        sandalDestinations.any((item) =>
            item["id"] ==
            application!.sandalDestinationId)) {
      selectedSandalDestinationId =
          application!.sandalDestinationId;
      sandalDestinationIsOther = false;
    } else if ((application!.sandalDestinationCustom)
        .trim()
        .isNotEmpty) {
      selectedSandalDestinationId = -1;
      sandalDestinationIsOther = true;
      sandalCustomController.text =
          application!.sandalDestinationCustom;
    }
  }

  //----------------------------------------------------------
  // Load Application
  //----------------------------------------------------------

  Future<void> _loadApplication() async {

    application =
        await _applicationRepository.getById(
      widget.applicationId,
    );

  }

  //----------------------------------------------------------
  // Load Species
  //----------------------------------------------------------

  Future<void> _loadSpecies() async {

  final Database db =
      await _dbHelper.database;

  //----------------------------------------------------------
  // Species
  //----------------------------------------------------------

  final species = await db.query(

    "master_data",

    where:
        "masterType=? AND isActive=1",

    whereArgs: const [

      "Species",

    ],

    orderBy: "displayOrder",

  );

  speciesMap = {

    for (final row in species)

      row["id"] as int:
          row["value"].toString(),

  };

  //----------------------------------------------------------
  // Recommendation Types
  //----------------------------------------------------------

  final recommendationTypes =
      await db.query(

    "master_data",

    where:
        "masterType=? AND isActive=1",

    whereArgs: const [

      "Recommendation Type",

    ],

    orderBy: "displayOrder",

  );

  recommendationTypeMap = {

    for (final row
        in recommendationTypes)

      row["id"] as int:
          row["value"].toString(),

  };

  //----------------------------------------------------------
  // Recommendation Reasons
  //----------------------------------------------------------

  final recommendationReasons =
      await db.query(

    "master_data",

    where:
        "masterType=? AND isActive=1",

    whereArgs: const [

      "Recommendation Reason",

    ],

    orderBy: "displayOrder",

  );

  recommendationReasonMap = {

    for (final row
        in recommendationReasons)

      row["id"] as int:
          row["value"].toString(),

  };

}

  //----------------------------------------------------------
  // Load Trees
  //----------------------------------------------------------

  Future<void> _loadTrees() async {

    final result =
        await _treeRepository.getTrees(
      widget.applicationId,
    );

    allTrees = result;

    filteredTrees = result;

    if (mounted) {

      setState(() {});

    }

  }

  //----------------------------------------------------------
  // Search Trees
  //----------------------------------------------------------

  void _searchTrees() {

    final query =
        searchController.text
            .trim()
            .toLowerCase();

    if (query.isEmpty) {

      filteredTrees = allTrees;

    } else {

      filteredTrees = allTrees.where(

        (tree) {

          return tree.treeNumber
              .toLowerCase()
              .contains(query);

        },

      ).toList();

    }

    if (mounted) {

      setState(() {});

    }

  }
    //----------------------------------------------------------
  // Delete Tree
  //----------------------------------------------------------

  Future<void> _deleteTree(
    TreeModel tree,
  ) async {

    final bool delete =
        await showDialog<bool>(

              context: context,

              builder: (context) {

                return AlertDialog(

                  title: Text(
                    "Delete Tree ${tree.treeNumber}",
                  ),

                  content: const Text(

                    "This tree will be permanently deleted.\n\n"
                    "Its tree number will remain reserved and "
                    "will never be reused.",

                  ),

                  actions: [

                    TextButton(

                      onPressed: () {

                        Navigator.pop(
                          context,
                          false,
                        );

                      },

                      child: const Text(
                        "Cancel",
                      ),

                    ),

                    ElevatedButton(

                      onPressed: () {

                        Navigator.pop(
                          context,
                          true,
                        );

                      },

                      child: const Text(
                        "Delete",
                      ),

                    ),

                  ],

                );

              },

            ) ??
            false;

    if (!delete) return;

    await _treeRepository.deleteTree(
      tree.id!,
    );

    await _loadTrees();

  }

  //----------------------------------------------------------
  // Add Tree
  //----------------------------------------------------------

  Future<void> _openAddTree() async {

  final stemType = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Select Stem Type",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.park),
                title: const Text("Single Stem"),
                onTap: () {
                  Navigator.pop(context, "Single");
                },
              ),

              ListTile(
                leading: const Icon(Icons.forest),
                title: const Text("Multiple Stem"),
                onTap: () {
                  Navigator.pop(context, "Multiple");
                },
              ),

              const SizedBox(height: 10),

            ],
          ),
        ),
      );
    },
  );

  if (stemType == null) return;

  final numbering = TreeNumberingService();

  Map<String, dynamic> numberData;

  if (stemType == "Single") {

    numberData = await numbering.nextTree(
      widget.applicationId,
    );

  } else {

    final next = await numbering.nextTree(
      widget.applicationId,
    );

    numberData = {
      "treeNumber":
          "${next["baseTreeNumber"]}A",
      "baseTreeNumber":
          next["baseTreeNumber"],
      "stemLetter": "A",
    };

  }

  dynamic result = TreeModel(
  applicationId: widget.applicationId,
  treeNumber: numberData["treeNumber"],
  baseTreeNumber: numberData["baseTreeNumber"],
  stemType: stemType,
  stemLetter: numberData["stemLetter"],
  stemSequence: 1,
  isLastStem: true,
  speciesId: 0,
recommendationTypeId: 0,
gbh: null,
height: null,
numberOfBranches: null,
numberOfTwigs: null,
firewood: 0,
recommendationReasonIds: const [],
remarks: "",
);

while (result is TreeModel) {

  result = await Navigator.push(

    context,

    MaterialPageRoute(

      builder: (_) => AddEditTreeScreen(

        tree: result,

        isEdit: false,

      ),

    ),

  );

}

if (result == true) {

  await _loadTrees();

}

}

  //----------------------------------------------------------
  // Edit Tree
  //----------------------------------------------------------

  Future<void> _openEditTree(
    TreeModel tree,
  ) async {

    final bool? refresh =
        await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (_) => AddEditTreeScreen(

          tree: tree,

          isEdit: true,

        ),

      ),

    );

    if (refresh == true) {

      await _loadTrees();

    }

  }

  //----------------------------------------------------------
  // Sandal Destination Card
  //----------------------------------------------------------

  Widget _sandalDestinationCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Send sandal to",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: sandalDestinations.any((item) =>
                      item["id"] ==
                      selectedSandalDestinationId)
                  ? selectedSandalDestinationId
                  : null,
              decoration: const InputDecoration(
                labelText: "Send sandal to",
                border: OutlineInputBorder(),
              ),
              items: [
                ...sandalDestinations.map((item) {
                  return DropdownMenuItem<int>(
                    value: item["id"] as int,
                    child: Text(
                      item["value"]?.toString() ?? "",
                    ),
                  );
                }),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text("Others"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSandalDestinationId = value;
                  sandalDestinationIsOther = value == -1;
                });
              },
            ),
            if (sandalDestinationIsOther) ...[
              const SizedBox(height: 12),
              TextField(
                controller: sandalCustomController,
                decoration: const InputDecoration(
                  labelText: "Type destination",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  //----------------------------------------------------------
  // Continue
  //----------------------------------------------------------

  Future<void>
      _continueToDocuments() async {

    if (allTrees.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(

            "Please add at least one tree before continuing.",

          ),

        ),

      );

      return;

    }

    if (_isSandalApplication && application != null) {
      if (selectedSandalDestinationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please select where to send the sandalwood.",
            ),
          ),
        );
        return;
      }

      if (sandalDestinationIsOther &&
          sandalCustomController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please type the sandal destination.",
            ),
          ),
        );
        return;
      }

      application!.sandalDestinationId =
          sandalDestinationIsOther
              ? null
              : selectedSandalDestinationId;
      application!.sandalDestinationCustom =
          sandalDestinationIsOther
              ? sandalCustomController.text.trim()
              : "";

      await _applicationRepository.updateApplication(
        application!,
      );
    }

    Navigator.pop(
      context,
      true,
    );

  }

  //----------------------------------------------------------
  // Tree Count Card
  //----------------------------------------------------------

  Widget _treeCountCard() {

    return Card(

      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),

      child: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Row(

          children: [

            const Icon(

              Icons.forest,

              color: Colors.green,

            ),

            const SizedBox(width: 12),

            const Text(

              "Trees Entered",

              style: TextStyle(

                fontWeight:
                    FontWeight.bold,

                fontSize: 16,

              ),

            ),

            const Spacer(),

            Text(

              allTrees.length.toString(),

              style: const TextStyle(

                fontWeight:
                    FontWeight.bold,

                fontSize: 20,

                color: Colors.blue,

              ),

            ),

          ],

        ),

      ),

    );

  }

  //----------------------------------------------------------
  // Search Box
  //----------------------------------------------------------

  Widget _searchBox() {

    return Padding(

      padding:
          const EdgeInsets.symmetric(

        horizontal: 16,

      ),

      child: TextField(

        controller: searchController,

        decoration: InputDecoration(

          hintText:
              "Search Tree Number",

          prefixIcon:
              const Icon(Icons.search),

          border:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(10),

          ),

        ),

      ),

    );

  }
    //----------------------------------------------------------
  // Tree List
  //----------------------------------------------------------

  Widget _treeList() {

    if (loading) {

      return const Center(
        child: CircularProgressIndicator(),
      );

    }

    if (filteredTrees.isEmpty) {

      return const Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(

              Icons.park_outlined,

              size: 70,

              color: Colors.grey,

            ),

            SizedBox(height: 16),

            Text(

              "No Trees Added",

              style: TextStyle(

                fontSize: 20,

                fontWeight: FontWeight.bold,

              ),

            ),

            SizedBox(height: 8),

            Text(

              "Click ADD TREE to begin inspection.",

            ),

          ],

        ),

      );

    }

    return Column(

  children: [

    Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),

      color: Colors.green.shade100,

      child: const Row(
  children: [

    SizedBox(
      width: 55,
      child: Text(
        "Tree",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    Expanded(
      flex: 3,
      child: Text(
        "Species",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    SizedBox(
      width: 55,
      child: Text(
        "GBH\n(m)",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    SizedBox(
      width: 55,
      child: Text(
        "Ht",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    SizedBox(
      width: 60,
      child: Text(
        "Br/Tw",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    SizedBox(
      width: 60,
      child: Text(
        "Fire",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    SizedBox(
      width: 130,
      child: Text(
        "Recommendation",
        style: TextStyle(
            fontWeight:
                FontWeight.bold),
      ),
    ),

    SizedBox(
      width: 180,
      child: Text(
        "Reason",
        style: TextStyle(
            fontWeight:
                FontWeight.bold),
      ),
    ),

    Expanded(
      flex: 2,
      child: Text(
        "Remarks",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    SizedBox(width: 72),

  ],
)

    ),

    Expanded(

      child: ListView.separated(

      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),

      itemCount: filteredTrees.length,

      separatorBuilder: (_, _) =>
          const SizedBox(height: 10),

      itemBuilder: (context, index) {

        final tree = filteredTrees[index];

        return _treeCard(tree);

      },

          ),

    ),

  ],

);

  }

  //----------------------------------------------------------
  // Tree Card
  //----------------------------------------------------------

  Widget _treeCard(TreeModel tree) {

  return Card(

    margin: const EdgeInsets.symmetric(vertical: 3),

    elevation: 1,

    child: InkWell(

      onTap: () => _openEditTree(tree),

      child: Padding(

        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),

        child: Row(

          children: [

            //--------------------------------------------------
            // Tree Number
            //--------------------------------------------------

            SizedBox(
              width: 55,
              child: Text(
                tree.treeNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            //--------------------------------------------------
            // Species
            //--------------------------------------------------

            Expanded(
              flex: 3,
              child: Text(
                speciesMap[tree.speciesId] ?? "",
                overflow: TextOverflow.ellipsis,
              ),
            ),

            //--------------------------------------------------
            // GBH
            //--------------------------------------------------

            SizedBox(
              width: 55,
              child: Text(
                tree.gbh?.toStringAsFixed(2) ?? "",
                textAlign: TextAlign.center,
              ),
            ),

            //--------------------------------------------------
            // Height
            //--------------------------------------------------

            SizedBox(
              width: 55,
              child: Text(
                tree.height?.toStringAsFixed(2) ?? "",
                textAlign: TextAlign.center,
              ),
            ),

            //--------------------------------------------------
            // Branch / Twig
            //--------------------------------------------------

            SizedBox(
              width: 60,
              child: Text(
                _branchTwig(tree),
                textAlign: TextAlign.center,
              ),
            ),

            //--------------------------------------------------
            // Firewood
            //--------------------------------------------------

            SizedBox(
              width: 60,
              child: Text(
                tree.firewood.toStringAsFixed(2),
                textAlign: TextAlign.center,
              ),
            ),

            //--------------------------------------------------
            // Recommendation
            //--------------------------------------------------

            SizedBox(

  width: 130,

  child: Text(

    _recommendationName(tree),

    overflow:
        TextOverflow.ellipsis,

  ),

),

SizedBox(

  width: 180,

  child: Text(

    _recommendationReasons(tree),

    overflow:
        TextOverflow.ellipsis,

  ),

),

            //--------------------------------------------------
            // Remarks
            //--------------------------------------------------

            Expanded(
              flex: 2,
              child: Text(
                tree.remarks,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            //--------------------------------------------------
            // Edit
            //--------------------------------------------------

            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () => _openEditTree(tree),
            ),

            //--------------------------------------------------
            // Delete
            //--------------------------------------------------

            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteTree(tree),
            ),

          ],

        ),

      ),

    ),

  );

}

  //----------------------------------------------------------
  // Recommendation Strip
  //----------------------------------------------------------

  Widget _recommendationStrip(

    bool recommended,

    String text,

  ) {

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(

        horizontal: 12,

        vertical: 8,

      ),

      decoration: BoxDecoration(

        color: recommended
            ? Colors.green.shade50
            : Colors.red.shade50,

        borderRadius:
            BorderRadius.circular(8),

        border: Border.all(

          color: recommended
              ? Colors.green
              : Colors.red,

        ),

      ),

      child: Row(

        children: [

          Icon(

            recommended
                ? Icons.check_circle
                : Icons.cancel,

            color: recommended
                ? Colors.green
                : Colors.red,

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              text,

              style: TextStyle(

                fontWeight:
                    FontWeight.bold,

                color: recommended
                    ? Colors.green
                    : Colors.red,

              ),

            ),

          ),

        ],

      ),

    );

  }

String _recommendationName(
    TreeModel tree) {

  return recommendationTypeMap[
          tree.recommendationTypeId] ??
      "-";

}

String _recommendationReasons(
    TreeModel tree) {

  if (tree.recommendationReasonIds
      .isEmpty) {

    return "-";

  }

  return tree.recommendationReasonIds

      .map((id) =>
          recommendationReasonMap[id] ??
          "")

      .where((e) => e.isNotEmpty)

      .join(", ");

}

String _branchTwig(
    TreeModel tree) {

  if (tree.numberOfBranches !=
          null &&
      tree.numberOfBranches! > 0) {

    return tree.numberOfBranches
        .toString();

  }

  if (tree.numberOfTwigs != null &&
      tree.numberOfTwigs! > 0) {

    return tree.numberOfTwigs
        .toString();

  }

  return "-";

}

    //----------------------------------------------------------
  // BUILD
  //----------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: const TPMSAppBar(
        title: "Tree Inspection",
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        onPressed: _openAddTree,

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          "ADD TREE",
        ),

      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : application == null

              ? const Center(
                  child: Text(
                    "Application not found.",
                  ),
                )

              : SafeArea(

                  child: Column(

                    children: [

                      //------------------------------------------------
                      // Application Header
                      //------------------------------------------------

                      ApplicationHeaderCard(
                        application:
                            application!,
                      ),

                      //------------------------------------------------
                      // Wizard Progress
                      //------------------------------------------------

                      const WizardProgressCard(

                        currentStep: 5,

                        totalSteps: 8,

                        title:
                            "Tree Inspection",

                      ),

                      //------------------------------------------------
                      // Tree Count
                      //------------------------------------------------

                      _treeCountCard(),

                      //------------------------------------------------
                      // Search
                      //------------------------------------------------

                      _searchBox(),

                      const SizedBox(
                        height: 12,
                      ),

                      //------------------------------------------------
                      // Tree List
                      //------------------------------------------------

                      Expanded(

                        child: _treeList(),

                      ),

                      //------------------------------------------------
                      // Sandal Destination (SPL/SGL only)
                      //------------------------------------------------

                      if (_isSandalApplication)
                        _sandalDestinationCard(),

                      //------------------------------------------------
                      // Continue Button
                      //------------------------------------------------

                      SafeArea(

                        top: false,

                        child: Padding(

                          padding:
                              const EdgeInsets.all(
                            16,
                          ),

                          child: SizedBox(

                            width:
                                double.infinity,

                            height: 50,

                            child:
                                ElevatedButton(

                              onPressed:
                                  _continueToDocuments,

                              child:
                                  const Text(

                                "CONTINUE TO DOCUMENTS",

                              ),

                            ),

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

    );

  }
    //----------------------------------------------------------
  // Species Name
  //----------------------------------------------------------

  String _speciesName(
    int speciesId,
  ) {

    return speciesMap[speciesId] ??
        "Unknown";

  }

  //----------------------------------------------------------
  // Total Trees
  //----------------------------------------------------------

  int get _totalTrees {

    return allTrees.length;

  }

  //----------------------------------------------------------
  // Has Trees
  //----------------------------------------------------------

  bool get _hasTrees {

    return allTrees.isNotEmpty;

  }

  //----------------------------------------------------------
  // Refresh Screen
  //----------------------------------------------------------

  Future<void> _refresh() async {

    await _loadTrees();

  }

  //----------------------------------------------------------
  // Empty State Widget
  //----------------------------------------------------------

  Widget _emptyState() {

    return const Center(

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(

            Icons.forest_outlined,

            size: 80,

            color: Colors.grey,

          ),

          SizedBox(height: 16),

          Text(

            "No Trees Added",

            style: TextStyle(

              fontSize: 20,

              fontWeight: FontWeight.bold,

            ),

          ),

          SizedBox(height: 8),

          Text(

            "Press ADD TREE to create the first tree.",

            textAlign: TextAlign.center,

          ),

        ],

      ),

    );

  }

  //----------------------------------------------------------
  // Loading Widget
  //----------------------------------------------------------

  Widget _loadingWidget() {

    return const Center(

      child: CircularProgressIndicator(),

    );

  }

  //----------------------------------------------------------
  // Application Not Found
  //----------------------------------------------------------

  Widget _applicationNotFound() {

    return const Center(

      child: Text(

        "Application not found.",

        style: TextStyle(

          fontSize: 18,

          fontWeight: FontWeight.bold,

        ),

      ),

    );

  }

  //----------------------------------------------------------
  // Refresh after Add/Edit/Delete
  //----------------------------------------------------------

  Future<void> _reloadAfterChange() async {

    await _loadTrees();

    if (mounted) {

      setState(() {});

    }

  }
  }