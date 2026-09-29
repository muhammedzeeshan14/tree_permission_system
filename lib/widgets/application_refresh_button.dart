import 'package:flutter/material.dart';
import 'workflow_action.dart';

class ApplicationRefreshButton extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const ApplicationRefreshButton({super.key, required this.onRefresh});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Refresh applications', icon: const Icon(Icons.refresh),
    onPressed: workflowAction(context, onRefresh),
  );
}
