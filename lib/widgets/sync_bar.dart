import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/online_mode.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

/// Stage 2: bottom sync bar for every dashboard.
/// Shows online status, pending count, last sync + Sync button.
class SyncBar extends StatefulWidget {
  const SyncBar({super.key});

  @override
  State<SyncBar> createState() => _SyncBarState();
}

class _SyncBarState extends State<SyncBar> {
  bool _busy = false;
  int _pending = 0;
  DateTime? _lastSync;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _online = ConnectivityService.instance.isOnline;
    _refresh();
    ConnectivityService.instance.onStatus.listen((online) {
      if (!mounted) return;
      setState(() => _online = online);
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final pending = await SyncService.instance.pendingCount();
    final last = await SyncService.instance.lastSync();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _lastSync = last;
    });
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

  String _lastText() {
    if (_lastSync == null) return 'never synced';
    final d = _lastSync!.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return 'last ${d.day}/${d.month} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    // Stage 3: completely-online mode — data is live, no queue.
    if (OnlineMode.enabled) {
      return SafeArea(
        top: false,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Online — data saves live to cloud',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final ready = SupabaseService.isReady;
    final status = !ready
        ? 'local-only'
        : !_online
            ? 'offline'
            : 'online';
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              !ready || !_online
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_done_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$status • $_pending queued • ${_lastText()}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton.icon(
                    onPressed: _sync,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
