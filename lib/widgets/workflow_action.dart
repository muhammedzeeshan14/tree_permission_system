import '../services/workflow_action_gate.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// One in-flight action per page. Dialogs have their own route, so confirmation
/// buttons remain usable while the calling page is waiting for their answer.
final _runningWorkflowActions = WorkflowActionGate();
bool workflowActionIsRunning(BuildContext context) =>
    _runningWorkflowActions.isRunning(ModalRoute.of(context) ?? context);

VoidCallback? workflowAction(BuildContext context, FutureOr<void> Function()? action) {
  if (action == null) return null;
  return () async {
    final route = ModalRoute.of(context);
    final key = route ?? context;
    if (!_runningWorkflowActions.acquire(key)) return;
    OverlayEntry? indicator;
    try {
      indicator = OverlayEntry(builder: (overlayContext) => AnimatedBuilder(
        animation: Listenable.merge([route?.animation, route?.secondaryAnimation]),
        builder: (_, __) => route != null && !route.isCurrent ? const SizedBox.shrink() : Stack(children: [
          const Positioned.fill(child: ModalBarrier(dismissible: false, color: Color(0x22000000))),
          Positioned(
          left: 16, right: 16, top: MediaQuery.paddingOf(overlayContext).top + 8,
          child: IgnorePointer(child: Material(elevation: 8, borderRadius: BorderRadius.circular(8),
            color: Theme.of(overlayContext).colorScheme.surface,
            child: const Padding(padding: EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
              LinearProgressIndicator(), SizedBox(height: 10),
              Text('Processing… Please wait. Do not press again.', semanticsLabel: 'Processing. Please wait.'),
            ])),
          )),
        ),
        ]),
      ));
      Overlay.of(context).insert(indicator);
      await action();
    } catch (error, stack) {
      debugPrint('Workflow action failed: $error\n$stack');
      if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Action could not finish: $error')),
      );
    } finally {
      indicator?.remove();
      indicator?.dispose();
      _runningWorkflowActions.release(key);
    }
  };
}
