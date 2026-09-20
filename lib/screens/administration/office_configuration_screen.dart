import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import '../../repositories/office_configuration_repository.dart';
import '../../repositories/rfo_letter_configuration_repository.dart';

class OfficeConfigurationScreen extends StatefulWidget {
  const OfficeConfigurationScreen({super.key});

  @override
  State<OfficeConfigurationScreen> createState() =>
      _OfficeConfigurationScreenState();
}

class _OfficeConfigurationScreenState
    extends State<OfficeConfigurationScreen> {

  final rangeNameController = TextEditingController();

final rangeLocationController =
    TextEditingController();

final rangeCodeController = TextEditingController();

  final officePrefixController = TextEditingController();

  final financialYearController = TextEditingController();

  final officeAddressController = TextEditingController();

final rangeEmailController = TextEditingController();

String rfoOfficeLogoPath = "";

final divisionController = TextEditingController();

  final subDivisionController = TextEditingController();

  final RfoLetterConfigurationRepository
    rfoLetterConfigurationRepository =
    RfoLetterConfigurationRepository();

final rtcRfoLetterNumberController =
    TextEditingController();

final privateLandRfoLetterNumberController =
    TextEditingController();

final stateGovernmentRfoLetterNumberController =
    TextEditingController();

final centralGovernmentRfoLetterNumberController =
    TextEditingController();

final governmentLandRfoLetterNumberController =
    TextEditingController();

final sandalPrivateRfoLetterNumberController =
    TextEditingController();

final sandalGovernmentRfoLetterNumberController =
    TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    final data =
        await OfficeConfigurationRepository()
            .getConfiguration();

    if (data == null) return;

  rangeNameController.text =
    data["rangeName"] ?? "";

rangeLocationController.text =
    data["rangeLocation"] ?? "";

rangeCodeController.text =
    data["rangeCode"] ?? "";

    officePrefixController.text =
        data["officePrefix"] ?? "";

    financialYearController.text =
        data["financialYear"] ?? "";

    officeAddressController.text =
    data["rangeOfficeAddress"] ?? "";

rangeEmailController.text =
    data["rangeEmail"] ?? "";

rfoOfficeLogoPath =
    data["rfoOfficeLogoPath"]?.toString() ?? "";

divisionController.text =
    data["division"] ?? "";

   subDivisionController.text =
    data["subDivision"] ?? "";

final rfoLetterNumbers =
    await rfoLetterConfigurationRepository
        .getAllLetterNumbers();

rtcRfoLetterNumberController.text =
    rfoLetterNumbers["RTC"] ?? "";

privateLandRfoLetterNumberController.text =
    rfoLetterNumbers["PL"] ?? "";

stateGovernmentRfoLetterNumberController.text =
    rfoLetterNumbers["STGL"] ?? "";

centralGovernmentRfoLetterNumberController.text =
    rfoLetterNumbers["CGL"] ?? "";

governmentLandRfoLetterNumberController.text =
    rfoLetterNumbers["GL"] ?? "";

sandalPrivateRfoLetterNumberController.text =
    rfoLetterNumbers["SPL"] ?? "";

sandalGovernmentRfoLetterNumberController.text =
    rfoLetterNumbers["SGL"] ?? "";

setState(() {});
  }

  Future<void> selectRfoOfficeLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.single.path == null) {
      return;
    }

    final selectedFile =
        File(result.files.single.path!);

    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final logoDirectory = Directory(
      p.join(
        documentsDirectory.path,
        "TPMS",
        "Office Configuration",
      ),
    );

    if (!await logoDirectory.exists()) {
      await logoDirectory.create(recursive: true);
    }

    final extension =
        p.extension(selectedFile.path).toLowerCase();

    final savedLogoPath = p.join(
      logoDirectory.path,
      "rfo_office_logo$extension",
    );

    final previousLogoPath = rfoOfficeLogoPath;

    if (p.normalize(selectedFile.path) !=
        p.normalize(savedLogoPath)) {
      await selectedFile.copy(savedLogoPath);
    }

    if (previousLogoPath.isNotEmpty &&
        p.normalize(previousLogoPath) !=
            p.normalize(savedLogoPath)) {
      final previousFile = File(previousLogoPath);

      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    if (!mounted) return;

    setState(() {
      rfoOfficeLogoPath = savedLogoPath;
    });
  }

  Future<void> removeRfoOfficeLogo() async {
    if (rfoOfficeLogoPath.isNotEmpty) {
      final logoFile = File(rfoOfficeLogoPath);

      if (await logoFile.exists()) {
        await logoFile.delete();
      }
    }

    if (!mounted) return;

    setState(() {
      rfoOfficeLogoPath = "";
    });
  }


  Widget field(
      String title,
      TextEditingController controller) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 15),

      child: TextField(

        controller: controller,

        decoration: InputDecoration(

          labelText: title,

          border: const OutlineInputBorder(),

        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:
            const Text("Office Configuration"),

      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: ListView(

          children: [

            field(
    "Range Name",
    rangeNameController),

field(
    "Range Location",
    rangeLocationController),

field(
    "Range Code",
    rangeCodeController),

            field(
                "Office Prefix",
                officePrefixController),

            field(
                "Financial Year",
                financialYearController),

            field(
    "Range Office Postal Address",
    officeAddressController),

field(
    "Range Email",
    rangeEmailController),

Card(
  margin: const EdgeInsets.only(bottom: 15),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "RFO Office Logo",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (rfoOfficeLogoPath.isNotEmpty)
          Center(
            child: Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Image.file(
                File(rfoOfficeLogoPath),
                fit: BoxFit.contain,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Center(
                    child: Text(
                      "Logo file not available",
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "No logo uploaded",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: selectRfoOfficeLogo,
              icon: const Icon(Icons.upload_file),
              label: Text(
                rfoOfficeLogoPath.isEmpty
                    ? "UPLOAD LOGO"
                    : "REPLACE LOGO",
              ),
            ),
            if (rfoOfficeLogoPath.isNotEmpty)
              OutlinedButton.icon(
                onPressed: removeRfoOfficeLogo,
                icon: const Icon(Icons.delete_outline),
                label: const Text("REMOVE LOGO"),
              ),
          ],
        ),
      ],
    ),
  ),
),

field(
    "Division",
    divisionController),

            field(
    "Sub Division",
    subDivisionController),

const SizedBox(height: 10),

const Text(
  "RFO Letter Numbers",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 15),

field(
  "RTC RFO Letter Number",
  rtcRfoLetterNumberController,
),

field(
  "Private Land RFO Letter Number",
  privateLandRfoLetterNumberController,
),

field(
  "State Government Land RFO Letter Number",
  stateGovernmentRfoLetterNumberController,
),

field(
  "Central Government Land RFO Letter Number",
  centralGovernmentRfoLetterNumberController,
),

field(
  "Government Land RFO Letter Number",
  governmentLandRfoLetterNumberController,
),

field(
  "Sandal Private RFO Letter Number",
  sandalPrivateRfoLetterNumberController,
),

field(
  "Sandal Government RFO Letter Number",
  sandalGovernmentRfoLetterNumberController,
),

const SizedBox(height: 20),

            SizedBox(

              height: 50,

              child: ElevatedButton(

                onPressed: () async {

                  await OfficeConfigurationRepository()
                      .saveConfiguration(

                   rangeName:
    rangeNameController.text,

rangeLocation:
    rangeLocationController.text,

rangeCode:
    rangeCodeController.text,

                    officePrefix:
                        officePrefixController.text,

                    financialYear:
                        financialYearController.text,

                    rangeOfficeAddress:
    officeAddressController.text,

rangeEmail:
    rangeEmailController.text,

rfoOfficeLogoPath:
    rfoOfficeLogoPath,

division:
    divisionController.text,

                    subDivision:
                        subDivisionController.text,

                  );

await Future.wait([
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "RTC",
    letterNumber:
        rtcRfoLetterNumberController.text,
  ),
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "PL",
    letterNumber:
        privateLandRfoLetterNumberController.text,
  ),
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "STGL",
    letterNumber:
        stateGovernmentRfoLetterNumberController.text,
  ),
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "CGL",
    letterNumber:
        centralGovernmentRfoLetterNumberController.text,
  ),
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "GL",
    letterNumber:
        governmentLandRfoLetterNumberController.text,
  ),
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "SPL",
    letterNumber:
        sandalPrivateRfoLetterNumberController.text,
  ),
  rfoLetterConfigurationRepository
      .saveLetterNumber(
    applicationTypeCode: "SGL",
    letterNumber:
        sandalGovernmentRfoLetterNumberController.text,
  ),
]);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content: Text(
                          "Configuration Saved"),

                    ),

                  );

                },

                child: const Text(
                    "SAVE CONFIGURATION"),

              ),

            ),

          ],

        ),

      ),

    );

  }

}