import 'package:flutter/material.dart';

import '../../repositories/master_repository.dart';
import '../../repositories/pole_rate_repository.dart';

class PoleRateMasterScreen extends StatefulWidget {
  const PoleRateMasterScreen({super.key});

  @override
  State<PoleRateMasterScreen> createState() =>
      _PoleRateMasterScreenState();
}

class _PoleRateMasterScreenState
    extends State<PoleRateMasterScreen> {

  final MasterRepository masterRepository =
      MasterRepository();

  final PoleRateRepository poleRateRepository =
      PoleRateRepository();

  List<Map<String, dynamic>> species = [];
  List<Map<String, dynamic>> rates = [];

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

    species =
        await masterRepository.getSpecies();

    rates =
        await poleRateRepository.getAllRates();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  String speciesName(int speciesId) {
    final match = species.where(
      (e) => e["id"] == speciesId,
    );

    if (match.isEmpty) {
      return "Unknown";
    }

    return match.first["value"] ?? "";
  }

  double? parseDouble(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(
      value.trim(),
    );
  }

  Future<void> showRateDialog({
    Map<String, dynamic>? item,
  }) async {

    int? selectedSpeciesId =
        item?["speciesId"];

    final lengthFromController =
        TextEditingController(
      text:
          item?["lengthFrom"]?.toString() ?? "",
    );

    final lengthUptoController =
        TextEditingController(
      text:
          item?["lengthUpto"]?.toString() ?? "",
    );

    final girthFromController =
        TextEditingController(
      text:
          item?["girthFrom"]?.toString() ?? "",
    );

    final girthUptoController =
        TextEditingController(
      text:
          item?["girthUpto"]?.toString() ?? "",
    );

    final rateController =
        TextEditingController(
      text:
          item?["rate"]?.toString() ?? "",
    );

    final categoryController =
        TextEditingController(
      text:
          item?["category"] ?? "",
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
                    ? "Add Pole Rate"
                    : "Edit Pole Rate",
              ),

              content: SizedBox(

                width: 600,

                child:
                    SingleChildScrollView(

                  child: Column(

                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      DropdownButtonFormField<int>(
  value: selectedSpeciesId,

  decoration: const InputDecoration(
    labelText: "Species",
    border: OutlineInputBorder(),
  ),

  items: species.map((e) {
    return DropdownMenuItem<int>(
      value: e["id"] as int,
      child: Text(
        e["value"]?.toString() ?? "",
      ),
    );
  }).toList(),

  onChanged: (value) {
    setDialogState(() {
      selectedSpeciesId = value;
    });
  },
),

                      const SizedBox(
                        height: 15,
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
                        height: 15,
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
                        height: 15,
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
                              "Rate per Pole",
                          prefixText:
                              "₹ ",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      TextField(
                        controller:
                            categoryController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Category",
                          hintText:
                              "Pole / Timber",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
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
                        height: 10,
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
                        onChanged:
                            (value) {

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
                      const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {

                    if (selectedSpeciesId ==
                        null) {

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select species.",
                          ),
                        ),
                      );

                      return;
                    }

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

                    if (lengthFrom ==
                            null ||
                        lengthUpto ==
                            null ||
                        girthFrom ==
                            null ||
                        girthUpto ==
                            null ||
                        rate == null) {

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter all length, girth and rate values.",
                          ),
                        ),
                      );

                      return;
                    }

                    if (lengthUpto <=
                        lengthFrom) {

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
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

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Girth Upto must be greater than Girth From.",
                          ),
                        ),
                      );

                      return;
                    }

                    if (categoryController
                        .text
                        .trim()
                        .isEmpty) {

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Category is required.",
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

                    if (item == null) {

                      await poleRateRepository
                          .insertRate(

                        speciesId:
                            selectedSpeciesId!,

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
                            categoryController
                                .text
                                .trim(),

                        displayOrder:
                            displayOrder,

                        isActive:
                            isActive,
                      );

                    } else {

                      await poleRateRepository
                          .updateRate(

                        id:
                            item["id"],

                        speciesId:
                            selectedSpeciesId!,

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
                            categoryController
                                .text
                                .trim(),

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
                  },

                  child:
                      const Text(
                    "Save",
                  ),
                ),

              ],
            );
          },
        );
      },
    );

  }

  Future<void> deleteRate(
    Map<String, dynamic> item,
  ) async {

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          title:
              const Text(
            "Delete Pole Rate",
          ),

          content:
              const Text(
            "Are you sure you want to delete this rate category?",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                "Delete",
              ),
            ),

          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await poleRateRepository.deleteRate(
      item["id"],
    );

    await loadData();
  }

  String rangeText(
    dynamic from,
    dynamic upto,
  ) {

    return "${from ?? ""} - ${upto ?? ""}";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text(
          "Pole Rate Master",
        ),
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : rates.isEmpty

              ? const Center(
                  child: Text(
                    "No Pole Rate Records Found",
                    style:
                        TextStyle(
                      fontSize: 18,
                    ),
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
                              Text("Species"),
                        ),

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
                            (item) {

                              return DataRow(

                                cells: [

                                  DataCell(
                                    Text(
                                      item[
                                            "speciesName"] ??
                                          "",
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      rangeText(
                                        item[
                                            "lengthFrom"],
                                        item[
                                            "lengthUpto"],
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      rangeText(
                                        item[
                                            "girthFrom"],
                                        item[
                                            "girthUpto"],
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      "₹ ${item["rate"] ?? ""}",
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      item[
                                              "category"] ??
                                          "",
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      item[
                                                  "isActive"] ==
                                              1
                                          ? "Active"
                                          : "Inactive",
                                    ),
                                  ),

                                  DataCell(

                                    Row(

                                      mainAxisSize:
                                          MainAxisSize.min,

                                      children: [

                                        IconButton(
                                          tooltip:
                                              "Edit",
                                          icon:
                                              const Icon(
                                            Icons.edit,
                                          ),
                                          onPressed: () {
                                            showRateDialog(
                                              item:
                                                  item,
                                            );
                                          },
                                        ),

                                        IconButton(
                                          tooltip:
                                              "Delete",
                                          icon:
                                              const Icon(
                                            Icons.delete,
                                          ),
                                          onPressed: () {
                                            deleteRate(
                                              item,
                                            );
                                          },
                                        ),

                                      ],
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

      floatingActionButton:
          FloatingActionButton.extended(

        onPressed: () {
          showRateDialog();
        },

        icon:
            const Icon(Icons.add),

        label:
            const Text(
          "Add Pole Rate",
        ),
      ),
    );
  }
}