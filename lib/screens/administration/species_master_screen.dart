import 'package:flutter/material.dart';

import '../../repositories/master_repository.dart';

class SpeciesMasterScreen extends StatefulWidget {
  const SpeciesMasterScreen({super.key});

  @override
  State<SpeciesMasterScreen> createState() =>
      _SpeciesMasterScreenState();
}

class _SpeciesMasterScreenState
    extends State<SpeciesMasterScreen> {
  final MasterRepository repository =
      MasterRepository();

  List<Map<String, dynamic>> timber = [];
  List<Map<String, dynamic>> poles = [];
  List<Map<String, dynamic>> sandal = [];
  List<Map<String, dynamic>> firewood = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

    timber =
        await repository.getSpeciesByGroup("TIMBER");

    poles =
        await repository.getPoleSpecies();

    sandal =
        await repository.getSpeciesByGroup("SANDAL");

    firewood =
        await repository.getSpeciesByGroup("FIREWOOD");

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  double? parseDouble(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(
      value.trim(),
    );
  }

  // ============================================================
  // SPECIES DIALOG
  // ============================================================

  Future<void> showSpeciesDialog({
    required String group,
    Map<String, dynamic>? item,
  }) async {
    final speciesController =
        TextEditingController(
      text: item?["value"] ?? "",
    );

    final scientificController =
        TextEditingController(
      text: item?["scientificName"] ?? "",
    );

    final kannadaController =
        TextEditingController(
      text: item?["kannadaName"] ?? "",
    );

    final ratePerM3Controller =
        TextEditingController(
      text:
          item?["ratePerCubicMeter"]
                  ?.toString() ??
              "",
    );

    final ratePerTonController =
        TextEditingController(
      text:
          item?["ratePerTon"]
                  ?.toString() ??
              "",
    );

final categoryController =
    TextEditingController(
      text: item?["category"] ?? "",
    );

    final displayOrderController =
        TextEditingController(
      text:
          item?["displayOrder"]
                  ?.toString() ??
              "1",
    );

    bool isActive =
        (item?["isActive"] ?? 1) == 1;

    String title;

    switch (group) {
      case "TIMBER":
        title = "Timber Species";
        break;

      case "POLE":
        title = "Pole Species";
        break;

      case "SANDAL":
        title = "Sandal Species";
        break;

      case "FIREWOOD":
        title = "Firewood Rate";
        break;

      default:
        title = "Species";
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                item == null
                    ? "Add $title"
                    : "Edit $title",
              ),

              content: SizedBox(
                width: 500,

                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [

                      if (group != "FIREWOOD")
                        TextField(
                          controller:
                              speciesController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Species",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                      if (group != "FIREWOOD")
                        const SizedBox(
                          height: 12,
                        ),

                      if (group != "FIREWOOD")
                        TextField(
                          controller:
                              scientificController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Scientific Name",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                      if (group != "FIREWOOD")
                        const SizedBox(
                          height: 12,
                        ),

                      if (group != "FIREWOOD")
                        TextField(
                          controller:
                              kannadaController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Kannada Name",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                      if (group == "TIMBER") ...[
                        const SizedBox(
                          height: 12,
                        ),

                        TextField(
                          controller:
                              ratePerM3Controller,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Rate per m³",
                            prefixText: "₹ ",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        TextField(
  controller: categoryController,
  decoration:
      const InputDecoration(
    labelText: "Category",
    border: OutlineInputBorder(),
  ),
),
                      ],

                      if (group == "FIREWOOD")
                        TextField(
                          controller:
                              ratePerTonController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Rate per ton",
                            prefixText: "₹ ",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            displayOrderController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Display Order",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      SwitchListTile(
                        title:
                            const Text(
                          "Active",
                        ),
                        value:
                            isActive,
                        contentPadding:
                            EdgeInsets.zero,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
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
                      const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {

                    if (group !=
                            "FIREWOOD" &&
                        speciesController
                            .text
                            .trim()
                            .isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Species name is required.",
                          ),
                        ),
                      );

                      return;
                    }

                    final displayOrder =
                        int.tryParse(
                              displayOrderController
                                  .text,
                            ) ??
                            1;

                    // ------------------------------------------------
                    // POLE SPECIES
                    // ------------------------------------------------

                    if (group == "POLE") {

                      if (item == null) {

                        await repository
                            .insertPoleSpecies(
                          species:
                              speciesController
                                  .text
                                  .trim(),
                          scientificName:
                              scientificController
                                  .text
                                  .trim(),
                          kannadaName:
                              kannadaController
                                  .text
                                  .trim(),
                          displayOrder:
                              displayOrder,
                          isActive:
                              isActive,
                        );

                      } else {

                        await repository
                            .updatePoleSpecies(
                          id: item["id"],
                          species:
                              speciesController
                                  .text
                                  .trim(),
                          scientificName:
                              scientificController
                                  .text
                                  .trim(),
                          kannadaName:
                              kannadaController
                                  .text
                                  .trim(),
                          displayOrder:
                              displayOrder,
                          isActive:
                              isActive,
                        );
                      }

                    }

                    // ------------------------------------------------
                    // OTHER SPECIES
                    // ------------------------------------------------

                    else {

                      if (item == null) {

                        await repository
                            .insertSpecies(
                          speciesGroup:
                              group,
                          species:
                              speciesController
                                  .text
                                  .trim(),
                          scientificName:
                              scientificController
                                  .text
                                  .trim(),
                          kannadaName:
                              kannadaController
                                  .text
                                  .trim(),
                          ratePerCubicMeter:
    parseDouble(
  ratePerM3Controller.text,
),

category:
    categoryController.text.trim(),

ratePerTon:
    parseDouble(
  ratePerTonController.text,
),

displayOrder:
    displayOrder,
                          isActive:
                              isActive,
                        );

                      } else {

                        await repository
                            .updateSpecies(
                          id: item["id"],
                          speciesGroup:
                              group,
                          species:
                              speciesController
                                  .text
                                  .trim(),
                          scientificName:
                              scientificController
                                  .text
                                  .trim(),
                          kannadaName:
                              kannadaController
                                  .text
                                  .trim(),
                          ratePerCubicMeter:
    parseDouble(
  ratePerM3Controller.text,
),

category:
    categoryController.text.trim(),

ratePerTon:
    parseDouble(
  ratePerTonController.text,
),

displayOrder:
    displayOrder,
                          isActive:
                              isActive,
                        );
                      }
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                    );

                  },

                  child:
                      const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // POLE RATE DIALOG
  // ============================================================

  Future<void> showPoleRateDialog({
    required Map<String, dynamic> species,
    Map<String, dynamic>? rateItem,
  }) async {

    final lengthFromController =
        TextEditingController(
      text:
          rateItem?["lengthFrom"]
                  ?.toString() ??
              "",
    );

    final lengthUptoController =
        TextEditingController(
      text:
          rateItem?["lengthUpto"]
                  ?.toString() ??
              "",
    );

    final girthFromController =
        TextEditingController(
      text:
          rateItem?["girthFrom"]
                  ?.toString() ??
              "",
    );

    final girthUptoController =
        TextEditingController(
      text:
          rateItem?["girthUpto"]
                  ?.toString() ??
              "",
    );

    final rateController =
        TextEditingController(
      text:
          rateItem?["rate"]
                  ?.toString() ??
              "",
    );

    final categoryController =
        TextEditingController(
      text:
          rateItem?["category"] ?? "",
    );

    final displayOrderController =
        TextEditingController(
      text:
          rateItem?["displayOrder"]
                  ?.toString() ??
              "1",
    );

    bool isActive =
        (rateItem?["isActive"] ?? 1) == 1;

    await showDialog(
      context: context,
      builder: (dialogContext) {

        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {

            return AlertDialog(

              title: Text(
                rateItem == null
                    ? "Add Pole Rate"
                    : "Edit Pole Rate",
              ),

              content: SizedBox(

                width: 500,

                child:
                    SingleChildScrollView(

                  child: Column(

                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      Text(
                        species["value"] ??
                            "",
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        children: [

                          Expanded(
                            child:
                                TextField(
                              controller:
                                  lengthFromController,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    "Length From",
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                TextField(
                              controller:
                                  lengthUptoController,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    "Length Upto",
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [

                          Expanded(
                            child:
                                TextField(
                              controller:
                                  girthFromController,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    "Girth From",
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                TextField(
                              controller:
                                  girthUptoController,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    "Girth Upto",
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            rateController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Rate",
                          prefixText:
                              "₹ ",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            categoryController
                                    .text
                                    .trim()
                                    .isEmpty
                                ? null
                                : categoryController
                                    .text
                                    .trim(),
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Category",
                          border:
                              OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "POLE",
                            child:
                                Text("POLE"),
                          ),
                          DropdownMenuItem(
                            value: "TIMBER",
                            child:
                                Text("TIMBER"),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            categoryController
                                    .text =
                                value ?? "";
                          });
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            displayOrderController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Display Order",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      SwitchListTile(
                        title:
                            const Text(
                          "Active",
                        ),
                        value:
                            isActive,
                        contentPadding:
                            EdgeInsets.zero,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
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
                      const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {

                    final lengthFrom =
                        parseDouble(
                      lengthFromController
                          .text,
                    );

                    final lengthUpto =
                        parseDouble(
                      lengthUptoController
                          .text,
                    );

                    final girthFrom =
                        parseDouble(
                      girthFromController
                          .text,
                    );

                    final girthUpto =
                        parseDouble(
                      girthUptoController
                          .text,
                    );

                    final rate =
                        parseDouble(
                      rateController.text,
                    );

                    final category =
                        categoryController
                            .text
                            .trim();

                    if (lengthFrom ==
                            null ||
                        lengthUpto ==
                            null ||
                        girthFrom ==
                            null ||
                        girthUpto ==
                            null ||
                        rate == null) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter Length, Girth and Rate.",
                          ),
                        ),
                      );

                      return;
                    }

                    if (lengthUpto <=
                        lengthFrom) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Length Upto must be greater than Length From.",
                          ),
                        ),
                      );

                      return;
                    }

                    if (girthUpto <=
                        girthFrom) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Girth Upto must be greater than Girth From.",
                          ),
                        ),
                      );

                      return;
                    }

                    if (category.isEmpty) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select Category.",
                          ),
                        ),
                      );

                      return;
                    }

                    final displayOrder =
                        int.tryParse(
                              displayOrderController
                                  .text,
                            ) ??
                            1;

                    if (rateItem == null) {

                      await repository
                          .insertPoleRate(

                        speciesId:
                            species["id"],

                        lengthFrom:
                            lengthFrom,

                        lengthUpto:
                            lengthUpto,

                        girthFrom:
                            girthFrom,

                        girthUpto:
                            girthUpto,

                        rate:
                            rate,

                        category:
                            category,

                        displayOrder:
                            displayOrder,

                        isActive:
                            isActive,
                      );

                    } else {

                      await repository
                          .updatePoleRate(

                        id:
                            rateItem["id"],

                        speciesId:
                            species["id"],

                        lengthFrom:
                            lengthFrom,

                        lengthUpto:
                            lengthUpto,

                        girthFrom:
                            girthFrom,

                        girthUpto:
                            girthUpto,

                        rate:
                            rate,

                        category:
                            category,

                        displayOrder:
                            displayOrder,

                        isActive:
                            isActive,
                      );
                    }

                    if (!dialogContext.mounted) {
  return;
}

Navigator.pop(
  dialogContext,
);

await loadData();

                    setState(() {});
                  },

                  child:
                      const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // POLE RATES SCREEN
  // ============================================================

  Future<void> showPoleRates(
    Map<String, dynamic> species,
  ) async {

    List<Map<String, dynamic>> rates =
        await repository.getAllPoleRates(
      species["id"],
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {

        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {

            Future<void> reloadRates() async {

              rates =
                  await repository.getAllPoleRates(
                species["id"],
              );

              setDialogState(() {});
            }

            return AlertDialog(

              title: Text(
                "${species["value"]} - Pole Rates",
              ),

              content: SizedBox(

                width: 850,
                height: 500,

                child: rates.isEmpty

                    ? const Center(
                        child: Text(
                          "No rate slabs found.",
                        ),
                      )

                    : SingleChildScrollView(

                        scrollDirection:
                            Axis.horizontal,

                        child:
                            SingleChildScrollView(

                          child: DataTable(

                            columns: const [

                              DataColumn(
                                label:
                                    Text("Length"),
                              ),

                              DataColumn(
                                label:
                                    Text("Girth"),
                              ),

                              DataColumn(
                                label:
                                    Text("Rate"),
                              ),

                              DataColumn(
                                label:
                                    Text("Category"),
                              ),

                              DataColumn(
                                label:
                                    Text("Status"),
                              ),

                              DataColumn(
                                label:
                                    Text("Action"),
                              ),
                            ],

                            rows: rates
                                .map(
                                  (rateItem) {

                                    final length =
                                        "${rateItem["lengthFrom"]} - "
                                        "${rateItem["lengthUpto"]}";

                                    final girth =
                                        "${rateItem["girthFrom"]} - "
                                        "${rateItem["girthUpto"]}";

                                    final active =
                                        rateItem[
                                                "isActive"] ==
                                            1;

                                    return DataRow(
                                      cells: [

                                        DataCell(
                                          Text(
                                            length,
                                          ),
                                        ),

                                        DataCell(
                                          Text(
                                            girth,
                                          ),
                                        ),

                                        DataCell(
                                          Text(
                                            "₹ ${rateItem["rate"]}",
                                          ),
                                        ),

                                        DataCell(
                                          Text(
                                            rateItem[
                                                    "category"] ??
                                                "",
                                          ),
                                        ),

                                        DataCell(
                                          Text(
                                            active
                                                ? "Active"
                                                : "Inactive",
                                          ),
                                        ),

                                        DataCell(
                                          IconButton(
                                            tooltip:
                                                "Edit",
                                            icon:
                                                const Icon(
                                              Icons.edit,
                                            ),
                                            onPressed:
                                                () async {

                                              await showPoleRateDialog(
                                                species:
                                                    species,
                                                rateItem:
                                                    rateItem,
                                              );

                                              await reloadRates();
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                                .toList(),
                          ),
                        ),
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
                      const Text("Close"),
                ),

                ElevatedButton.icon(
                  onPressed: () async {

                    await showPoleRateDialog(
                      species:
                          species,
                    );

                    await reloadRates();
                  },

                  icon:
                      const Icon(Icons.add),

                  label:
                      const Text(
                    "Add Rate",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget buildSection({
    required String title,
    required String group,
    required List<Map<String, dynamic>> items,
  }) {

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(
              children: [

                Expanded(
                  child: Text(
                    title,
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    showSpeciesDialog(
                      group: group,
                    );
                  },
                  icon:
                      const Icon(Icons.add),
                  label:
                      const Text("Add"),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (items.isEmpty)

              const Padding(
                padding:
                    EdgeInsets.all(12),
                child: Text(
                  "No records found.",
                ),
              )

            else

              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,

                child: DataTable(
                  columns:
                      buildColumns(group),

                  rows: items
                      .map(
                        (item) =>
                            buildRow(
                          group,
                          item,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COLUMNS
  // ============================================================

  List<DataColumn> buildColumns(
    String group,
  ) {

    if (group == "TIMBER") {

      return const [

        DataColumn(
          label:
              Text("Species"),
        ),

        DataColumn(
          label:
              Text("Scientific Name"),
        ),

        DataColumn(
          label:
              Text("Kannada Name"),
        ),

        DataColumn(
          label:
              Text("Rate / m³"),
        ),

        DataColumn(
          label:
              Text("Category"),
        ),

        DataColumn(
          label:
              Text("Status"),
        ),

        DataColumn(
          label:
              Text("Action"),
        ),
      ];
    }

    if (group == "POLE") {

      return const [

        DataColumn(
          label:
              Text("Species"),
        ),

        DataColumn(
          label:
              Text("Scientific Name"),
        ),

        DataColumn(
          label:
              Text("Kannada Name"),
        ),

        DataColumn(
          label:
              Text("Rates"),
        ),

        DataColumn(
          label:
              Text("Status"),
        ),

        DataColumn(
          label:
              Text("Action"),
        ),
      ];
    }

    if (group == "SANDAL") {

      return const [

        DataColumn(
          label:
              Text("Species"),
        ),

        DataColumn(
          label:
              Text("Scientific Name"),
        ),

        DataColumn(
          label:
              Text("Kannada Name"),
        ),

        DataColumn(
          label:
              Text("Status"),
        ),

        DataColumn(
          label:
              Text("Action"),
        ),
      ];
    }

    return const [

      DataColumn(
        label:
            Text("Rate / Ton"),
      ),

      DataColumn(
        label:
            Text("Status"),
      ),

      DataColumn(
        label:
            Text("Action"),
      ),
    ];
  }

  // ============================================================
  // ROW
  // ============================================================

  DataRow buildRow(
    String group,
    Map<String, dynamic> item,
  ) {

    final active =
        item["isActive"] == 1;

    if (group == "TIMBER") {

      return DataRow(
        cells: [

          DataCell(
            Text(
              item["value"] ?? "",
            ),
          ),

          DataCell(
            Text(
              item["scientificName"] ??
                  "",
            ),
          ),

          DataCell(
            Text(
              item["kannadaName"] ??
                  "",
            ),
          ),

          DataCell(
            Text(
              item["ratePerCubicMeter"]
                      ?.toString() ??
                  "",
            ),
          ),

          DataCell(
            Text(
              item["category"] ?? "",
            ),
          ),

          buildStatusCell(active),

          buildEditCell(
            group,
            item,
          ),
        ],
      );
    }

    if (group == "POLE") {

      return DataRow(
        cells: [

          DataCell(
            Text(
              item["value"] ?? "",
            ),
          ),

          DataCell(
            Text(
              item["scientificName"] ??
                  "",
            ),
          ),

          DataCell(
            Text(
              item["kannadaName"] ??
                  "",
            ),
          ),

          DataCell(
            ElevatedButton(
              onPressed: () {
                showPoleRates(item);
              },
              child:
                  const Text("VIEW RATES"),
            ),
          ),

          buildStatusCell(active),

          buildEditCell(
            group,
            item,
          ),
        ],
      );
    }

    if (group == "SANDAL") {

      return DataRow(
        cells: [

          DataCell(
            Text(
              item["value"] ?? "",
            ),
          ),

          DataCell(
            Text(
              item["scientificName"] ??
                  "",
            ),
          ),

          DataCell(
            Text(
              item["kannadaName"] ??
                  "",
            ),
          ),

          buildStatusCell(active),

          buildEditCell(
            group,
            item,
          ),
        ],
      );
    }

    return DataRow(
      cells: [

        DataCell(
          Text(
            item["ratePerTon"]
                    ?.toString() ??
                "",
          ),
        ),

        buildStatusCell(active),

        buildEditCell(
          group,
          item,
        ),
      ],
    );
  }

  DataCell buildStatusCell(
    bool active,
  ) {

    return DataCell(
      Text(
        active
            ? "Active"
            : "Inactive",
      ),
    );
  }

  DataCell buildEditCell(
    String group,
    Map<String, dynamic> item,
  ) {

    return DataCell(
      IconButton(
        tooltip: "Edit",
        icon:
            const Icon(Icons.edit),
        onPressed: () {
          showSpeciesDialog(
            group: group,
            item: item,
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text(
          "Species Master",
        ),
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : RefreshIndicator(
              onRefresh:
                  loadData,

              child: ListView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                children: [

                  buildSection(
                    title: "TIMBER",
                    group: "TIMBER",
                    items: timber,
                  ),

                  buildSection(
                    title: "POLES",
                    group: "POLE",
                    items: poles,
                  ),

                  buildSection(
                    title: "SANDAL",
                    group: "SANDAL",
                    items: sandal,
                  ),

                  buildSection(
                    title: "FIREWOOD",
                    group: "FIREWOOD",
                    items: firewood,
                  ),
                ],
              ),
            ),
    );
  }
}