import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../services/session_service.dart';
import '../../widgets/sync_bar.dart';

class CompletedApplicationsScreen extends StatefulWidget {
  const CompletedApplicationsScreen({
    super.key,
  });

  @override
  State<CompletedApplicationsScreen> createState() =>
      _CompletedApplicationsScreenState();
}

class _CompletedApplicationsScreenState
    extends State<CompletedApplicationsScreen> {
  List<ApplicationModel> applications = [];
  late Future<int> completedCountFuture;

  @override
  void initState() {
    super.initState();
    _loadApplications();
    completedCountFuture = _getCompletedCount();
  }

  Future<void> _loadApplications() async {
    final userId = SessionService.instance.userId;
    if (userId == null) {
      setState(() {
        applications = [];
      });
      return;
    }

    final all = await ApplicationRepository().getApplications();
    setState(() {
      applications = all.where((app) =>
          app.status == 'Completed' &&
          app.createdBy == userId).toList();
    });
  }

  Future<int> _getCompletedCount() async {
    final all = await ApplicationRepository().getApplications();
    return all.where((app) =>
        app.status == 'Completed' &&
        app.createdBy ==
            SessionService.instance.userId)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _loadApplications();
                completedCountFuture = _getCompletedCount();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<int>(
              future: completedCountFuture,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Completed: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (applications.isEmpty)
                  const Center(
                    child: Text(
                      'No completed applications found.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: applications.length,
                      itemBuilder: (context, index) {
                        final app = applications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(
                              'Application ${app.officeNumber} - ${app.applicationType}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Office: ${app.applicantName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.remove),
                            onTap: () {
                              // TODO: Show application details and re-print option
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Re-print functionality coming soon'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SyncBar(),
    );
  }
}