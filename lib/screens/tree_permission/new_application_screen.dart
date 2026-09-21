import 'package:flutter/material.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/history_repository.dart';
import '../../models/application_model.dart';
import '../../models/application_reference_model.dart';
import '../../services/application_service.dart';
import '../../services/master_service.dart';
import '../../repositories/master_repository.dart';
import '../../repositories/application_type_repository.dart';
import '../../repositories/section_repository.dart';
import '../../repositories/beat_repository.dart';
import '../../repositories/forwarded_source_repository.dart';
import '../../widgets/forwarded_reference_widget.dart';
import '../../services/session_service.dart';
import '../../utils/date_picker_util.dart';
import '../../repositories/application_type_permission_mapping_repository.dart';

class NewApplicationScreen extends StatefulWidget {

  final ApplicationModel? application;

  const NewApplicationScreen({

    super.key,

    this.application,

  });

  @override
  State<NewApplicationScreen> createState() =>
      _NewApplicationScreenState();
}

class _NewApplicationScreenState
    extends State<NewApplicationScreen> {

  final applicationDateController = TextEditingController();
  final receivedDateController = TextEditingController();

  final applicantLetterNumberController = TextEditingController();
  final applicantNameController = TextEditingController();
  final applicantAddressController = TextEditingController();

final treeLocationController = TextEditingController();

final mobileController = TextEditingController();

  final purposeController = TextEditingController();
  final workNameController = TextEditingController();
  // ===========================
// EDIT MODE
// ===========================

bool get isEdit =>
    widget.application != null;
 List<Map<String, dynamic>> whyRemovingList = [];
List<Map<String, dynamic>> allPurposeList = [];
List<Map<String, dynamic>> purposeList = [];
List<Map<String, dynamic>> applicationTypeList = [];

List<Map<String, dynamic>> governmentAgencyList = [];
List<Map<String, dynamic>> urbanRuralList = [];
List<Map<String, dynamic>> structureTypeList = [];

int? governmentAgencyId;
int? urbanRuralId;
int? whyRemovingId;
int? purposeId;
int? structureTypeId;

List<Map<String, dynamic>> sectionList = [];
  List<Map<String, dynamic>> beatList = [];
  List<Map<String, dynamic>> forwardedSourceList = [];

String applicationSource = "DIRECT";

String forwardedDate = "";

List<ForwardReference> forwardReferences = [];

  String applicationType = "PL";
  bool get isGovernmentCategory =>
    applicationType == "GL" ||
    applicationType == "STGL" ||
    applicationType == "CGL" ||
    applicationType == "SGL";

bool get isPrivateCategory =>
    applicationType == "PL" ||
    applicationType == "SPL";

bool get showsAdditionalWorkDetails =>
    isGovernmentCategory || isPrivateCategory;

    bool get isRTC =>
    applicationType.trim().toUpperCase() == "RTC";

bool get requiresWhyRemovingAndPurpose =>
    !isRTC;

String get selectedWhyRemovingCode {
  if (whyRemovingId == null) return "";

  final matches = whyRemovingList.where(
    (item) => item["id"] == whyRemovingId,
  );

  if (matches.isEmpty) return "";

  return matches.first["code"]
          ?.toString()
          .trim()
          .toUpperCase() ??
      "";
}

bool get isDevelopmentWork =>
    selectedWhyRemovingCode == "WORKS";

bool get showsNameOfWork =>
    showsAdditionalWorkDetails &&
    isDevelopmentWork;

  String section = "";
String beat = "";

bool treeLocationSame = true;
  String formatDate(String value) {
  List<String> p = value.split("/");

  if (p.length != 3) return value;

  String day = p[0].padLeft(2, "0");
  String month = p[1].padLeft(2, "0");
  String year = p[2];

  if (year.length == 2) {
    year = "20$year";
  }

  return "$day/$month/$year";
}

@override
void initState() {
  super.initState();

  initializeScreen();
}
Future<void> initializeScreen() async {

  applicationDateController.text = "DD/MM/YYYY";
  receivedDateController.text = "DD/MM/YYYY";

  await loadWhyRemoving();

await loadPurpose();

await loadApplicationTypes();
  await loadAdditionalApplicationMasters();

  await loadSections();
  await loadForwardedSources();

  if (isEdit) {

    applicationDateController.text =
        widget.application!.applicationDate;

    receivedDateController.text =
        widget.application!.receivedDate;

    applicantLetterNumberController.text = widget.application!.applicantLetterNumber;
    applicantNameController.text =
        widget.application!.applicantName;

    applicantAddressController.text =
        widget.application!.applicantAddress;

    mobileController.text =
        widget.application!.mobile;

    purposeController.text =
        widget.application!.purpose;

purposeId =
    widget.application!.purposeId;

whyRemovingId =
    widget.application!.whyRemovingId;

// Load only purposes connected to the saved
// Why Removing selection.
filterPurposeList();

// Support old records that contain Purpose text
// but do not yet contain purposeId.
if (purposeId == null &&
    widget.application!.purpose.trim().isNotEmpty) {
  final matches = purposeList.where(
    (item) =>
        item["value"]?.toString().trim() ==
        widget.application!.purpose.trim(),
  );

  if (matches.isNotEmpty) {
    purposeId = matches.first["id"] as int;
  }
}

    applicationType =
        widget.application!.applicationType;

    governmentAgencyId =
    widget.application!.governmentAgencyId;

urbanRuralId =
    widget.application!.urbanRuralId;

structureTypeId =
    widget.application!.structureTypeId;

workNameController.text =
    widget.application!.workName;

    section =
        widget.application!.section;

    await loadBeats();

    beat =
        widget.application!.beat;
            applicationSource =
        widget.application!.applicationSource;

    forwardedDate =
        widget.application!.forwardedDate;

    forwardReferences =
        widget.application!.forwardingReferences
            .map(
              (ref) => ForwardReference(
                sourceId: ref.sourceId,
                sourceName: ref.forwardedBy,
                referenceNumber:
                    ref.referenceNumber,
                referenceDate:
                    ref.referenceDate,
              ),
            )
            .toList();

  }

  if (mounted) {
    setState(() {});
  }

}

Future<void> loadWhyRemoving() async {
  final allItems =
      await MasterRepository().getMasters(
    "Why Removing",
  );

  final existingId =
      widget.application?.whyRemovingId;

  whyRemovingList = allItems.where((item) {
    return item["isActive"] == 1 ||
        item["id"] == existingId;
  }).toList();

  if (mounted) {
    setState(() {});
  }
}

void filterPurposeList() {
  final parentCode =
      selectedWhyRemovingCode;

  if (parentCode.isEmpty) {
    purposeList = [];
    return;
  }

  purposeList = allPurposeList.where((item) {
    final purposeParentCode =
        item["parentCode"]
                ?.toString()
                .trim()
                .toUpperCase() ??
            "";

    return purposeParentCode == parentCode;
  }).toList();

  // Fallback: custom purposes without a mapped parent still show,
  // so save is never blocked by an empty purpose list.
  if (purposeList.isEmpty) {
    purposeList = allPurposeList.toList();
  }

  final selectedPurposeStillValid =
      purposeList.any(
    (item) => item["id"] == purposeId,
  );

  if (!selectedPurposeStillValid) {
    purposeId = null;
    purposeController.clear();
  }
}

Future<void> loadPurpose() async {
  final allItems =
      await MasterRepository().getMasters(
    "Purpose",
  );

  final existingId =
      widget.application?.purposeId;

  allPurposeList = allItems.where((item) {
    return item["isActive"] == 1 ||
        item["id"] == existingId;
  }).toList();

  filterPurposeList();

  if (mounted) {
    setState(() {});
  }
}

Future<void> loadApplicationTypes() async {
  final allTypes =
      await ApplicationTypeRepository().getAll();

  final existingType =
      widget.application?.applicationType ?? "";

  applicationTypeList = allTypes.where((item) {
    return item["isActive"] == 1 ||
        item["shortCode"] == existingType;
  }).toList();

  if (mounted) {
    setState(() {});
  }
}

Future<void> loadAdditionalApplicationMasters() async {
  final repository = MasterRepository();

  final agencies =
      await repository.getMasters("Government Agency");

  final urbanRural =
      await repository.getMasters("Urban Rural");

  final structureTypes =
      await repository.getMasters("Structure Type");

  governmentAgencyList = agencies
      .where((item) => item["isActive"] == 1)
      .toList();

  urbanRuralList = urbanRural
      .where((item) => item["isActive"] == 1)
      .toList();

  structureTypeList = structureTypes
      .where((item) => item["isActive"] == 1)
      .toList();

  if (mounted) {
    setState(() {});
  }
}

Future<void> loadSections() async {

  sectionList =
      await SectionRepository().getAll();

  if (mounted) {
    setState(() {});
  }

}
Future<void> loadBeats() async {

  if (section.isEmpty) {

    beatList = [];

    if (mounted) {
      setState(() {});
    }

    return;

  }

  final selectedSection = sectionList.firstWhere(

    (e) => e["sectionName"] == section,

  );

  beatList = await BeatRepository().getBySection(

    selectedSection["id"],

  );

  if (mounted) {

    setState(() {});

  }

}

Future<void> loadForwardedSources() async {

  forwardedSourceList =
      await ForwardedSourceRepository()
          .getSources();

  if (mounted) {

    setState(() {});

  }

}

@override
void dispose() {
  applicationDateController.dispose();
  receivedDateController.dispose();
  applicantLetterNumberController.dispose();
  applicantNameController.dispose();
  applicantAddressController.dispose();
  treeLocationController.dispose();
  mobileController.dispose();
  purposeController.dispose();
  workNameController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {

    final officeNo =
        ApplicationService.generateOfficeNumber(applicationType);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "New Tree Permission Application"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextFormField(
              initialValue: officeNo,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Office Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            ForwardedReferenceWidget(

  applicationSource: applicationSource,

  forwardedDate: forwardedDate,

  references: forwardReferences,

  sourceList: forwardedSourceList,

  onSourceChanged: (value) {

    setState(() {

      applicationSource = value;

    });

  },

  onForwardedDateChanged: (value) {

    forwardedDate = value;

  },

  onAddReference: () {

    setState(() {

      forwardReferences.add(

        ForwardReference(),

      );

    });

  },

  onRemoveReference: (index) {

    setState(() {

      forwardReferences.removeAt(index);

    });

  },

  onSourceSelected: (

    index,

    sourceId,

    sourceName,

  ) {

    forwardReferences[index].sourceId = sourceId;

    forwardReferences[index].sourceName = sourceName;

  },

  onReferenceNumberChanged: (

    index,

    value,

  ) {

    forwardReferences[index].referenceNumber = value;

  },

  onReferenceDateChanged: (

    index,

    value,

  ) {

    forwardReferences[index].referenceDate = value;

  },

),

const SizedBox(height: 15),

            TextFormField(
  controller: applicationDateController,
  readOnly: true,
  onTap: () async {
    await DatePickerUtil.pickDate(
      context,
      applicationDateController,
    );
  },
  decoration: const InputDecoration(
    labelText: "Date of Application",
    border: OutlineInputBorder(),
    suffixIcon: Icon(Icons.calendar_month),
  ),
),

            const SizedBox(height: 15),

TextFormField(
  controller: receivedDateController,
  readOnly: true,
  onTap: () async {
    await DatePickerUtil.pickDate(
      context,
      receivedDateController,
    );
  },
  decoration: const InputDecoration(
    labelText: "Date Received",
    border: OutlineInputBorder(),
    suffixIcon: Icon(Icons.calendar_month),
  ),
),

            const SizedBox(height: 15),

            TextFormField(
              controller: applicantLetterNumberController,
              decoration: const InputDecoration(labelText: 'Applicant letter number (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: applicantNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Applicant Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
  controller: applicantAddressController,
  maxLines: 3,
  textInputAction: TextInputAction.next,
  onChanged: (value) {

    if (treeLocationSame) {

      treeLocationController.text = value;

    }

  },
  decoration: const InputDecoration(
    labelText: "Applicant Address",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 15),

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Location of Tree(s)",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  ),
),

Row(
  children: [

    Expanded(
      child: RadioListTile<bool>(
        dense: true,
        value: true,
        groupValue: treeLocationSame,
        title: const Text("Same"),
        onChanged: (value) {

          setState(() {

            treeLocationSame = true;

            treeLocationController.text =
                applicantAddressController.text;

          });

        },
      ),
    ),

    Expanded(
      child: RadioListTile<bool>(
        dense: true,
        value: false,
        groupValue: treeLocationSame,
        title: const Text("Different"),
        onChanged: (value) {

          setState(() {

            treeLocationSame = false;

          });

        },
      ),
    ),

  ],
),

TextFormField(
  controller: treeLocationController,
  enabled: !treeLocationSame,
  maxLines: 3,
  decoration: const InputDecoration(
    labelText: "Location of Tree(s)",
    border: OutlineInputBorder(),
  ),
),

            const SizedBox(height: 15),

            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Mobile",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
  value: applicationTypeList.any(
          (e) => e["shortCode"] == applicationType)
      ? applicationType
      : null,

  decoration: const InputDecoration(
    labelText: "Application Type",
    border: OutlineInputBorder(),
  ),

  items: applicationTypeList.map((item) {

    return DropdownMenuItem<String>(

      value: item["shortCode"],

      child: Text(
  item["applicationType"]?.toString() ?? "",
),

    );

  }).toList(),

  onChanged: (value) {
  if (value == null) return;

  setState(() {
    applicationType = value;

    final governmentType =
        value == "GL" ||
        value == "STGL" ||
        value == "CGL" ||
        value == "SGL";

    final privateType =
        value == "PL" ||
        value == "SPL";

    if (governmentType) {
      urbanRuralId = null;
    } else if (privateType) {
      governmentAgencyId = null;
    } else {
      governmentAgencyId = null;
      urbanRuralId = null;
      structureTypeId = null;
      workNameController.clear();
    }

    if (value == "RTC") {
      whyRemovingId = null;
      purposeId = null;
      purposeController.clear();
      purposeList = [];
      workNameController.clear();
    } else {
      filterPurposeList();
    }
  });
},

),

if (isGovernmentCategory) ...[
  const SizedBox(height: 15),

  DropdownButtonFormField<int>(
    value: governmentAgencyList.any(
      (item) => item["id"] == governmentAgencyId,
    )
        ? governmentAgencyId
        : null,
    decoration: const InputDecoration(
      labelText: "Government Agency",
      border: OutlineInputBorder(),
    ),
    items: governmentAgencyList.map((item) {
      return DropdownMenuItem<int>(
  value: item["id"] as int,
  child: Text(
    item["value"]?.toString() ?? "",
  ),
);
    }).toList(),
    onChanged: (value) {
      setState(() {
        governmentAgencyId = value;
      });
    },
  ),
],

if (isPrivateCategory) ...[
  const SizedBox(height: 15),

  DropdownButtonFormField<int>(
    value: urbanRuralList.any(
      (item) => item["id"] == urbanRuralId,
    )
        ? urbanRuralId
        : null,
    decoration: const InputDecoration(
      labelText: "Urban / Rural",
      border: OutlineInputBorder(),
    ),
    items: urbanRuralList.map((item) {
      return DropdownMenuItem<int>(
  value: item["id"] as int,
  child: Text(
    item["value"]?.toString() ?? "",
  ),
);
    }).toList(),
    onChanged: (value) {
      setState(() {
        urbanRuralId = value;
      });
    },
  ),
],

if (requiresWhyRemovingAndPurpose) ...[
  const SizedBox(height: 15),

DropdownButtonFormField<int>(
  value: whyRemovingList.any(
    (item) => item["id"] == whyRemovingId,
  )
      ? whyRemovingId
      : null,
  validator: (value) {
    if (value == null) {
      return "Please select Why Removing";
    }

    return null;
  },
  decoration: const InputDecoration(
    labelText: "Why Removing",
    border: OutlineInputBorder(),
  ),
  items: whyRemovingList.map((item) {
    return DropdownMenuItem<int>(
      value: item["id"] as int,
      child: Text(
        item["value"]?.toString() ?? "",
      ),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      whyRemovingId = value;

      // Clear an old Purpose if it does not belong
      // to the newly selected Why Removing value.
      filterPurposeList();

      // Name of Work applies only to Development work.
      if (!isDevelopmentWork) {
        workNameController.clear();
      }
    });
  },
),

const SizedBox(height: 15),

DropdownButtonFormField<int>(
  value: purposeList.any(
    (item) => item["id"] == purposeId,
  )
      ? purposeId
      : null,
  validator: (value) {
    if (value == null) {
      return "Please select Purpose";
    }

    return null;
  },
  decoration: const InputDecoration(
    labelText: "Purpose",
    border: OutlineInputBorder(),
  ),
  items: purposeList.map((item) {
    return DropdownMenuItem<int>(
      value: item["id"] as int,
      child: Text(
        item["value"]?.toString() ?? "",
      ),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      purposeId = value;

      final selected = purposeList.where(
        (item) => item["id"] == value,
      );

      purposeController.text =
          selected.isEmpty
              ? ""
              : selected.first["value"]
                      ?.toString() ??
                  "";
    });
    },
),

],

if (showsAdditionalWorkDetails) ...[
  const SizedBox(height: 15),

  DropdownButtonFormField<int>(
    value: structureTypeList.any(
      (item) => item["id"] == structureTypeId,
    )
        ? structureTypeId
        : null,
    decoration: const InputDecoration(
      labelText: "Structure Type",
      border: OutlineInputBorder(),
    ),
    items: structureTypeList.map((item) {
      return DropdownMenuItem<int>(
  value: item["id"] as int,
  child: Text(
    item["value"]?.toString() ?? "",
  ),
);
    }).toList(),
    onChanged: (value) {
      setState(() {
        structureTypeId = value;
      });
    },
  ),

  if (showsNameOfWork) ...[
    const SizedBox(height: 15),

    TextFormField(
      controller: workNameController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: "Name of Work",
        border: OutlineInputBorder(),
      ),
    ),
  ],
],

            const SizedBox(height: 15),

DropdownButtonFormField<String>(

  value: sectionList.any(
        (e) => e["sectionName"] == section)
    ? section
    : null,

  decoration: const InputDecoration(

    labelText: "Section",

    border: OutlineInputBorder(),

  ),

  items: sectionList.map((item) {

    return DropdownMenuItem<String>(

      value: item["sectionName"],

      child: Text(item["sectionName"]),

    );

  }).toList(),

 onChanged: (value) async {

  setState(() {

    section = value!;

    beat = "";

  });

  await loadBeats();


}

),

const SizedBox(height: 15),

DropdownButtonFormField<String>(

  value: beatList.any(
        (e) => e["beatName"] == beat)
    ? beat
    : null,

  decoration: const InputDecoration(

    labelText: "Beat",

    border: OutlineInputBorder(),

  ),

  items: beatList.map((item) {

    return DropdownMenuItem<String>(

      value: item["beatName"],

      child: Text(

        item["beatName"],

      ),

    );

  }).toList(),

  onChanged: (value) {

    setState(() {

      beat = value!;

    });

  },

),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {

if (requiresWhyRemovingAndPurpose &&
    whyRemovingId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please select Why Removing.",
      ),
    ),
  );
  return;
}

if (requiresWhyRemovingAndPurpose &&
    purposeId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please select Purpose.",
      ),
    ),
  );
  return;
}

