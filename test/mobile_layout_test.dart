import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/widgets/adaptive_layout.dart';
import 'package:tree_permission_system/widgets/responsive_actions.dart';
import 'package:tree_permission_system/widgets/verification_card.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget child, double width, double scale) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home:MediaQuery(
      data:MediaQueryData(size:Size(width,900),textScaler:TextScaler.linear(scale)),
      child:Scaffold(body:SingleChildScrollView(child:Padding(
        padding:const EdgeInsets.all(16),child:child))),
    )));
    await tester.pumpAndSettle();
  }
  for(final width in [320.0,360.0,390.0,600.0,1000.0]) {
    for(final scale in [1.0,1.5]) {
      testWidgets('Verification, documents, actions and time fit $width at $scale', (tester) async {
        String? decision;
        final card = VerificationCard(title:"Inspecting Officer's Overall Remarks",
          value:'Recommended',threeOptions:true,verificationStatus:null,
          onStatusChanged:(value)=>decision=value);
        await show(tester,card,width,scale);
        expect(tester.takeException(),isNull);
        await tester.tap(find.text('Re-inspect'));
        expect(decision,'Re-inspect');

        await show(tester,AdaptiveDocumentTile(
          leading:const Icon(Icons.picture_as_pdf),
          title:const Text('DRFO Deferred Letter for MYS/RFO/2026/11'),
          trailing:Wrap(spacing:8,runSpacing:8,children:[
            OutlinedButton.icon(onPressed:(){},icon:const Icon(Icons.visibility),label:const Text('VIEW')),
            ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.print),label:const Text('PRINT')),
          ]),
        ),width,scale);
        expect(tester.takeException(),isNull);
        expect(tester.getSize(find.text('DRFO Deferred Letter for MYS/RFO/2026/11')).width,greaterThan(150));

        await show(tester,ResponsiveActions(children:[
          OutlinedButton(onPressed:(){},child:const Text('PREVIOUS')),
          OutlinedButton(onPressed:(){},child:const Text('SAVE DRAFT')),
          ElevatedButton(onPressed:(){},child:const Text('FORWARD TO RFO')),
        ]),width,scale);
        expect(tester.takeException(),isNull);
        if(width<600*scale) {
          expect(tester.getTopLeft(find.text('SAVE DRAFT')).dy,greaterThan(tester.getTopLeft(find.text('PREVIOUS')).dy));
        }

        await show(tester,TimeEntryLayout(
          title:const Text('Mahazar start time'),
          hour:const TextField(decoration:InputDecoration(labelText:'HH',border:OutlineInputBorder())),
          minute:const TextField(decoration:InputDecoration(labelText:'MM',border:OutlineInputBorder())),
          period:DropdownButtonFormField<String>(initialValue:'AM',isExpanded:true,
            items:const [DropdownMenuItem(value:'AM',child:Text('AM')),DropdownMenuItem(value:'PM',child:Text('PM'))],onChanged:(_){}),
        ),width,scale);
        expect(tester.takeException(),isNull);
        if(width<600*scale) {
          expect(tester.getTopLeft(find.byType(DropdownButtonFormField<String>)).dy,
            greaterThan(tester.getBottomLeft(find.byType(TextField).first).dy));
        }
      });
    }
  }
  testWidgets('Navigation remains reachable in short viewport with keyboard', (tester) async {
    tester.view.physicalSize=const Size(360,600);tester.view.devicePixelRatio=1;
    tester.view.viewInsets=const FakeViewPadding(bottom:240);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Column(children:[
      const Expanded(child:Text('Form')),
      NavigationPanel(child:ResponsiveActions(children:[
        OutlinedButton(onPressed:(){},child:const Text('Previous')),
        OutlinedButton(onPressed:(){},child:const Text('Save draft')),
        ElevatedButton(onPressed:(){},child:const Text('Forward to RFO')),
      ])),
    ]))));
    expect(tester.takeException(),isNull);
    await tester.drag(find.byType(SingleChildScrollView),const Offset(0,-150));
    await tester.pumpAndSettle();
    expect(find.text('Forward to RFO').hitTestable(),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('Wide tree tables scroll without squeezing columns', (tester) async {
    await show(tester,SizedBox(height:240,child:ScrollableTableViewport(
      child:Column(children:[const Text('Tree enumeration'),
        Expanded(child:ListView(children:[Row(children:[
          for(var i=0;i<10;i++) SizedBox(width:100,child:Text('Column $i')),
        ])])),
      ]))),320,1.5);
    expect(tester.takeException(),isNull);
    final scroll = find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection==Axis.horizontal);
    await tester.drag(scroll,const Offset(-300,0));
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
  });

  testWidgets('Long applicant headers leave room for mobile form and navigation', (tester) async {
    tester.view.physicalSize=const Size(320,480);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Column(children:[
      ResponsiveHeader(child:Text(List.filled(60,'Applicant address').join(' '))),
      const Expanded(child:Center(child:Text('Inspection form'))),
      NavigationPanel(child:ResponsiveActions(children:[
        OutlinedButton(onPressed:(){},child:const Text('Previous')),
        ElevatedButton(onPressed:(){},child:const Text('Next')),
      ])),
    ]))));
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    expect(find.text('Inspection form').hitTestable(),findsOneWidget);
    expect(find.text('Next').hitTestable(),findsOneWidget);
  });

}
