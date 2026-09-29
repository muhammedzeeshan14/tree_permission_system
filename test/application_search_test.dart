import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/models/application_model.dart';
import 'package:tree_permission_system/screens/tree_permission/application_search_screen.dart';
import 'package:tree_permission_system/widgets/application_search_action.dart';

class SearchFixture implements ApplicationModel {
  @override String status;
  SearchFixture(this.status);
  @override String get officeNumber => 'MYS/RFO/2026/38';
  @override String get applicationType => 'Private Land';
  @override String get verifiedApplicationType => 'PL';
  @override String get beat => 'Nazarbad';
  @override String get section => 'Mysuru Urban';
  @override String get applicantName => 'Example Applicant';
  @override String get assignedBFO => 'Beat Officer';
  @override String get assignedDRFO => 'Section Officer';
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  test('All five filters support partial, case-insensitive searches including completed', () {
    final a = SearchFixture('Completed');
    final queries = {'Application number':'2026/38', 'Application type':'PRIVATE',
      'Beat':' nazar ', 'Section':'URBAN', 'Applicant name':'example'};
    for (final entry in queries.entries) {
      expect(matchesApplication(a, entry.key, entry.value), isTrue);
      expect(matchesApplication(a, entry.key, 'unmatched'), isFalse);
    }
    expect(matchesApplication(a, 'All fields', 'urban'), isTrue);
    expect(matchesApplication(a, 'Applicant name', 'urban'), isFalse);
    expect(matchesApplication(a, 'All fields', ''), isTrue);
  });
  test('Approved requests stay in printing; pending replies and completed are distinct', () {
    final a = SearchFixture('Approved');
    expect(applicationLocation(a), contains('RFO Approved Print'));
    a.status = 'Pending Revenue Opinion';
    expect(applicationLocation(a), 'Caseworker — Pending Revenue Opinion');
    a.status = 'Pending Government land approvals';
    expect(applicationLocation(a), contains('Pending Government Land Approvals'));
    a.status = 'Completed';
    expect(applicationLocation(a), 'Completed');
  });
  test('Assignment location uses actual officer and section or beat', () {
    final a = SearchFixture('Pending BFO Inspection');
    expect(applicationLocation(a), 'BFO — Beat Officer — Nazarbad');
    a.status = 'Pending DRFO Verification';
    expect(applicationLocation(a), 'DRFO — Section Officer — Mysuru Urban');
    a.status = 'Pending RFO Approval';
    expect(applicationLocation(a), 'RFO — Pending Approvals');
  });
  testWidgets('SEARCH remains readable in a narrow dashboard app bar', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(
      title: const Text('Case Worker Dashboard'), actions: [const ApplicationSearchAction(),
      IconButton(onPressed: () {}, icon: const Icon(Icons.refresh))]))));
    expect(find.text('SEARCH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
