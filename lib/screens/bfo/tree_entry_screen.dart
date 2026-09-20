import 'package:flutter/material.dart';

import '../../models/tree_model.dart';
import 'tree/add_edit_tree_screen.dart';

class TreeEntryScreen extends StatelessWidget {
  final int applicationId;
  final int treeNumber;
  final int? treeId;
  final TreeModel? tree;

  const TreeEntryScreen({
    super.key,
    required this.applicationId,
    required this.treeNumber,
    this.treeId,
    this.tree,
  });

  @override
  Widget build(BuildContext context) {
    final TreeModel treeModel =
        tree ??
        TreeModel(
  applicationId: applicationId,
  treeNumber: treeNumber.toString(),
  baseTreeNumber: treeNumber,
  stemType: "Single",
  stemLetter: "",
  stemSequence: 1,
  isLastStem: true,

  speciesId: 0,
  recommendationTypeId: 0,

  gbh: null,
  height: null,

notFitForTimber: false,

numberOfBranches: null,
  numberOfTwigs: null,

  firewood: 0,

  recommendationReasonIds: const [],

  remarks: "",
);

    return AddEditTreeScreen(
      tree: treeModel,
      isEdit: tree != null,
    );
  }
}