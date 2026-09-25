import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../models/tree_model.dart';
import '../../../repositories/application_repository.dart';
import '../../../repositories/master_repository.dart';
import '../../../repositories/tree_repository.dart';
import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';
import '../../../services/tree_numbering_service.dart';

class AddEditTreeScreen extends StatefulWidget {
  final TreeModel tree;
  final bool isEdit;

  const AddEditTreeScreen({
    super.key,
    required this.tree,
    required this.isEdit,
  });

  @override
  State<AddEditTreeScreen> createState() =>
      _AddEditTreeScreenState();
}

class _AddEditTreeScreenState
    extends State<AddEditTreeScreen> {

  //----------------------------------------------------------
  // Repositories
  //----------------------------------------------------------

  final TreeRepository _treeRepository =
      TreeRepository();

  final ApplicationRepository
      _applicationRepository =
      ApplicationRepository();

  //----------------------------------------------------------
  // Form
  //----------------------------------------------------------

  final _formKey =
      GlobalKey<FormState>();

  //----------------------------------------------------------
  // Screen State
  //----------------------------------------------------------

  bool _loading = true;

  ApplicationModel? application;

  //----------------------------------------------------------
  // Masters
  //----------------------------------------------------------

  List<Map<String, dynamic>>
      speciesList = [];

  List<Map<String,dynamic>> recommendationTypeList=[];
    List<Map<String, dynamic>> treeStatusList = [];

List<Map<String,dynamic>> recommendationReasonList=[];

  //----------------------------------------------------------
  // Selected Values
  //----------------------------------------------------------

  int? selectedSpeciesId;

  int? selectedRecommendationTypeId;
  int? selectedTreeStatusId;
String selectedRecommendationCode = "";

  List<int> selectedReasons = [];
  bool notFitForTimber = false;

  //----------------------------------------------------------
  // Controllers
  //----------------------------------------------------------

  final gbhController =
      TextEditingController();

  final heightController =
      TextEditingController();

  final branchesController =
      TextEditingController();

      final twigsController =
    TextEditingController();

  final firewoodController =
      TextEditingController();

  final remarksController =
      TextEditingController();

  //----------------------------------------------------------
  // Init
  //----------------------------------------------------------

  @override
  void initState() {

    super.initState();

    _initialize();

  }

  //----------------------------------------------------------
  // Dispose
  //----------------------------------------------------------

  @override
  void dispose() {

    gbhController.dispose();

    heightController.dispose();

    branchesController.dispose();

    twigsController.dispose();

    firewoodController.dispose();

    remarksController.dispose();

    super.dispose();

  }

  //----------------------------------------------------------
  // Initialize Screen
  //----------------------------------------------------------

  Future<void> _initialize() async {
  try {
    await _loadApplication();
    await _loadSpecies();
    await _loadRecommendationTypes();
    await _loadTreeStatuses();
    await _loadTree();
  } catch (e, s) {
    debugPrint("AddEditTreeScreen initialization failed");
    debugPrint(e.toString());
    debugPrint(s.toString());
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  //----------------------------------------------------------
  // Load Application
  //----------------------------------------------------------

  bool get isSandalApplication {
    final type = (application?.applicationType ?? "")
        .trim()
        .toUpperCase();
    return type == "SPL" || type == "SGL";
  }

  Future<void> _loadApplication() async {

    application =
        await _applicationRepository.getById(
      widget.tree.applicationId,
    );

  }

  //----------------------------------------------------------
  // Load Species
  //----------------------------------------------------------

  Future<void> _loadSpecies() async {
  // Online-aware: species added on any device appear here.
  final allSpecies = await MasterRepository().getMasters("Species");

  final activeSpecies = allSpecies.where((species) {
    return species["isActive"] == 1;
  }).toList();

  final applicationType =
      (application?.applicationType ?? "")
          .trim()
          .toUpperCase();

  final sandalApplication =
      applicationType == "SGL" ||
      applicationType == "SPL" ||
      applicationType == "SANDAL GOVERNMENT" ||
      applicationType == "SANDAL PRIVATE";

  final allowedSpecies =
      activeSpecies.where((species) {
    var group = species["speciesGroup"]
            ?.toString()
            .trim()
            .toUpperCase() ??
        "";

    // Legacy/seed species without a group behave as timber.
    if (group.isEmpty) group = "TIMBER";

    if (sandalApplication) {
      return group == "SANDAL";
    }

    return group == "TIMBER" ||
        group == "POLE";
  }).toList();

  // Deduplicate species having the same name in
  // TIMBER and POLE masters. Prefer the TIMBER record
  // as the selected tree ID. Pole matching and rate
  // selection will still happen later using species
  // name, GBH and height.
  final Map<String, Map<String, dynamic>>
      uniqueSpecies = {};

  for (final species in allowedSpecies) {
    final name = species["value"]
            ?.toString()
            .trim()
            .toLowerCase() ??
        "";

    if (name.isEmpty) continue;

    final existing = uniqueSpecies[name];

    if (existing == null) {
      uniqueSpecies[name] = species;
      continue;
    }

    final existingGroup =
        existing["speciesGroup"]
                ?.toString()
                .trim()
                .toUpperCase() ??
            "";

    final currentGroup =
        species["speciesGroup"]
                ?.toString()
                .trim()
                .toUpperCase() ??
            "";

    // If the same species exists in both categories,
    // retain its TIMBER master record in the dropdown.
    if (existingGroup != "TIMBER" &&
        currentGroup == "TIMBER") {
      uniqueSpecies[name] = species;
    }
  }

  speciesList = uniqueSpecies.values.toList();
}

//----------------------------------------------------------
// Load Recommendation Types
//----------------------------------------------------------

Future<void> _loadRecommendationTypes() async {

  final all = await MasterRepository().getMasters(
    "Recommendation Type",
  );

  final active = all
      .where((item) => item["isActive"] == 1)
      .toList();

  // Sandal applications allow only Full Tree and Not Recommended.
  if (isSandalApplication) {
    recommendationTypeList = active.where((item) {
      final code = item["code"]
              ?.toString()
              .trim()
              .toUpperCase() ??
          "";
      return code == "FULL" || code == "NR";
    }).toList();
  } else {
    recommendationTypeList = active;
  }

}

Future<void> _loadTreeStatuses() async {
  final allStatuses = await MasterRepository().getMasters("Tree Status");

  final existingStatusId =
      widget.tree.treeStatusId;

  treeStatusList = allStatuses.where((item) {
    return item["isActive"] == 1 ||
        item["id"] == existingStatusId;
  }).toList();
}
  //----------------------------------------------------------
// Load Recommendation Reasons
//----------------------------------------------------------

Future<void> _loadRecommendationReasons() async {

  recommendationReasonList.clear();
  selectedReasons.clear();

  if (selectedRecommendationCode.isEmpty) {

    return;

  }

  recommendationReasonList =
      await MasterRepository().getRecommendationReasons(
    selectedRecommendationCode,
  );

}

//----------------------------------------------------------
// Recommendation Changed
//----------------------------------------------------------

Future<void> _onRecommendationTypeChanged(
    int recommendationTypeId,
) async {

  final item = recommendationTypeList.firstWhere(
    (e) => e["id"] == recommendationTypeId,
  );

  final newCode = item["code"].toString();

  final reasons =
      await MasterRepository().getRecommendationReasons(
    newCode,
  );

  if (!mounted) return;

  setState(() {

    //------------------------------------------------
    // Recommendation
    //------------------------------------------------

    selectedRecommendationTypeId =
        recommendationTypeId;

    selectedRecommendationCode =
        newCode;

    //------------------------------------------------
    // New reason list
    //------------------------------------------------

    recommendationReasonList = reasons;

    //------------------------------------------------
    // Clear selected reasons
    //------------------------------------------------

    selectedReasons.clear();

    //------------------------------------------------
    // Clear measurements
    //------------------------------------------------

    gbhController.clear();

    heightController.clear();

    branchesController.clear();

    twigsController.clear();

    firewoodController.clear();

  });

}

  //----------------------------------------------------------
  // Load Existing Tree
  //----------------------------------------------------------

  Future<void> _loadTree() async {

    final tree = widget.tree;

    selectedSpeciesId =
    tree.speciesId == 0 ? null : tree.speciesId;

    selectedRecommendationTypeId =
    tree.recommendationTypeId;

        selectedTreeStatusId =
        tree.treeStatusId;

selectedRecommendationCode = "";

recommendationReasonList.clear();

if (selectedRecommendationTypeId != null) {

  final item = recommendationTypeList.firstWhere(

    (e) =>

        e["id"] == selectedRecommendationTypeId,

    orElse: () => {},

  );

  if (item.isNotEmpty) {

    selectedRecommendationCode =
        item["code"].toString();

  }

}

    selectedReasons =
        List<int>.from(
            tree.recommendationReasonIds);

    gbhController.text =
        tree.gbh?.toString() ?? "";

    heightController.text =
        tree.height?.toString() ?? "";

notFitForTimber =
    tree.notFitForTimber;

    branchesController.text =
        tree.numberOfBranches
                ?.toString() ??
            "";

            twigsController.text =
    tree.numberOfTwigs
            ?.toString() ??
        "";

    firewoodController.text =
        tree.firewood.toString();

    remarksController.text =
        tree.remarks;

  }
    //----------------------------------------------------------
  // Validate
  //----------------------------------------------------------

  bool _validate() {

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (selectedSpeciesId == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select species."),
        ),
      );

      return false;
    }

   if (selectedRecommendationTypeId != null &&
    selectedReasons.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Select at least one recommendation reason.",
          ),
        ),
      );

      return false;
    }

    return true;
  }

  //----------------------------------------------------------
  // Save Tree
  //----------------------------------------------------------

  Future<int> _saveCurrentTree() async {

  if (!_validate()) return -1;

  setState(() {
    _loading = true;
  });

  final tree = TreeModel(
    id: widget.tree.id,
    applicationId: widget.tree.applicationId,
    treeNumber: widget.tree.treeNumber,
    baseTreeNumber: widget.tree.baseTreeNumber,
    stemType: widget.tree.stemType,
    stemLetter: widget.tree.stemLetter,
    stemSequence: widget.tree.stemSequence,
    isLastStem: widget.tree.isLastStem,
    speciesId: selectedSpeciesId!,
    recommendationTypeId:
    selectedRecommendationTypeId!,
        treeStatusId:
        selectedTreeStatusId!,
    gbh: gbhController.text.trim().isEmpty
        ? null
        : double.parse(gbhController.text.trim()),
    height: heightController.text.trim().isEmpty
        ? null
        : double.parse(heightController.text.trim()),
        notFitForTimber:
    notFitForTimber,
    numberOfBranches:
    branchesController.text.trim().isEmpty
        ? null
        : int.parse(
            branchesController.text.trim()),

numberOfTwigs:
    twigsController.text.trim().isEmpty
        ? null
        : int.parse(
            twigsController.text.trim()),
    firewood: firewoodController.text.trim().isEmpty
        ? 0
        : double.parse(firewoodController.text.trim()),
    
    recommendationReasonIds: List<int>.from(selectedReasons),
    remarks: remarksController.text.trim(),
  );

  if (widget.isEdit) {

    await _treeRepository.updateTree(tree);

    return tree.id!;

  } else {

    return await _treeRepository.insertTree(tree);

  }

}

  Future<void> _updateTree() async {

  await _saveCurrentTree();

  if (!mounted) return;

  Navigator.pop(context, true);

}

