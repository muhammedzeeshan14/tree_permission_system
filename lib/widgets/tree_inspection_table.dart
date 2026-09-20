import 'package:flutter/material.dart';

import '../models/tree_model.dart';

class TreeInspectionTable extends StatefulWidget {
  final List<TreeModel> trees;

  final Map<int, String> speciesMap;
  final Map<int, String> treeStatusMap;
  final Map<int, String> recommendationTypeMap;
  final Map<int, String> recommendationReasonMap;

  final bool showVerification;

  final Widget Function(TreeModel tree)? verificationBuilder;

  const TreeInspectionTable({
    super.key,
    required this.trees,
    required this.speciesMap,
    this.treeStatusMap = const {},
    required this.recommendationTypeMap,
    required this.recommendationReasonMap,
    this.showVerification = false,
    this.verificationBuilder,
  });

  @override
  State<TreeInspectionTable> createState() => _TreeInspectionTableState();
}

class _TreeInspectionTableState extends State<TreeInspectionTable> {
  final ScrollController _verticalController = ScrollController();
  List<TreeModel> get trees => widget.trees;
  Map<int,String> get speciesMap => widget.speciesMap;
  Map<int,String> get treeStatusMap => widget.treeStatusMap;
  Map<int,String> get recommendationTypeMap => widget.recommendationTypeMap;
  Map<int,String> get recommendationReasonMap => widget.recommendationReasonMap;
  bool get showVerification => widget.showVerification;
  Widget Function(TreeModel)? get verificationBuilder => widget.verificationBuilder;
  @override
  void dispose() { _verticalController.dispose(); super.dispose(); }

String _recommendationName(TreeModel tree) {
  return recommendationTypeMap[
          tree.recommendationTypeId] ??
      "-";
}

String _treeStatusName(TreeModel tree) {
  final statusId = tree.treeStatusId;

  if (statusId == null) return "-";

  return treeStatusMap[statusId] ?? "-";
}

String _recommendationReasons(TreeModel tree) {

  List<String> reasons = tree.recommendationReasonIds

      .map((id) => recommendationReasonMap[id] ?? "")

      .where((e) => e.isNotEmpty)

      .toList();

  if (tree.notFitForTimber) {

    reasons.add("Not Fit For Timber");

  }

  if (reasons.isEmpty) {

    return "-";

  }

  return reasons.join(", ");

}

Widget headerCell(String text) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget tableCell(String text) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      textAlign: TextAlign.center,
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scrollbar(
  controller: _verticalController,
  thumbVisibility: true,
  child: SingleChildScrollView(
    controller: _verticalController,
    primary: false,
    scrollDirection: Axis.vertical,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
      border: TableBorder.all(),
      defaultVerticalAlignment:
          TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FixedColumnWidth(40),
        1: const FixedColumnWidth(50),
        2: const FixedColumnWidth(120),
        3: const FixedColumnWidth(60),
        4: const FixedColumnWidth(80),
        5: const FixedColumnWidth(100),
        6: const FixedColumnWidth(100),
        7: const FixedColumnWidth(150),
        8: const FixedColumnWidth(150),
        9: const FixedColumnWidth(150),

        if (showVerification)
          10: const FixedColumnWidth(200),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xffE8F5E9),
          ),
          children: [
            headerCell("Sl"),
            headerCell("Tree No"),
            headerCell("Species"),
            headerCell("Tree Status"),
            headerCell("GBH (m)"),
            headerCell("Height (m)"),
            headerCell("Branch/Twig"),
            headerCell("Firewood (Tonnes)"),
            headerCell("Recommendation"),
            headerCell("Reason"),

            if (showVerification)
              headerCell("Verification"),
          ],
        ),

        ...List.generate(trees.length, (index) {
          final tree = trees[index];

          return TableRow(
            children: [
              tableCell("${index + 1}"),
              tableCell(tree.treeNumber),
              tableCell(
                speciesMap[tree.speciesId] ?? "",
              ),
              tableCell(
                _treeStatusName(tree),
              ),
              tableCell(
                tree.gbh?.toStringAsFixed(2) ?? "-",
              ),
tableCell(
    tree.height?.toStringAsFixed(2) ?? "-"),

              tableCell(
                tree.numberOfBranches != null
                    ? tree.numberOfBranches.toString()
                    : tree.numberOfTwigs != null
                        ? tree.numberOfTwigs.toString()
                        : "-",
              ),

              tableCell(tree.firewood.toStringAsFixed(2)),

              tableCell(
                  _recommendationName(tree)),

              tableCell(
                  _recommendationReasons(tree)),

              if (showVerification)
                verificationBuilder != null
                    ? verificationBuilder!(tree)
                    : const SizedBox(),
            ],
          );
        }),
            ],
    ),
  ),
),
);
}

}