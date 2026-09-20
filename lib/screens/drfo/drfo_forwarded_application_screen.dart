import '../../repositories/revenue_reply_repository.dart';
import '../../models/revenue_reply_model.dart';
import '../../constants/workflow_status.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/application_model.dart';
import '../../services/drfo_document_service.dart';

class DRFOForwardedApplicationScreen extends StatefulWidget {
  final ApplicationModel application;
  final bool rfoApprovedOnly;
  final String screenTitle;

  const DRFOForwardedApplicationScreen({
  super.key,
  required this.application,
  this.rfoApprovedOnly = false,
  this.screenTitle = "Forwarded Application",
});

  @override
  State<DRFOForwardedApplicationScreen> createState() =>
      _DRFOForwardedApplicationScreenState();
}

class _DRFOForwardedApplicationScreenState
    extends State<DRFOForwardedApplicationScreen> {

  final DrfoDocumentService documentService =
      DrfoDocumentService();

  List<File> generatedDocuments = [];

  bool loadingDocuments = true;
  String? documentError;
  RevenueReply? revenueReply;
  bool printing = false;

  @override
  void initState() {
    super.initState();

    _loadGeneratedDocuments();
  }

  Future<void> _loadGeneratedDocuments() async {
    try {
      final allFiles =
    await documentService.getGeneratedDocuments(
  widget.application.officeNumber,
);

if (widget.rfoApprovedOnly && widget.application.status == WorkflowStatus.pendingRevenueOpinion) {
  final current = await RevenueReplyRepository().current(widget.application.id!);
  final requests = allFiles.where((f) => f.path.toUpperCase().contains('RFO_REVENUE_OPINION_REQUEST')).toList();
  if (current != null) { revenueReply = current; }
  else if (requests.isNotEmpty) { revenueReply = await RevenueReplyRepository().ensureLegacyRequest(widget.application, requests.first.path); }
}
final files = widget.rfoApprovedOnly
    ? allFiles.where((file) {
        final fileName = file.path
            .split(Platform.pathSeparator)
            .last
            .toUpperCase();

        if (widget.application.status == WorkflowStatus.pendingRevenueOpinion && revenueReply != null) return file.path == revenueReply!.requestLetterPath;
        return fileName.contains("_RFO_");
      }).toList()
    : allFiles;

      if (!mounted) return;

      setState(() {
        generatedDocuments = files;
        loadingDocuments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        documentError = e.toString();
        generatedDocuments = [];
        loadingDocuments = false;
      });
    }
  }

  String _documentName(File file) {
    final fileName = file.path
        .split(Platform.pathSeparator)
        .last
        .toUpperCase();

if (fileName.contains('RFO_GL_VALUATION')) return 'RFO GL Valuation Letter';
if (fileName.contains('RFO_GL_DOCUMENT_REQUEST')) return 'RFO Government Valuation Document Request';
if (fileName.contains('RFO_GL_TAGGU_BELE_PATTI')) return 'RFO Taggu Bele Patti';
if (fileName.contains('RFO_GL_DO')) return 'RFO DO Letter';
if (fileName.contains('RFO_PRIVATE_LAND_APPROVED_APPLICANT')) return 'RFO PL Approval Applicant Letter';
if (fileName.contains('RFO_PRIVATE_LAND_APPROVED')) return 'RFO Private Land Approval Letter';
if (fileName.contains('RFO_PRIVATE_LAND_REJECTED')) return 'RFO Private Land Rejection Letter';
if (fileName.contains(
    'RFO_REVENUE_OPINION_REQUEST')) {
  return 'Revenue Opinion Request Letter';
}

if (fileName.contains(
    'RFO_NOT_RECOMMENDED_NON_RTC')) {
  return 'Non-RTC Not Recommended RFO Letter';
}

if (fileName.contains(
    'RFO_DEFERRED_NON_RTC')) {
  return 'Non-RTC Deferred RFO Letter';
}

if (fileName.contains('RFO_DEFERRED_RTC')) {
  return 'RTC Deferred RFO Letter';
}

if (fileName.contains('RFO_PRIVATE_LAND_BRANCH_PERMISSION')) {
  return 'RFO Private Land Branch Permission Letter';
}

if (fileName.contains('RFO_APPROVED_RTC')) {
  return 'RTC Approved RFO Letter';
}

    if (fileName.contains('DRFO_DEFERRED')) {
      return 'DRFO Deferred Letter';
    }

    if (fileName.contains('DRFO_RECOMMENDED')) {
      return 'DRFO Recommended Letter';
    }

if (fileName.contains('UPDATED_MAHAZAR')) {
  return 'Updated Mahazar';
}

    if (fileName.contains('MAHAZAR')) {
      return 'Mahazar';
    }

    if (fileName.contains('TREE_ENUMERATION')) {
      return 'Tree Enumeration List';
    }

    return file.path
        .split(Platform.pathSeparator)
        .last;
  }

  Future<void> _openDocument(File file) async {
    try {
      await documentService.refreshOfficerAddresses(file);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _printDocument(File file) async {
  if (printing) return;
  setState(() => printing = true);
  try {
    final printed = await documentService.openPdf(file);
    if (printed && revenueReply?.stage == 'printing' && file.path == revenueReply!.requestLetterPath) {
      await RevenueReplyRepository().markPrinted(revenueReply!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Pending Revenue Opinion.')));
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  } finally { if (mounted) setState(() => printing = false); }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
  widget.screenTitle,
),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          // =====================================================
          // APPLICATION DETAILS
          // =====================================================

          Card(
            elevation: 2,

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Application Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _detail(
                    'Office Number',
                    widget.application.officeNumber,
                  ),

                  _detail(
                    'Applicant Name',
                    widget.application.applicantName,
                  ),

                  _detail(
                    'Application Type',
                    widget.application.applicationType,
                  ),

                  _detail(
                    'Address',
                    widget.application.applicantAddress,
                  ),

                  _detail(
                    'Section',
                    widget.application.section,
                  ),

                  _detail(
                    'Beat',
                    widget.application.beat,
                  ),

                  _detail(
                    'Status',
                    widget.application.status,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // =====================================================
          // GENERATED DOCUMENTS
          // =====================================================

          Card(
            elevation: 2,

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Generated Documents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (loadingDocuments)
                    const Center(
                      child:
                          CircularProgressIndicator(),
                    )

                  else if (documentError != null)
                    Padding(padding: const EdgeInsets.all(16), child: Text(documentError!))
                  else if (generatedDocuments.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 20,
                      ),

                      child: Center(
                        child: Text(
                          'No generated documents found.',
                        ),
                      ),
                    )

                  else

                    ...generatedDocuments.map(
                      (file) {

                        return Card(

                          margin:
                              const EdgeInsets.only(
                            bottom: 8,
                          ),

                          child: ListTile(

                            leading:
                                const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 32,
                            ),

                            title: Text(
                              _documentName(file),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    OutlinedButton.icon(
      icon: const Icon(
        Icons.visibility,
      ),
      label: const Text(
        'VIEW',
      ),
      onPressed: () {
        _openDocument(file);
      },
    ),
    const SizedBox(width: 8),
    ElevatedButton.icon(
      icon: const Icon(
        Icons.print,
      ),
      label: const Text(
        'PRINT',
      ),
      onPressed: printing ? null : () {
        _printDocument(file);
      },
    ),
  ],
),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _detail(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 9),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 150,

            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
            ),
          ),
        ],
      ),
    );
  }
}