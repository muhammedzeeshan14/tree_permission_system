import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/document_repository.dart';
import '../../repositories/photo_repository.dart';
import '../../services/cloud_file_service.dart';
import '../../services/session_service.dart';

/// Item 8 (RFO only): see cloud storage per application and delete it.
///
/// - Delete complete file: removes cloud bytes AND their DB rows.
/// - Delete data only: removes cloud bytes, keeps DB record rows
///   (and generated PDFs regenerate on demand) for reference.
class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageInfo {
  final ApplicationModel application;
  final List<CloudFileEntry> generated;
  final List<CloudFileEntry> photos;
  final List<CloudFileEntry> uploads;

  const _StorageInfo({
    required this.application,
    required this.generated,
    required this.photos,
    required this.uploads,
  });

  int get fileCount =>
      generated.length + photos.length + uploads.length;

  int get knownBytes {
    var total = 0;
    for (final e in [...generated, ...photos, ...uploads]) {
      if (e.sizeBytes >= 0) total += e.sizeBytes;
    }
    return total;
  }
}

class _StorageManagementScreenState
    extends State<StorageManagementScreen> {
  final ApplicationRepository _applications =
      ApplicationRepository();
  final PhotoRepository _photos = PhotoRepository();
  final DocumentRepository _documents = DocumentRepository();

  List<_StorageInfo> _items = [];
  List<String> _statuses = ['All'];
  String _statusFilter = 'All';
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _isRfo =>
      SessionService.instance.role.trim().toUpperCase() == 'RFO';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _sizeText(int bytes) {
    if (bytes < 0) return 'size unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final applications =
          await _applications.getApplications();
      final items = <_StorageInfo>[];
      final statusSet = <String>{'All'};
      for (final app in applications) {
        statusSet.add(app.status);
        final office = app.officeNumber;
        final generated =
            await CloudFileService.listFiles(
          CloudFileService.docsBucket,
          'generated/$office',
        );
        final photos = await CloudFileService.listFiles(
          CloudFileService.photosBucket,
          'photos/$office',
        );
        final uploads = await CloudFileService.listFiles(
          CloudFileService.docsBucket,
          'uploads/$office',
        );
        items.add(_StorageInfo(
          application: app,
          generated: generated,
          photos: photos,
          uploads: uploads,
        ));
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _statuses = statusSet.toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_StorageInfo> get _filtered => _statusFilter == 'All'
      ? _items
      : _items
          .where((i) =>
              i.application.status == _statusFilter)
          .toList();

  int get _totalFiles =>
      _filtered.fold(0, (sum, i) => sum + i.fileCount);

  int get _totalBytes =>
      _filtered.fold(0, (sum, i) => sum + i.knownBytes);

  Future<bool> _confirm(
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deleteComplete(_StorageInfo info) async {
    final app = info.application;
    final ok = await _confirm(
      'Delete complete file',
      'Delete ALL cloud files of ${app.officeNumber} '
      '(${info.fileCount} file(s)) AND their photo/document '
      'records? Generated letters regenerate on demand.',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      // Photos: rows + bytes.
      final photos =
          await _photos.getPhotos(app.id!);
      for (final photo in photos) {
        if (photo.id != null) {
          await _photos.deletePhoto(photo.id!);
        }
      }
      await CloudFileService.deletePrefix(
        CloudFileService.photosBucket,
        'photos/${app.officeNumber}',
      );
      // Uploads: rows + bytes.
      final docs =
          await _documents.getDocuments(app.id!);
      for (final doc in docs) {
        if (doc.id != null) {
          await _documents.deleteDocument(doc.id!);
        }
      }
      await CloudFileService.deletePrefix(
        CloudFileService.docsBucket,
        'uploads/${app.officeNumber}',
      );
      // Generated PDFs: bytes (regenerate on demand).
      await CloudFileService.deletePrefix(
        CloudFileService.docsBucket,
        'generated/${app.officeNumber}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete file deleted.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDataOnly(_StorageInfo info) async {
    final app = info.application;
    final ok = await _confirm(
      'Delete data only',
      'Delete cloud file bytes of ${app.officeNumber} '
      '(${info.fileCount} file(s)) but KEEP all record rows '
      'for reference?',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await CloudFileService.deletePrefix(
        CloudFileService.photosBucket,
        'photos/${app.officeNumber}',
      );
      await CloudFileService.deletePrefix(
        CloudFileService.docsBucket,
        'uploads/${app.officeNumber}',
      );
      await CloudFileService.deletePrefix(
        CloudFileService.docsBucket,
        'generated/${app.officeNumber}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'File data deleted, records kept.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRfo) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Storage Management'),
        ),
        body: const Center(
          child: Text(
            'Storage Management is available to RFO login only.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cloud usage (filter: $_statusFilter)',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_totalFiles file(s) • '
                                '${_sizeText(_totalBytes)}'
                                '${_totalBytes == 0 ? ' (sizes reported by cloud)' : ''}',
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<
                                  String>(
                                value: _statusFilter,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Application status',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                items: _statuses
                                    .map((s) =>
                                        DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() =>
                                      _statusFilter =
                                          v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(
                              child: Text(
                                  'No applications found.'),
                            )
                          : ListView.builder(
                              itemCount:
                                  _filtered.length,
                              itemBuilder:
                                  (context, index) {
                                final info =
                                    _filtered[index];
                                final app =
                                    info.application;
                                return Card(
                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets
                                            .all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          app.officeNumber,
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${app.applicantName} • ${app.status}',
                                        ),
                                        const SizedBox(
                                            height: 4),
                                        Text(
                                          'Letters: ${info.generated.length} • '
                                          'Photos: ${info.photos.length} • '
                                          'Uploads: ${info.uploads.length} • '
                                          '${_sizeText(info.knownBytes)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton
                                                .icon(
                                              icon: const Icon(
                                                Icons
                                                    .delete_forever,
                                                color: Colors
                                                    .red,
                                              ),
                                              label:
                                                  const Text(
                                                'Delete complete file',
                                              ),
                                              onPressed: _busy ||
                                                      info.fileCount ==
                                                          0
                                                  ? null
                                                  : () =>
                                                      _deleteComplete(
                                                          info),
                                            ),
                                            ElevatedButton
                                                .icon(
                                              icon: const Icon(
                                                  Icons
                                                      .cleaning_services),
                                              label:
                                                  const Text(
                                                'Delete data only',
                                              ),
                                              onPressed: _busy ||
                                                      info.fileCount ==
                                                          0
                                                  ? null
                                                  : () =>
                                                      _deleteDataOnly(
                                                          info),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
