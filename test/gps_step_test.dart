import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:tree_permission_system/models/application_model.dart';
import 'package:tree_permission_system/screens/bfo/wizard/gps_step.dart';

class FakeGps extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  int fixes = 0;
  @override Future<bool> isLocationServiceEnabled() async => enabled;
  @override Future<LocationPermission> checkPermission() async => permission;
  @override Future<LocationPermission> requestPermission() async => permission;
  @override Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    fixes++;
    return Position(latitude: 12.3456789, longitude: 76.5432101, timestamp: DateTime(2026), accuracy: 5, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
  }
}
ApplicationModel application() => ApplicationModel(officeNumber: '',applicationType: 'PL',verifiedApplicationType: '',applicationDate: '',receivedDate: '',applicantName: '',applicantAddress: '',mobile: '',applicationSource: '',forwardedDate: '',section: '',beat: '',assignedBFO: '',assignedDRFO: '',purpose: '',gpsCoordinates: '',bfoVerificationDate: '',inspectionStarted: false,inspectionDecision: '',deferredReasonIds: [],overallRemarks: '',drfoInspectionDate: '',drfoOverallRemarks: '',rfoInspectionStarted: false,rfoInspectionDate: '',rfoOverallRemarks: '',returnReason: '',returnRemarks: '',returnedBy: '',returnedDate: '',trees: [],status: '',inspectionMode: '',createdDate: DateTime(2026));
void main() {
  late FakeGps gps;
  late GeolocatorPlatform original;
  setUp(() { original = GeolocatorPlatform.instance; gps = FakeGps(); GeolocatorPlatform.instance = gps; });
  tearDown(() { GeolocatorPlatform.instance = original; });
  testWidgets('Capture fills both coordinates and Next awaits one save', (tester) async {
    final app = application();
    final saved = Completer<void>();
    int saves = 0;
    await tester.pumpWidget(MaterialApp(home: GPSStep(application: app, onBack: () {}, onNext: () { saves++; return saved.future; })));
    final capture = find.text('GET CURRENT GPS');
    await tester.ensureVisible(capture); await tester.tap(capture); await tester.pumpAndSettle();
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[0].controller!.text, '12.3456789');
    expect(fields[1].controller!.text, '76.5432101');
    final next = find.text('SAVE & CONTINUE');
    await tester.ensureVisible(next); await tester.tap(next); await tester.pump();
    expect(saves, 1); expect(app.gpsCoordinates, '12.3456789,76.5432101');
    expect(find.textContaining('Processing'), findsOneWidget);
    saved.complete(); await tester.pumpAndSettle();
    expect(find.textContaining('Processing'), findsNothing);
  });
  for (final denied in [false, true]) {
    testWidgets(denied ? 'Denied permission keeps manual coordinates' : 'Disabled service does not request a fix', (tester) async {
      gps.enabled = denied;
      gps.permission = LocationPermission.deniedForever;
      final app = application()..gpsCoordinates = '11,77';
      await tester.pumpWidget(MaterialApp(home: GPSStep(application: app, onNext: () {}, onBack: () {})));
      final capture = find.text('RE-CAPTURE GPS'); await tester.ensureVisible(capture); await tester.tap(capture); await tester.pumpAndSettle();
      expect(gps.fixes, 0);
      expect(tester.widgetList<TextFormField>(find.byType(TextFormField)).first.controller!.text, '11');
      expect(find.text('Settings'), findsOneWidget);
    });
  }
  testWidgets('Windows gives manual entry guidance without calling native GPS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
    await tester.pumpWidget(MaterialApp(home: GPSStep(application: application(), onNext: () {}, onBack: () {})));
    final button = find.text('GET CURRENT GPS');
    await tester.ensureVisible(button); await tester.tap(button); await tester.pumpAndSettle();
    expect(gps.fixes, 0);
    expect(find.textContaining('Enter latitude and longitude manually'), findsOneWidget);
    } finally { debugDefaultTargetPlatformOverride = null; }
  });
  testWidgets('Invalid coordinate cannot advance', (tester) async {
    int next = 0;
    final app = application()..gpsCoordinates = '91,181';
    await tester.pumpWidget(MaterialApp(home: GPSStep(application: app, onNext: () { next++; }, onBack: () {})));
    final button = find.text('SAVE & CONTINUE'); await tester.ensureVisible(button); await tester.tap(button); await tester.pumpAndSettle();
    expect(next, 0); expect(find.textContaining('Enter valid latitude'), findsOneWidget);
  });
}
