import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../widgets/responsive_actions.dart';
import '../../../models/application_revenue_opinion_model.dart';

import '../../../repositories/application_revenue_opinion_repository.dart';
import '../../../repositories/revenue_opinion_repository.dart';
import '../../../models/revenue_opinion_model.dart';

class RevenueOpinionStep extends StatefulWidget {

  final ApplicationModel application;

  final VoidCallback onBack;

  final VoidCallback onNext;

  const RevenueOpinionStep({

    super.key,

    required this.application,

    required this.onBack,

    required this.onNext,

  });

  @override
  State<RevenueOpinionStep> createState() =>
      _RevenueOpinionStepState();

}

class _RevenueOpinionStepState
    extends State<RevenueOpinionStep> {

  final revenueRepo =
      RevenueOpinionRepository();

  final applicationRepo =
      ApplicationRevenueOpinionRepository();

  List<RevenueOpinionModel> opinions = [];

  int? selectedOpinionId;

  @override
  void initState(){

    super.initState();

    load();

  }

  Future<void> load() async{

    opinions =
        await revenueRepo.getActive();

    final existing =
        await applicationRepo
            .getByApplication(
      widget.application.id!,
    );

    selectedOpinionId = existing?.revenueOpinionId;

if (mounted) {
  setState(() {});
}
 
  }

 Future<void> save() async {

  debugPrint("STEP 1");

  if (selectedOpinionId == null) {

    debugPrint("STEP 2 - No Revenue Opinion Selected");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please select Revenue Opinion.",
        ),
      ),
    );

    return;

  }

  debugPrint("STEP 3 - Selected ID = $selectedOpinionId");

  await applicationRepo.save(

    ApplicationRevenueOpinionModel(

      applicationId: widget.application.id!,

      revenueOpinionId: selectedOpinionId!,

    ),

  );

  debugPrint("STEP 4 - Saved");

  if (!mounted) return;

  debugPrint("STEP 5 - Going Next");

  widget.onNext();

}

  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Revenue Opinion",
        ),

      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          children: [

            DropdownButtonFormField<int>(

              initialValue:selectedOpinionId,

              decoration:
                  const InputDecoration(

                labelText:
                    "Revenue Opinion",

                border:
                    OutlineInputBorder(),

              ),

              items: opinions.map((item){

                return DropdownMenuItem<int>(
  value: item.id,

                  child: Text(
  item.revenueOpinion,
),

                );

              }).toList(),

              onChanged:(value){

                if (value == null) return;

setState(() {

  selectedOpinionId = value;

});

              },

            ),

            const Spacer(),

            ResponsiveActions(

              children:[

                  ElevatedButton(

                    onPressed:
                        widget.onBack,

                    child:
                        const Text("BACK"),

                  ),

                  ElevatedButton(

                    onPressed:save,

                    child: const Text(

                      "SAVE & CONTINUE",

                    ),

                  ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}