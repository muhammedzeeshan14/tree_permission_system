import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../models/tree_model.dart';

import '../../../repositories/application_repository.dart';

import '../../../services/tree_numbering_service.dart';

import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

import 'add_edit_tree_screen.dart';
import '../../../repositories/tree_repository.dart';

class StemTypeScreen extends StatefulWidget {
  final int applicationId;

  const StemTypeScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<StemTypeScreen> createState() =>
      _StemTypeScreenState();
}

class _StemTypeScreenState
    extends State<StemTypeScreen> {

  //----------------------------------------------------------
  // Repository & Services
  //----------------------------------------------------------

  final ApplicationRepository
      _applicationRepository =
      ApplicationRepository();

  final TreeNumberingService
      _numberingService =
      TreeNumberingService();

  //----------------------------------------------------------
  // Screen State
  //----------------------------------------------------------

  ApplicationModel? application;

  bool loading = true;

  String stemType = "Single";

  //----------------------------------------------------------
  // Init
  //----------------------------------------------------------

  @override
  void initState() {

    super.initState();

    _initialize();

  }

  Future<void> _initialize() async {

    application =
        await _applicationRepository.getById(
      widget.applicationId,
    );

    if (mounted) {

      setState(() {

        loading = false;

      });

    }

  }

  //----------------------------------------------------------
  // Continue
  //----------------------------------------------------------

  Future<void> _continue() async {
  try {
    print("ENTERED _continue()");

    setState(() {
      loading = true;
    });

    Map<String, dynamic> numberData;

    if (stemType == "Single") {
      print("STEP 1");
      numberData =
          await _numberingService.nextTree(
        widget.applicationId,
      );
      print(numberData);
    } else {

  final next =
      await _numberingService.nextTree(
    widget.applicationId,
  );

  numberData = {

    "treeNumber":
        "${next["baseTreeNumber"]}A",

    "baseTreeNumber":
        next["baseTreeNumber"],

    "stemLetter": "A",

  };

}

    final newTree = TreeModel(
  applicationId: widget.applicationId,
  treeNumber: numberData["treeNumber"],
  baseTreeNumber: numberData["baseTreeNumber"],
  stemType: stemType,
  stemLetter: numberData["stemLetter"],
  stemSequence: 1,
  isLastStem: true,

  speciesId: 0,

  recommendationTypeId: 0,

  gbh: null,
  height: null,
  numberOfBranches: null,
  numberOfTwigs: null,
  firewood: 0,

  recommendationReasonIds: const [],

  remarks: "",
);

    print("Opening AddEditTreeScreen");

    if (!mounted) return;

    final refresh =
    await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (_) => AddEditTreeScreen(
      tree: newTree,
      isEdit: false,
    ),
  ),
);

if (!mounted) return;

if (refresh == true) {
  Navigator.pop(context, true);
}
  } catch (e, st) {
    debugPrint("EXCEPTION:");
    debugPrint(e.toString());
    debugPrint(st.toString());
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

  //----------------------------------------------------------
  // BUILD
  //----------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: const TPMSAppBar(
        title: "Stem Type - TEST",
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : application == null

              ? const Center(
                  child: Text(
                    "Application not found.",
                  ),
                )

              : Column(

                  children: [

                    ApplicationHeaderCard(
                      application: application!,
                    ),

                    const WizardProgressCard(

                      currentStep: 5,

                      totalSteps: 8,

                      title:
                          "Select Stem Type",

                    ),

                    Expanded(

                      child:
                          SingleChildScrollView(

                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child: Card(

                          child: Padding(

                            padding:
                                const EdgeInsets.all(
                              16,
                            ),

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                const Text(

                                  "Select Stem Type",

                                  style: TextStyle(

                                    fontSize: 18,

                                    fontWeight:
                                        FontWeight.bold,

                                  ),

                                ),

                                const SizedBox(
                                  height: 20,
                                ),

                                RadioListTile<String>(

                                  value: "Single",

                                  groupValue:
                                      stemType,

                                  title: const Text(
                                    "Single Stem",
                                  ),

                                  subtitle:
                                      const Text(

                                    "Creates Tree No. 1, 2, 3 ...",

                                  ),

                                  onChanged:
                                      (value) {

                                    setState(() {

                                      stemType =
                                          value!;

                                    });

                                  },

                                ),

                                RadioListTile<String>(

                                  value: "Multiple",

                                  groupValue:
                                      stemType,

                                  title: const Text(
                                    "Multiple Stem",
                                  ),

                                  subtitle:
                                      const Text(

                                    "Creates Tree No. 2A, 5A, 8A ...",

                                  ),

                                  onChanged:
                                      (value) {

                                    setState(() {

                                      stemType =
                                          value!;

                                    });

                                  },

                                ),

                                const SizedBox(
                                  height: 30,
                                ),
                                                                SizedBox(

                                  width:
                                      double.infinity,

                                  height: 50,

                                  child:
                                      ElevatedButton(

                                    onPressed: loading ? null : _continue,

                                    child:
                                        const Text(

                                      "CONTINUE",

                                    ),

                                  ),

                                ),

                              ],

                            ),

                          ),

                        ),

                      ),

                    ),

                  ],

                ),

    );

  }
  }