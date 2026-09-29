import 'package:flutter/material.dart';
import 'workflow_action.dart';

/// Prevent accidental route exits; checkpoints saved with Next remain stored.
class InspectionExitGuard extends StatefulWidget {
  static Future<bool> mayLeave(BuildContext context) async {
    final state = context.findAncestorStateOfType<_InspectionExitGuardState>();
    return state == null || await state._askToLeave();
  }
  final Widget child;
  const InspectionExitGuard({super.key, required this.child});
  @override
  State<InspectionExitGuard> createState() => _InspectionExitGuardState();
}

class _InspectionExitGuardState extends State<InspectionExitGuard> {
  bool _asking = false;
  bool _allowExit = false;
  Future<bool> _askToLeave() async {
    if (_asking || workflowActionIsRunning(context)) return false;
    _asking = true;
    final leave = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Leave this screen?'),
      content: const Text('Entries saved using Next or Save are retained. To keep changes on the current page, stay here and save them first.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Stay and save')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Leave')),
      ],
    ));
    _asking = false;
    return mounted && leave == true;
  }
  Future<void> _confirmExit() async {
    if (!await _askToLeave() || !mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowExit,
    onPopInvokedWithResult: (didPop, result) { if (!didPop) _confirmExit(); },
    child: widget.child,
  );
}