Future<void> _saveAndFinishTree() async {

  final insertedId = await _saveCurrentTree();

  if (insertedId == -1) return;

  if (!mounted) return;

  Navigator.pop(context, true);

}

Future<void> _saveAndNextStem() async {

  final insertedId = await _saveCurrentTree();

if (insertedId == -1) return;

final currentTree = TreeModel(
    id: widget.tree.id ?? insertedId,
  applicationId: widget.tree.applicationId,
  treeNumber: widget.tree.treeNumber,
  baseTreeNumber: widget.tree.baseTreeNumber,
  stemType: widget.tree.stemType,
  stemLetter: widget.tree.stemLetter,
  stemSequence: widget.tree.stemSequence,
  isLastStem: false,
  speciesId: selectedSpeciesId!,
  recommendationTypeId:
    selectedRecommendationTypeId!,
      treeStatusId:
      selectedTreeStatusId!,
  gbh: gbhController.text.trim().isEmpty
      ? null
      : double.parse(gbhController.text.trim()),
  height: heightController.text.trim().isEmpty
      ? null
      : double.parse(heightController.text.trim()),
      notFitForTimber:
    notFitForTimber,
  numberOfBranches:
    branchesController.text.trim().isEmpty
        ? null
        : int.parse(
            branchesController.text.trim()),

numberOfTwigs:
    twigsController.text.trim().isEmpty
        ? null
        : int.parse(
            twigsController.text.trim()),
  firewood: firewoodController.text.trim().isEmpty
      ? 0
      : double.parse(firewoodController.text.trim()),
 
  recommendationReasonIds: List<int>.from(selectedReasons),
  remarks: remarksController.text.trim(),
);

await _treeRepository.updateTree(currentTree);

  final next =
      await TreeNumberingService().nextStem(

    widget.tree.applicationId,

    widget.tree.baseTreeNumber,

    widget.tree.stemLetter,

  );

  if (!mounted) return;

  if (!mounted) return;

Navigator.pop(
  context,
  TreeModel(
    applicationId: widget.tree.applicationId,
    treeNumber: next["treeNumber"],
    baseTreeNumber: next["baseTreeNumber"],
    stemType: "Multiple",
    stemLetter: next["stemLetter"],
    stemSequence: widget.tree.stemSequence + 1,
    isLastStem: true,
    speciesId: selectedSpeciesId!,
    recommendationTypeId:
        selectedRecommendationTypeId!,
    treeStatusId: null,
    gbh: null,
    height: null,
    notFitForTimber: false,
    numberOfBranches: null,
    firewood: 0,
   
    recommendationReasonIds: List<int>.from(selectedReasons),
    remarks: "",
  ),
);

}

  //----------------------------------------------------------
  // Species Dropdown
  //----------------------------------------------------------

  Widget _speciesDropdown() {

  if (widget.tree.stemType == "Multiple" &&
      widget.tree.stemSequence > 1) {

    final species = speciesList.firstWhere(
      (e) => e["id"] == selectedSpeciesId,
      orElse: () => {},
    );

    return TextFormField(
      initialValue:
          species["value"]?.toString() ?? "",
      enabled: false,
      decoration: const InputDecoration(
        labelText: "Species",
        border: OutlineInputBorder(),
      ),
    );
  }

  return FormField<int>(
    validator: (_) {

      if (selectedSpeciesId == null) {

        return "Select Species";

      }

      return null;
    },

    builder: (field) {

      final selectedSpecies =
          speciesList.firstWhere(
        (e) => e["id"] == selectedSpeciesId,
        orElse: () => {},
      );

      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          InkWell(

            onTap: () async {

              final selected =
                  await _showSpeciesSearchDialog();

              if (selected == null) {
                return;
              }

              setState(() {

                selectedSpeciesId =
                    selected["id"];

              });

              field.didChange(
                selected["id"] as int,
              );

            },

            child: InputDecorator(

              decoration: InputDecoration(

                labelText: "Species",

                border:
                    const OutlineInputBorder(),

                errorText:
                    field.errorText,

                suffixIcon:
                    const Icon(
                  Icons.search,
                ),

              ),

              child: Text(

                selectedSpecies.isEmpty

                    ? "Select Species"

                    : selectedSpecies["value"]
                        .toString(),

                style: TextStyle(

                  color:
                      selectedSpecies.isEmpty
                          ? Colors.grey
                          : Colors.black,

                ),

              ),

            ),

          ),

        ],

      );
    },
  );
}

