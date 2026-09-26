import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../constants/workflow_status.dart';
import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/application_type_repository.dart';
import '../../repositories/master_repository.dart';
import '../../services/drfo_document_service.dart';
import '../../services/session_service.dart';
import '../../widgets/tpms_drawer.dart';
import '../../widgets/sync_bar.dart';
import 'wizard/bfo_wizard_controller.dart';
import 'wizard/inspection_summary_step.dart';

class BFODashboardScreen extends StatefulWidget {
  const BFODashboardScreen({
    super.key,
  });

  @override
  State<BFODashboardScreen> createState() =>
      _BFODashboardScreenState();
}

class _BFODashboardScreenState
    extends State<BFODashboardScreen> {
  final ApplicationRepository repository =
      ApplicationRepository();

  final ApplicationTypeRepository
      applicationTypeRepository =
      ApplicationTypeRepository();

  final MasterRepository masterRepository =
      MasterRepository();

  final DrfoDocumentService documentService =
      DrfoDocumentService();

  List<ApplicationModel> pendingApplications = [];

  List<ApplicationModel> completedApplications = [];

  List<ApplicationModel> returnedByDRFOApplications = [];

  List<ApplicationModel> returnedByRFOApplications = [];

  final Map<String, String> applicationTypeNames = {};

  final Map<int, String> masterNames = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    final userId = SessionService.instance.userId!;

    final allApplications =
        await repository.getApplications();

    final assignedApplications =
        allApplications.where((application) {
      return application.assignedBFOId == userId;
    }).toList();

    final completed =
        await repository.getCompletedInspectionsForBFO(
      userId,
    );

    final applicationTypes =
        await applicationTypeRepository.getAll();

    final governmentAgencies =
        await masterRepository.getMasters(
      "Government Agency",
    );

    final urbanRuralItems =
        await masterRepository.getMasters(
      "Urban Rural",
    );

    applicationTypeNames.clear();

    for (final item in applicationTypes) {
      final shortCode =
          item["shortCode"]?.toString().trim() ?? "";

      final fullName =
          item["applicationType"]?.toString().trim() ?? "";

      if (shortCode.isNotEmpty) {
        applicationTypeNames[
            shortCode.toUpperCase()] = fullName;
      }

      if (fullName.isNotEmpty) {
        applicationTypeNames[
            fullName.toUpperCase()] = fullName;
      }
    }

    masterNames.clear();

    for (final item in [
      ...governmentAgencies,
      ...urbanRuralItems,
    ]) {
      final id = item["id"] as int?;

      final value =
          item["value"]?.toString().trim() ?? "";

      if (id != null) {
        masterNames[id] = value;
      }
    }

    pendingApplications =
        assignedApplications.where((application) {
      return application.status ==
          WorkflowStatus.pendingBFOInspection;
    }).toList();

    returnedByDRFOApplications =
        assignedApplications.where((application) {
      return application.status ==
          WorkflowStatus.returnedToBFO;
    }).toList();

    returnedByRFOApplications =
        assignedApplications.where((application) {
      return application.status ==
          WorkflowStatus.returnedByRFO;
    }).toList();

    completedApplications = completed;

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await loadApplications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshed'),
        ),
      );
    }
  }

  String applicationNumber(
    ApplicationModel application,
  ) {
    final parts = application.officeNumber.split("/");

    if (parts.isEmpty) {
      return application.officeNumber;
    }

    final lastPart = parts.last.trim();

    final number = int.tryParse(lastPart);

    return number?.toString() ?? lastPart;
  }

 String applicationTypeDisplay(
  ApplicationModel application,
) {
  final savedType =
      application.applicationType.trim();

  final masterName = applicationTypeNames[
      savedType.toUpperCase()];

  if (masterName != null &&
      masterName.trim().isNotEmpty) {
    return masterName;
  }

  if (application.verifiedApplicationType
      .trim()
      .isNotEmpty) {
    return application.verifiedApplicationType;
  }

  return savedType;
}

  String agencyOrUrbanRural(
    ApplicationModel application,
  ) {
    if (application.governmentAgencyId != null) {
      return masterNames[
              application.governmentAgencyId!] ??
          "-";
    }

    if (application.urbanRuralId != null) {
      return masterNames[
              application.urbanRuralId!] ??
          "-";
    }

    return "-";
  }

  Future<void> openInspection(
    ApplicationModel application, {
    required bool readOnly,
  }) async {
    if (readOnly) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InspectionSummaryStep(
            application: application,
            showNavigationButtons: false,
            onBack: () {
              Navigator.pop(context);
            },
            onNext: () {},
          ),
        ),
      );

      return;
    }

    if (!application.inspectionStarted) {
      application.inspectionStarted = true;

      await repository.updateApplication(
        application,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BFOWizardController(
          application: application,
        ),
      ),
    );

    await loadApplications();
  }

  Future<void> openMahazar(
    ApplicationModel application,
  ) async {
    final files =
        await documentService.getGeneratedDocuments(
      application.officeNumber,
    );

    final mahazarFiles = files.where((file) {
      final fileName = file.path
          .split(Platform.pathSeparator)
          .last
          .toUpperCase();

      return fileName.contains("MAHAZAR");
    }).toList();

    if (mahazarFiles.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No generated Mahazar is available.",
          ),
        ),
      );

      return;
    }

    await OpenFilex.open(
      mahazarFiles.last.path,
    );
  }

  Widget tabTitle(
    String title,
    int count,
  ) {
    return Tab(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: title,
            ),
            TextSpan(
              text: " ($count)",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget applicationList(
    List<ApplicationModel> applications, {
    required bool readOnly,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: applications.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1),
      itemBuilder: (context, index) {
        final application = applications[index];

        final rowText =
            "${applicationNumber(application)} / "
            "${applicationTypeDisplay(application)} / "
            "${agencyOrUrbanRural(application)} / "
            "${application.applicantName}";

        return Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            title: Text(
              rowText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: readOnly
                ? IconButton(
                    tooltip: "View Mahazar",
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      openMahazar(application);
                    },
                  )
                : const Icon(
                    Icons.chevron_right,
                  ),
            onTap: () {
              openInspection(
                application,
                readOnly: readOnly,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        drawer: const TPMSDrawer(),
        appBar: AppBar(
          centerTitle: true,
          title: const Text("BFO Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refresh,
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: const SyncBar(),
      );
    }

    final tabs = <_BFODashboardTab>[];

    if (pendingApplications.isNotEmpty) {
      tabs.add(
        _BFODashboardTab(
          title: "Pending Inspection",
          applications: pendingApplications,
          readOnly: false,
        ),
      );
    }

    if (completedApplications.isNotEmpty) {
      tabs.add(
        _BFODashboardTab(
          title: "Completed Inspection",
          applications: completedApplications,
          readOnly: true,
        ),
      );
    }

    if (returnedByDRFOApplications.isNotEmpty) {
      tabs.add(
        _BFODashboardTab(
          title: "Returned for Re-inspection by DRFO",
          applications: returnedByDRFOApplications,
          readOnly: false,
        ),
      );
    }

    if (returnedByRFOApplications.isNotEmpty) {
      tabs.add(
        _BFODashboardTab(
          title: "Returned for Re-inspection by RFO",
          applications: returnedByRFOApplications,
          readOnly: false,
        ),
      );
    }

    if (tabs.isEmpty) {
      return Scaffold(
        drawer: const TPMSDrawer(),
        appBar: AppBar(
          centerTitle: true,
          title: const Text("BFO Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refresh,
            ),
          ],
        ),
        body: const Center(
          child: Text(
            "No Applications Assigned",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottomNavigationBar: const SyncBar(),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        drawer: const TPMSDrawer(),
        appBar: AppBar(
          centerTitle: true,
          title: const Text("BFO Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refresh,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabs.map((tab) {
              return tabTitle(
                tab.title,
                tab.applications.length,
              );
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: tabs.map((tab) {
            return applicationList(
              tab.applications,
              readOnly: tab.readOnly,
            );
          }).toList(),
        ),
        bottomNavigationBar: const SyncBar(),
      ),
    );
  }
}

class _BFODashboardTab {
  final String title;

  final List<ApplicationModel> applications;

  final bool readOnly;

  const _BFODashboardTab({
    required this.title,
    required this.applications,
    required this.readOnly,
  });
}