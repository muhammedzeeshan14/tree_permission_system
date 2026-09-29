import 'package:tree_permission_system/widgets/adaptive_layout.dart';
import '../../widgets/application_refresh_button.dart';
import '../../widgets/workflow_action.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/application_completion_repository.dart';
import '../../services/session_service.dart';
import '../../repositories/revenue_reply_repository.dart';
import '../../repositories/government_approval_repository.dart';
import '../../models/revenue_reply_model.dart';
import '../../constants/workflow_status.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/application_model.dart';
import '../../services/drfo_document_service.dart';
import '../../services/inspection_attachment_pdf_service.dart';
import 'package:printing/printing.dart';

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
  late ApplicationModel _application;


  final DrfoDocumentService documentService =
      DrfoDocumentService();

  List<File> generatedDocuments = [];

  bool loadingDocuments = true;
  String? documentError;
  RevenueReply? revenueReply;
  bool printing = false;
  int photoCount = 0;
  int uploadCount = 0;
  bool buildingAttachments = false;

  @override
  void initState() {
    super.initState();
    _application = widget.application;

    _loadGeneratedDocuments();
  }

  String _baseName(String path) =>
      path.split(RegExp(r'[/\\]')).last;

  Future<void> _refreshApplicationDocuments() async {
    final latest = await ApplicationRepository().getById(_application.id!);
    if (!mounted) return;
    if (latest == null) throw StateError('Application no longer available.');
    _application = latest;
    revenueReply = null;
    await _loadGeneratedDocuments();
  }

  Future<void> _loadGeneratedDocuments() async {
    try {
      final allFiles =
    await documentService.getGeneratedDocuments(
  _application.officeNumber,
);

if (widget.rfoApprovedOnly && _application.status == WorkflowStatus.pendingRevenueOpinion) {
  final current = await RevenueReplyRepository().current(_application.id!);
  final requests = allFiles.where((f) => f.path.toUpperCase().contains('RFO_REVENUE_OPINION_REQUEST')).toList();
  if (current != null) { revenueReply = current; }
  else if (requests.isNotEmpty) { revenueReply = await RevenueReplyRepository().ensureLegacyRequest(_application, requests.first.path); }
}
final government = widget.rfoApprovedOnly
    ? await GovernmentApprovalRepository().get(_application.id!) : null;
if (widget.rfoApprovedOnly && _application.status == WorkflowStatus.approved) {
  revenueReply = await RevenueReplyRepository().current(_application.id!);
}
final files = widget.rfoApprovedOnly
    ? allFiles.where((file) {
        final fileName = file.path
            .split(Platform.pathSeparator)
            .last
            .toUpperCase();

        if (_application.status == WorkflowStatus.pendingRevenueOpinion && revenueReply != null) {
          final pendingLetter = revenueReply!.finalLetterPath.contains('APPLY_ONLINE')
              ? revenueReply!.finalLetterPath : revenueReply!.requestLetterPath;
          return _baseName(file.path).toUpperCase() == _baseName(pendingLetter).toUpperCase();
        }
        if (_application.status == WorkflowStatus.pendingGovernmentLandApprovals &&
            government != null) {
          return _baseName(file.path).toUpperCase() ==
              _baseName(government.requestLetterPath).toUpperCase();
        }
        if (_application.status == WorkflowStatus.approved) {
          if (revenueReply != null &&
              {'pending', 'printing'}.contains(revenueReply!.stage)) {
            final path = revenueReply!.finalLetterPath.toUpperCase().contains('APPLY_ONLINE')
                ? revenueReply!.finalLetterPath : revenueReply!.requestLetterPath;
            return fileName == _baseName(path).toUpperCase();
          }
          if (government != null && government.stage == 'pending') {
            return fileName == _baseName(government.requestLetterPath).toUpperCase();
          }
          if (revenueReply != null && revenueReply!.finalLetterPath.isNotEmpty) {
            return fileName == _baseName(revenueReply!.finalLetterPath).toUpperCase();
          }
          if (government != null && government.finalPaths.isNotEmpty) {
            return government.finalPaths.any((path) =>
                _baseName(path).toUpperCase() == fileName);
          }
          if (fileName.contains('REVENUE_OPINION_REQUEST') ||
              fileName.contains('DOCUMENT_REQUEST') ||
              fileName.contains('APPLY_ONLINE')) return false;
        }
        return fileName.contains("_RFO_");
      }).toList()
    : allFiles;

      if (!mounted) return;

      setState(() {
        generatedDocuments = files;
        loadingDocuments = false;
      });

      final photos =
          await InspectionAttachmentPdfService.photoCount(
        _application.id!,
        officeNumber: _application.officeNumber,
      );
      final uploads =
          await InspectionAttachmentPdfService.documentCount(
        _application.id!,
        officeNumber: _application.officeNumber,
      );
      if (!mounted) return;
      setState(() {
        photoCount = photos;
        uploadCount = uploads;
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

if (fileName.contains('RFO_MCC_VALUATION')) return 'RFO MCC Valuation Letter';
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

  Future<void> _recordFinalDocument(File file, String action) async {
    if (!widget.rfoApprovedOnly ||
        SessionService.instance.role != 'Case Worker' ||
        _application.status != WorkflowStatus.approved) return;
    final complete = await ApplicationCompletionRepository().recordSuccessfulAction(
      applicationId: _application.id!, path: file.path,
      approvalDate: _application.rfoApprovalDate, action: action,
    );
    if (!mounted) return;
    if (complete) {
      final latest = await ApplicationRepository().getById(_application.id!);
      if (!mounted) return;
      if (latest != null) _application = latest;
      final message = _application.status == WorkflowStatus.completed
          ? 'Application completed. Available in Completed Applications.'
          : 'Request handled. Moved to ${_application.status}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action saved. View or print the remaining final document to complete this application.')));
    }
  }

  Future<void> _openDocument(File file) async {
    if (printing) return;
    setState(() => printing = true);
    try {
      await documentService.refreshOfficerAddresses(file);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw StateError('Unable to open document: ${result.message}');
      }
      await _recordFinalDocument(file, 'View');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }

  Future<void> _printDocument(File file) async {
    if (printing) return;
    setState(() => printing = true);
    try {
      final printed = await documentService.openPdf(file);
      if (printed) await _recordFinalDocument(file, 'Print');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }

  Future<void> _openAttachmentPdf(bool photos) async {
    if (buildingAttachments) return;
    setState(() => buildingAttachments = true);
    try {
      final file = photos
          ? await InspectionAttachmentPdfService.buildPhotoPdf(
              applicationId: _application.id!,
              officeNumber: _application.officeNumber,
            )
          : await InspectionAttachmentPdfService.buildDocumentsPdf(
              applicationId: _application.id!,
              officeNumber: _application.officeNumber,
            );
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => buildingAttachments = false);
    }
  }

  Future<void> _printAttachmentPdf(bool photos) async {
    if (buildingAttachments) return;
    setState(() => buildingAttachments = true);
    try {
      final file = photos
          ? await InspectionAttachmentPdfService.buildPhotoPdf(
              applicationId: _application.id!,
              officeNumber: _application.officeNumber,
            )
          : await InspectionAttachmentPdfService.buildDocumentsPdf(
              applicationId: _application.id!,
              officeNumber: _application.officeNumber,
            );
      await Printing.layoutPdf(
        onLayout: (_) async => file.readAsBytes(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => buildingAttachments = false);
    }
  }

  Widget _attachmentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required bool photos,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: AdaptiveDocumentTile(
        leading: Icon(icon, color: Colors.red, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: count <= 0
            ? const Text('None')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('VIEW'),
                    onPressed: workflowAction(context, buildingAttachments
                        ? null
                        : () => _openAttachmentPdf(photos)),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('PRINT'),
                    onPressed: workflowAction(context, buildingAttachments
                        ? null
                        : () => _printAttachmentPdf(photos)),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        actions: [ApplicationRefreshButton(onRefresh: _refreshApplicationDocuments)],
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
                    _application.officeNumber,
                  ),

                  _detail(
                    'Applicant Name',
                    _application.applicantName,
                  ),

                  _detail(
                    'Application Type',
                    _application.applicationType,
                  ),

                  _detail(
                    'Address',
                    _application.applicantAddress,
                  ),

                  _detail(
                    'Section',
                    _application.section,
                  ),

                  _detail(
                    'Beat',
                    _application.beat,
                  ),

                  _detail(
                    'Status',
                    _application.status,
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

                          child: AdaptiveDocumentTile(

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

trailing: Wrap(
  spacing: 8,
  runSpacing: 8,
  alignment: WrapAlignment.end,
  children: [
    OutlinedButton.icon(
      icon: const Icon(
        Icons.visibility,
      ),
      label: const Text(
        'VIEW',
      ),
      onPressed: workflowAction(context, printing ? null : () => _openDocument(file)),
    ),
    ElevatedButton.icon(
      icon: const Icon(
        Icons.print,
      ),
      label: const Text(
        'PRINT',
      ),
      onPressed: workflowAction(context, printing ? null : () => _printDocument(file)),
    ),
  ],
),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  const Text(
                    'Inspection Photos & Uploads',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (buildingAttachments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  _attachmentTile(
                    icon: Icons.photo_library,
                    title: 'Inspection Photos (PDF)',
                    subtitle:
                        '$photoCount photo(s) • up to 4 per A4 page',
                    count: photoCount,
                    photos: true,
                  ),

                  _attachmentTile(
                    icon: Icons.upload_file,
                    title: 'Uploaded Documents (PDF)',
                    subtitle:
                        '$uploadCount document(s) • includes all uploaded PDF pages',
                    count: uploadCount,
                    photos: false,
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

      child: AdaptiveRow(
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