Future<Map<String, dynamic>?> _showSpeciesSearchDialog() async {
  final searchController = TextEditingController();

  List<Map<String, dynamic>> filtered =
      List<Map<String, dynamic>>.from(speciesList);

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void search(String value) {
            final query = value.trim().toLowerCase();

            setDialogState(() {
              if (query.isEmpty) {
                filtered =
                    List<Map<String, dynamic>>.from(speciesList);
              } else {
                filtered = speciesList.where((species) {
                  final name =
                      species["value"]?.toString().toLowerCase() ?? "";

                  return name.contains(query);
                }).toList();
              }
            });
          }

          return AlertDialog(
            title: const Text("Select Species"),

            content: SizedBox(
              width: 450,
              height: 500,

              child: Column(
                children: [

                  TextField(
                    controller: searchController,
                    autofocus: true,

                    decoration: const InputDecoration(
                      labelText: "Search Species",
                      hintText: "Type species name",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),

                    onChanged: search,
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text("No species found"),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,

                            itemBuilder: (context, index) {
                              final species = filtered[index];

                              return ListTile(
  title: Text(
    species["value"].toString(),
  ),
  onTap: () {
                                  Navigator.of(dialogContext).pop(
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
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("CANCEL"),
              ),
            ],
          );
        },
      );
    },
  );

  // IMPORTANT:
  // Do NOT dispose searchController here.
  // The dialog/overlay may still be completing its removal.
  return result;
}

//----------------------------------------------------------
// Recommendation Type
//----------------------------------------------------------

Widget _recommendationTypeDropdown() {

  return DropdownButtonFormField<int>(

    value: recommendationTypeList.any(
      (e) => e["id"] == selectedRecommendationTypeId,
    )
        ? selectedRecommendationTypeId
        : null,

    decoration: const InputDecoration(

      labelText: "Recommendation",

      border: OutlineInputBorder(),

    ),

    items: recommendationTypeList.map((item) {

      return DropdownMenuItem<int>(

        value: item["id"],

        child: Text(item["value"]),

      );

    }).toList(),

    onChanged: (value) async {

  if (value == null) return;

  await _onRecommendationTypeChanged(value);

},


    validator: (_) {

      if (selectedRecommendationTypeId == null) {

        return "Select Recommendation";

      }

      return null;

    },

  );

}

Widget _treeStatusDropdown() {
  return DropdownButtonFormField<int>(
    value: treeStatusList.any(
      (item) =>
          item["id"] == selectedTreeStatusId,
    )
        ? selectedTreeStatusId
        : null,
    decoration: const InputDecoration(
      labelText: "Tree Status",
      border: OutlineInputBorder(),
    ),
    items: treeStatusList.map((item) {
      return DropdownMenuItem<int>(
        value: item["id"] as int,
        child: Text(
          item["value"]?.toString() ?? "",
        ),
      );
    }).toList(),
    onChanged: (value) {
      setState(() {
        selectedTreeStatusId = value;
      });
    },
    validator: (value) {
      if (value == null) {
        return "Select Tree Status";
      }

      return null;
    },
  );
}

  //----------------------------------------------------------
  // Recommendation Reasons
  //----------------------------------------------------------

  Widget _recommendationReasons() {

  if (selectedRecommendationTypeId == null ||
    recommendationReasonList.isEmpty) {

  return const SizedBox();

}

  return Card(

    child: Padding(

      padding: const EdgeInsets.all(12),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Recommendation Reasons",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 16,

            ),

          ),

          const Divider(),

          ...recommendationReasonList.map((reason) {

            final id = reason["id"] as int;

            return CheckboxListTile(

              dense: true,

              value:
                  selectedReasons.contains(id),

              title: Text(reason["value"]),

              onChanged: (checked) {

                setState(() {

                  if (checked == true) {

                    selectedReasons.add(id);

                  } else {

                    selectedReasons.remove(id);

                  }

                });

              },

            );

          }),

        ],

      ),

    ),

  );

}

    //----------------------------------------------------------
  // Tree Information Card
  //----------------------------------------------------------

  Widget _treeInformationCard() {

    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(

              "Tree Information",

              style: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.bold,

              ),

            ),

            const Divider(),

            _infoRow(
  "Tree Number",
  widget.tree.treeNumber.toString(),
),

            _infoRow(
              "Stem Type",
              widget.tree.stemType,
            ),

            _infoRow(
              "Stem Letter",
              widget.tree.stemLetter.isEmpty
                  ? "-"
                  : widget.tree.stemLetter,
            ),

            _infoRow(
              "Base Tree",
              widget.tree.baseTreeNumber
                  .toString(),
            ),

          ],

        ),

      ),

    );

  }

  //----------------------------------------------------------
  // Information Row
  //----------------------------------------------------------

  Widget _infoRow(
    String title,
    String value,
  ) {

    return Padding(

      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),

      child: Row(

        children: [

          SizedBox(

            width: 120,

            child: Text(

              title,

              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),

            ),

          ),

          Expanded(
            child: Text(value),
          ),

        ],

      ),

    );

  }

  //----------------------------------------------------------
  // Measurements Card
  //----------------------------------------------------------

  Widget _measurementCard() {

  if (selectedRecommendationCode == "NR") {
    return const SizedBox();
  }

  return Card(

    child: Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Measurements",

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),

          ),

          const Divider(),

          if (selectedRecommendationCode == "FULL") ...[

            Column(
  children: [

    Row(
      children: [

        Expanded(
          child: _numberField(
            controller: gbhController,
            label: "GBH (m)",
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _numberField(
            controller: heightController,
            label: "Height (m)",
          ),
        ),

      ],
    ),

    const SizedBox(height: 12),

    // Not applicable for sandal applications.
    if (!isSandalApplication) ...[
CheckboxListTile(

  contentPadding: EdgeInsets.zero,

  value: notFitForTimber,

  title: const Text(

    "Not Fit For Timber",

  ),

  onChanged: (value) {

    setState(() {

      notFitForTimber = value ?? false;

    });

  },

),

    const SizedBox(height: 16),

    _numberField(
      controller: firewoodController,
      label: "Firewood (Tonnes)",
    ),

    ],

  ],
),

            const SizedBox(height: 16),

          ],

          if (selectedRecommendationCode == "BRANCH") ...[

  Row(
    children: [

      Expanded(
        child: _numberField(
          controller: branchesController,
          label: "Branches",
          integerOnly: true,
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: _numberField(
          controller: firewoodController,
          label: "Firewood",
        ),
      ),

    ],
  ),

  const SizedBox(height: 16),

],

if (selectedRecommendationCode == "TWIG") ...[

  Row(
    children: [

      Expanded(
        child: _numberField(
          controller: twigsController,
          label: "Twigs",
          integerOnly: true,
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: _numberField(
          controller: firewoodController,
          label: "Firewood",
        ),
      ),

    ],
  ),

  const SizedBox(height: 16),

],

if (selectedRecommendationCode == "TOP") ...[

  _numberField(
    controller: firewoodController,
    label: "Firewood",
  ),

],

      ],
    ),
  ),
);
}

  //----------------------------------------------------------
  // Number Field
  //----------------------------------------------------------

  Widget _numberField({

    required TextEditingController
        controller,

    required String label,

    bool integerOnly = false,

  }) {

    return TextFormField(

      controller: controller,

      keyboardType:
          const TextInputType.numberWithOptions(

        decimal: true,

      ),

      decoration: InputDecoration(

        labelText: label,

        border:
            const OutlineInputBorder(),

      ),

      validator: (value) {

        if (value == null ||
            value.trim().isEmpty) {

          return null;

        }

        if (integerOnly) {

          if (int.tryParse(value) ==
              null) {

            return "Invalid number";

          }

        } else {

          if (double.tryParse(value) ==
              null) {

            return "Invalid number";

          }

        }

        return null;

      },

    );

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

      body: _loading

          ? const Center(
              child: CircularProgressIndicator(),
            )

          : application == null

              ? const Center(
                  child: Text(
                    "Application not found.",
                  ),
                )

              : Form(

                  key: _formKey,

                  child: Column(

                    children: [

                      //------------------------------------------------
                      // Header
                      //------------------------------------------------

                      ApplicationHeaderCard(
                        application: application!,
                      ),

                      //------------------------------------------------
                      // Wizard
                      //------------------------------------------------

                      const WizardProgressCard(
                        currentStep: 5,
                        totalSteps: 8,
                        title: "Tree Inspection",
                      ),

                      //------------------------------------------------
                      // Form
                      //------------------------------------------------

                      Expanded(

                        child: SingleChildScrollView(

                          padding:
                              const EdgeInsets.all(16),

                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,

                            children: [

                              _treeInformationCard(),

                              const SizedBox(height: 16),

                              Card(

                                child: Padding(

                                  padding:
                                      const EdgeInsets.all(16),

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [

                                      const Text(

                                        "Inspection",

                                        style: TextStyle(

                                          fontWeight:
                                              FontWeight.bold,

                                          fontSize: 16,

                                        ),

                                      ),

                                      const Divider(),

                                    Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: _speciesDropdown(),
    ),

    const SizedBox(width: 16),

    Expanded(
      child: _treeStatusDropdown(),
    ),

    const SizedBox(width: 16),

    Expanded(
      child: _recommendationTypeDropdown(),
    ),
  ],
),

                                    ],

                                  ),

                                ),

                              ),

                              const SizedBox(height: 16),

                              _recommendationReasons(),

                              if (selectedRecommendationCode == "NR")
  const SizedBox(height: 16),

                              _measurementCard(),

                              const SizedBox(height: 24),
                              
                              //------------------------------------------------
// Buttons
//------------------------------------------------

if (widget.isEdit)

  Row(

    children: [

      Expanded(

        child: OutlinedButton.icon(

          icon: const Icon(Icons.close),

          label: const Text("Cancel"),

          onPressed: () {

            Navigator.pop(context);

          },

        ),

      ),

      const SizedBox(width: 16),

      Expanded(

        child: ElevatedButton.icon(

          icon: const Icon(Icons.save),

          label: const Text("Update Tree"),

         onPressed: () {

  _updateTree();

},

        ),

      ),

    ],

  )

else if (widget.tree.stemType == "Single")

  Row(

    children: [

      Expanded(

        child: OutlinedButton.icon(

          icon: const Icon(Icons.close),

          label: const Text("Cancel"),

          onPressed: () {

            Navigator.pop(context);

          },

        ),

      ),

      const SizedBox(width: 16),

      Expanded(

        child: ElevatedButton.icon(

          icon: const Icon(Icons.save),

          label: const Text("Save Tree"),

          onPressed: () {

            _saveAndFinishTree();

          },

        ),

      ),

    ],

  )

else

  Row(

    children: [

      Expanded(

        child: OutlinedButton(

          onPressed: () {

            Navigator.pop(context);

          },

          child: const Text(
            "Cancel",
          ),

        ),

      ),

      const SizedBox(width: 8),

      Expanded(

        child: ElevatedButton(

          onPressed: () {

  _saveAndNextStem();

},

          child: const Text(
            "Next Stem",
          ),

        ),

      ),

      const SizedBox(width: 8),

      Expanded(

        child: ElevatedButton(

          onPressed: () {

  _saveAndFinishTree();

},

          child: const Text(
            "Finish Tree",
          ),

        ),

      ),

    ],

  ),

                              const SizedBox(height: 24),

                            ],

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

    );

  }
    //----------------------------------------------------------
  // Reset Form
  //----------------------------------------------------------

  void _resetForm() {

    setState(() {

      selectedSpeciesId = null;

      selectedRecommendationTypeId = null;
            selectedTreeStatusId = null;

selectedRecommendationCode = "";

      selectedReasons.clear();

      gbhController.clear();

      heightController.clear();

      branchesController.clear();

      firewoodController.clear();

      remarksController.clear();

    });

  }

  //----------------------------------------------------------
  // Clear Recommendation Reasons
  //----------------------------------------------------------

  void _clearRecommendationReasons() {

    setState(() {

      selectedReasons.clear();

    });

  }

  //----------------------------------------------------------
  // Toggle Recommendation Reason
  //----------------------------------------------------------

  void _toggleRecommendationReason(int id) {

    setState(() {

      if (selectedReasons.contains(id)) {

        selectedReasons.remove(id);

      } else {

        selectedReasons.add(id);

      }

    });

  }

  //----------------------------------------------------------
  // Selected Reason Count
  //----------------------------------------------------------

  int get _selectedReasonCount {

    return selectedReasons.length;

  }

  //----------------------------------------------------------
  // Parse Double
  //----------------------------------------------------------

  double? _parseDouble(String value) {

    if (value.trim().isEmpty) {

      return null;

    }

    return double.tryParse(value.trim());

  }

  //----------------------------------------------------------
  // Parse Integer
  //----------------------------------------------------------

  int? _parseInt(String value) {

    if (value.trim().isEmpty) {

      return null;

    }

    return int.tryParse(value.trim());

  }

  //----------------------------------------------------------
  // Firewood Value
  //----------------------------------------------------------

  double get _firewoodValue {

    return _parseDouble(
            firewoodController.text) ??
        0;

  }

  //----------------------------------------------------------
  // GBH Value
  //----------------------------------------------------------

  double? get _gbhValue {

    return _parseDouble(
        gbhController.text);

  }

  //----------------------------------------------------------
  // Height Value
  //----------------------------------------------------------

  double? get _heightValue {

    return _parseDouble(
        heightController.text);

  }

  //----------------------------------------------------------
  // Branch Count
  //----------------------------------------------------------

  int? get _branchCount {

    return _parseInt(
        branchesController.text);

  }

  //----------------------------------------------------------
  // Has Recommendation Reasons
  //----------------------------------------------------------

  bool get _hasReasons {

    return selectedReasons.isNotEmpty;

  }

  }