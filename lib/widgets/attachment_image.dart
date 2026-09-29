import 'dart:io';
import 'package:flutter/material.dart';
import '../services/cloud_file_service.dart';

/// Uses a device-local downloaded file, with an actionable retry on failure.
class AttachmentImage extends StatefulWidget {
  final int applicationId;
  final String storedPath;
  final double? width, height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  const AttachmentImage({super.key, required this.applicationId, required this.storedPath,
    this.width, this.height, this.fit = BoxFit.contain, this.errorBuilder});
  @override State<AttachmentImage> createState() => _AttachmentImageState();
}
class _AttachmentImageState extends State<AttachmentImage> {
  late Future<String> _file;
  Future<String> _load() => CloudFileService.resolvePhotoPath(applicationId: widget.applicationId,
    storedPath: widget.storedPath, requiredForUse: true);
  @override void initState() { super.initState(); _file = _load(); }
  @override void didUpdateWidget(covariant AttachmentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedPath != widget.storedPath || oldWidget.applicationId != widget.applicationId) _file = _load();
  }
  Widget _error(Object error) => Center(child: IconButton(
    tooltip: 'Photo unavailable. Tap for details and retry.',
    icon: const Icon(Icons.cloud_off, color: Colors.red),
    onPressed: () async {
      final retry = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Photo could not load'), content: Text(error.toString()), actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Close')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Retry')),
        ],
      ));
      if (mounted && retry == true) setState(() => _file = _load());
    },
  ));
  @override Widget build(BuildContext context) => SizedBox(width: widget.width, height: widget.height,
    child: FutureBuilder<String>(future: _file, builder: (context, snapshot) {
      if (snapshot.hasError) return _error(snapshot.error!);
      if (!snapshot.hasData) return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()));
      return Image.file(File(snapshot.data!), width: widget.width, height: widget.height, fit: widget.fit,
        errorBuilder: (context, error, stack) => _error(error));
    }),
  );
}
