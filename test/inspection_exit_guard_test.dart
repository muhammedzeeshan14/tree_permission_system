import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/widgets/inspection_exit_guard.dart';
import 'package:tree_permission_system/widgets/workflow_action.dart';

void main() {
  testWidgets('Back requires confirmation and is blocked while saving', (tester) async {
    final saved = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      child: const Text('Open'), onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => InspectionExitGuard(
        child: Builder(builder: (context) => Scaffold(appBar: AppBar(title: const Text('Inspection')), body: TextButton(
          onPressed: workflowAction(context, () => saved.future), child: const Text('Save'),
        ))),
      ))),
    )))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
    expect(find.text('Leave this screen?'), findsOneWidget);
    await tester.tap(find.text('Stay and save')); await tester.pumpAndSettle();
    expect(find.text('Inspection'), findsOneWidget);
    await tester.tap(find.text('Save')); await tester.pump();
    await tester.binding.handlePopRoute(); await tester.pump();
    expect(find.text('Leave this screen?'), findsNothing);
    saved.complete(); await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
    await tester.tap(find.text('Leave')); await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
}
