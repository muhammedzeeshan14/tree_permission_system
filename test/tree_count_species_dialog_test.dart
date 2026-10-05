import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/widgets/tree_count_species_dialog.dart';

void main() {
  testWidgets('RTC species search selects, dismisses and reopens on mobile without disposed controller errors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? selected;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(child: const Text('Species'), onPressed: () async {
        selected = await showDialog<Map<String, dynamic>>(context: context,
          builder: (_) => const TreeCountSpeciesDialog(species: [
            {'id': 123, 'value': 'Teak', 'speciesGroup': 'TIMBER'},
            {'id': 124, 'value': 'Mango', 'speciesGroup': 'TIMBER'},
          ]));
      }),
    ))));
    await tester.tap(find.text('Species'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();
    expect(find.text('Mango'), findsNothing);
    await tester.tap(find.text('Teak'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(selected?['id'], 123);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Species'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });
}
