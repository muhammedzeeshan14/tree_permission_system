import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../services/session_service.dart';
import '../drfo/drfo_forwarded_application_screen.dart';

class ApprovedRfoLettersScreen
    extends StatefulWidget {
  const ApprovedRfoLettersScreen({
    super.key,
  });

  @override
  State<ApprovedRfoLettersScreen> createState() =>
      _ApprovedRfoLettersScreenState();
}

class _ApprovedRfoLettersScreenState
    extends State<ApprovedRfoLettersScreen> {
  final ApplicationRepository repository =
      ApplicationRepository();

  List<ApplicationModel> applications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final userId =
        SessionService.instance.userId;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        applications = [];
        loading = false;
      });
      return;
    }

    final result = await repository
        .getRfoApprovedApplicationsForCaseWorker(
      userId,
    );

    if (!mounted) return;

    setState(() {
      applications = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Approved RFO - Print Letters",
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : applications.isEmpty
              ? const Center(
                  child: Text(
                    "No RFO-approved applications available.",
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        applications.length,
                    separatorBuilder:
                        (context, index) {
                      return const SizedBox(
                        height: 8,
                      );
                    },
                    itemBuilder:
                        (context, index) {
                      final application =
                          applications[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.approval,
                            color: Colors.green,
                          ),
                          title: Text(
                            application.officeNumber,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "${application.applicationType}"
                            " / "
                            "${application.applicantName}",
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DRFOForwardedApplicationScreen(
  application: application,
  rfoApprovedOnly: true,
  screenTitle:
      "Approved RFO - Print Letters",
),
                              ),
                            );

                            await _loadApplications();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}