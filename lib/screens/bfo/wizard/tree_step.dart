import 'package:flutter/material.dart';

import '../../../models/application_model.dart';

import '../tree/tree_list_screen.dart';
import '../tree/tree_count_home_screen.dart';
import '../../../repositories/application_type_permission_mapping_repository.dart';

class TreeStep extends StatefulWidget {
  final ApplicationModel application;

  final VoidCallback onNext;

  final VoidCallback onBack;

  const TreeStep({
    super.key,
    required this.application,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<TreeStep> createState() =>
      _TreeStepState();
}

class _TreeStepState
    extends State<TreeStep> {

      final mappingRepo =
    ApplicationTypePermissionMappingRepository();

  bool _opened = false;

  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

    if (!_opened) {

      _opened = true;

      WidgetsBinding.instance
          .addPostFrameCallback((_) {

        _openTreeScreen();

      });

    }

  }

  Future<void> _openTreeScreen() async {

  final bool? completed =
      await Navigator.push<bool>(

    context,

    MaterialPageRoute(

      builder: (_) {

        // RTC applications always take the tree-count flow, even
        // when the saved permissionType is blank (legacy rows).
        final isTreeCountFlow = widget.application.permissionType ==
                "Tree Count" ||
            widget.application.applicationType
                    .trim()
                    .toUpperCase() ==
                "RTC";

        if (isTreeCountFlow) {

          return TreeCountHomeScreen(

            applicationId:
                widget.application.id!,

          );

        }

        return TreeListScreen(

          applicationId:
              widget.application.id!,

        );

      },

    ),

  );

  if (!mounted) return;

  if (completed == true) {

    widget.onNext();

  } else {

    widget.onBack();

  }

}

  @override
  Widget build(BuildContext context) {

    return const Scaffold(

      body: Center(

        child: CircularProgressIndicator(),

      ),

    );

  }

}