if (isGovernmentCategory &&
    governmentAgencyId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please select Government Agency.",
      ),
    ),
  );
  return;
}

if (isPrivateCategory &&
    urbanRuralId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please select Urban / Rural.",
      ),
    ),
  );
  return;
}

if (showsAdditionalWorkDetails &&
    structureTypeId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please select Structure Type.",
      ),
    ),
  );
  return;
}

if (showsNameOfWork &&
    workNameController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please enter Name of Work.",
      ),
    ),
  );
  return;
}

                  final officeNumber = isEdit

    ? widget.application!.officeNumber

    : ApplicationService.generateOfficeNumber(
        applicationType,
      );

// SAVE APPLICATION
try {

final selectedApplicationType = applicationTypeList.firstWhere(
  (e) => e["shortCode"] == applicationType,
);

final permission =
    await ApplicationTypePermissionMappingRepository()
        .getPermissionForApplicationType(
  selectedApplicationType["id"],
);

   ApplicationModel application = ApplicationModel(

  id: isEdit

      ? widget.application!.id

      : null,
  officeNumber: officeNumber,

  applicationType: applicationType,

  verifiedApplicationType: applicationType,

  permissionTypeId: permission?["id"] as int?,

permissionType:
    permission?["permissionType"]?.toString() ?? "",

  applicationDate: formatDate(applicationDateController.text),

  receivedDate: formatDate(receivedDateController.text),

  applicantLetterNumber: applicantLetterNumberController.text.trim(),
  applicantName: applicantNameController.text,

  applicantAddress: applicantAddressController.text,

  treeLocationSame: treeLocationSame,

treeLocationAddress: treeLocationSame
    ? applicantAddressController.text
    : treeLocationController.text,

  mobile: mobileController.text,

  applicationSource: applicationSource,

forwardedDate: forwardedDate,

  forwardingReferences:
      forwardReferences.map((ref) {
    return ApplicationReferenceModel(
      sourceId: ref.sourceId ?? 0,
      forwardedBy: ref.sourceName,
      referenceNumber: ref.referenceNumber,
      referenceDate: ref.referenceDate,
    );
  }).toList(),

  createdBy: SessionService.instance.userId,

sectionId: sectionList
        .where((e) => e["sectionName"] == section)
        .isEmpty
    ? null
    : sectionList.firstWhere(
        (e) => e["sectionName"] == section,
      )["id"],

beatId: beatList
        .where((e) => e["beatName"] == beat)
        .isEmpty
    ? null
    : beatList.firstWhere(
        (e) => e["beatName"] == beat,
      )["id"],
assignedBFOId: null,

assignedDRFOId: null,
section: section,

beat: beat,

  assignedBFO: "",

  assignedDRFO: "",

  purposeId:
      requiresWhyRemovingAndPurpose
          ? purposeId
          : null,

  purpose:
      requiresWhyRemovingAndPurpose
          ? purposeController.text.trim()
          : "",

  whyRemovingId:
      requiresWhyRemovingAndPurpose
          ? whyRemovingId
          : null,

  governmentAgencyId:
    isGovernmentCategory
        ? governmentAgencyId
        : null,

urbanRuralId:
    isPrivateCategory
        ? urbanRuralId
        : null,

structureTypeId:
    showsAdditionalWorkDetails
        ? structureTypeId
        : null,

workName:
    showsNameOfWork
        ? workNameController.text.trim()
        : "",

  gpsCoordinates: "",

  bfoVerificationDate: "",

  inspectionStarted: false,

inspectionDecision: "",

deferredReasonIds: [],

overallRemarks: "",

  // DRFO
  drfoInspectionDate: "",

  drfoOverallRemarks: "",
  // RFO
rfoInspectionStarted: false,

rfoInspectionDate: "",

rfoOverallRemarks: "",

// RETURN TO DRFO

returnReason: "",

returnRemarks: "",

returnedBy: "",

returnedDate: "",


  trees: [],

status: "Draft",

inspectionMode: "",

createdDate: isEdit

    ? widget.application!.createdDate

    : DateTime.now(),
);

  if (isEdit) {

  await ApplicationRepository()
      .updateApplication(application);

  await ApplicationRepository()
      .replaceForwardingReferences(
        application.id!,
        application.forwardingReferences,
      );

    await HistoryRepository().addHistory(

      officeNumber: application.officeNumber,

      action: "Application Updated",

      remarks: "Draft updated by Case Worker",

      actionBy: SessionService.instance.name,

    );

  } else {

    await ApplicationRepository()
        .insertApplication(application);

    await HistoryRepository().addHistory(

      officeNumber: application.officeNumber,

      action: "Application Saved",

      remarks: "Saved as Draft",

      actionBy: SessionService.instance.name,

    );

  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

      content: Text(

        isEdit

            ? "Application Updated"

            : "Application Saved",

      ),

    ),

  );

  Navigator.pop(context, true);

} catch (e) {

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

      content: Text("ERROR : $e"),

    ),

  );

}

                },
                child: Text(
  isEdit
      ? "UPDATE APPLICATION"
      : "SAVE APPLICATION",
  style: const TextStyle(fontSize: 18),
),
              ),
            ),
          ],
        ),
      ),
    );
  }
}