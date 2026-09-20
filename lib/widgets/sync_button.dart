import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';

/// Stage 2: manual sync button with pending count.
/// Drop into any AppBar: `actions: [const SyncButton()]`.
class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _busy = false;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    ConnectivityService.instance.onStatus.listen((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    final pending = await SyncService.instance.pendingCount();
    if (!mounted) return;
    setState(() => _pending = pending);
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    final message = await SyncService.instance.syncNow();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = ConnectivityService.instance.isOnline;
    final ready = SupabaseService.isReady;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_pending > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text('$_pending'),
              visualDensity: VisualDensity.compact,
            ),
          ),
        IconButton(
          tooltip: !ready
              ? 'Supabase not configured'
              : !online
                  ? 'Offline — tap to retry'
                  : 'Sync now',
          onPressed: _busy ? null : _sync,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  ready && online
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
        ),
      ],
    );
  }
}
