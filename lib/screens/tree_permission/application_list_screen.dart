import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../services/session_service.dart';
import '../../constants/workflow_status.dart';

import 'application_details_screen.dart';

class ApplicationListScreen extends StatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  State<ApplicationListScreen> createState() =>
      _ApplicationListScreenState();
}

class _ApplicationListScreenState
    extends State<ApplicationListScreen> {

  final TextEditingController searchController =
      TextEditingController();

  final ApplicationRepository repository =
      ApplicationRepository();

  List<ApplicationModel> applications = [];

  List<ApplicationModel> filteredApplications = [];

  String searchText = "";

  String searchType = "Office";

  @override
  void initState() {

    super.initState();

    loadApplications();

  }

  Future<void> loadApplications() async {

    final session =
        SessionService.instance;

    switch (session.role) {

      case "Case Worker":

        applications =
            await repository
                .getApplicationsForCaseWorker(

          session.userId!,

        );

        break;

      case "BFO":

        applications =
            await repository
                .getApplicationsForBFO(

          session.userId!,

        );

        break;

      case "DRFO":

        applications =
            await repository
                .getApplicationsForDRFO(

          session.sectionId!,

        );

        break;

      default:

  applications =
      await repository
          .getApplicationsForRFO();

  //------------------------------------------------
  // RFO should see only pending approval cases
  //------------------------------------------------

  applications = applications.where((e) {

  return e.status ==
      WorkflowStatus.pendingRFOApproval;

}).toList();

  break;

    }

    filterList();

  }

  void filterList() {

    if (searchText.trim().isEmpty) {

      filteredApplications = applications;

    } else {

      filteredApplications =
          applications.where((app) {

        switch (searchType) {

          case "Office":

            return app.officeNumber
                .toLowerCase()
                .contains(
                  searchText.toLowerCase(),
                );

          case "Applicant":

            return app.applicantName
                .toLowerCase()
                .contains(
                  searchText.toLowerCase(),
                );

          case "Section":

            return app.section
                .toLowerCase()
                .contains(
                  searchText.toLowerCase(),
                );

          case "Beat":

            return app.beat
                .toLowerCase()
                .contains(
                  searchText.toLowerCase(),
                );

          default:

            return true;

        }

      }).toList();

    }

    if (mounted) {

      setState(() {});

    }

  }
    Color statusColor(String status) {

    switch (status) {

      case "Pending BFO":
        return Colors.orange;

      case "Pending DRFO":
        return Colors.deepPurple;

      case "Pending RFO":
        return Colors.blue;

      case "Returned to DRFO":
        return Colors.red;

     case "Completed":
case "Approved":
  return Colors.green;

      case "Rejected":
        return Colors.black;

      default:
        return Colors.grey;

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        centerTitle: true,

        title: const Text(

          "Application List",

        ),

      ),

      body: Column(

        children: [

          Padding(

            padding: const EdgeInsets.all(10),

            child: TextField(

              controller: searchController,

              decoration: InputDecoration(

                hintText: "Search Application",

                prefixIcon:
                    const Icon(Icons.search),

                border: OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(10),

                ),

              ),

              onChanged: (value) {

                searchText = value;

                filterList();

              },

            ),

          ),

          Padding(

            padding: const EdgeInsets.symmetric(

              horizontal: 10,

            ),

            child: Row(

              children: [

                const Text(

                  "Search By : ",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(width: 10),

                DropdownButton<String>(

                  value: searchType,

                  items: const [

                    DropdownMenuItem(

                      value: "Office",

                      child: Text("Office"),

                    ),

                    DropdownMenuItem(

                      value: "Applicant",

                      child: Text("Applicant"),

                    ),

                    DropdownMenuItem(

                      value: "Section",

                      child: Text("Section"),

                    ),

                    DropdownMenuItem(

                      value: "Beat",

                      child: Text("Beat"),

                    ),

                  ],

                  onChanged: (value) {

                    searchType = value!;

                    filterList();

                  },

                ),

              ],

            ),

          ),

          const SizedBox(height: 10),

          Expanded(

            child: filteredApplications.isEmpty

                ? const Center(

                    child: Text(

                      "No Applications Found",

                      style: TextStyle(

                        fontSize: 18,

                      ),

                    ),

                  )

                : ListView.builder(

                    itemCount:
                        filteredApplications.length,

                    itemBuilder:
                        (context, index) {

                      final app =
                          filteredApplications[index];
                                                return Card(

                        margin: const EdgeInsets.symmetric(

                          horizontal: 10,

                          vertical: 5,

                        ),

                        elevation: 3,

                        child: ListTile(

                          leading: CircleAvatar(

                            child: Text(

                              "${index + 1}",

                            ),

                          ),

                          title: Text(

                            app.officeNumber,

                            style: const TextStyle(

                              fontWeight:
                                  FontWeight.bold,

                            ),

                          ),

                          subtitle: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(

                                "Applicant : ${app.applicantName}",

                              ),

                              Text(

                                "Section : ${app.section}",

                              ),

                              Text(

                                "Beat : ${app.beat}",

                              ),

                              Text(

                                "Type : ${app.applicationType}",

                              ),

                            ],

                          ),

                          trailing: Container(

                            padding:
                                const EdgeInsets.all(8),

                            decoration: BoxDecoration(

                              color: statusColor(

                                app.status,

                              ).withValues(

                                alpha: 0.15,

                              ),

                              borderRadius:
                                  BorderRadius.circular(

                                8,

                              ),

                            ),

                            child: Text(

                              app.status,

                              style: TextStyle(

                                color: statusColor(

                                  app.status,

                                ),

                                fontWeight:
                                    FontWeight.bold,

                              ),

                            ),

                          ),

                          onTap: () async {

                            await Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>

                                    ApplicationDetailsScreen(

                                  application: app,

                                ),

                              ),

                            );

                            await loadApplications();

                          },

                        ),

                      );

                    },

                  ),

          ),

        ],

      ),

    );

  }

}