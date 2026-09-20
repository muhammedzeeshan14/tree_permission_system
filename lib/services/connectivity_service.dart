import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Stage 1: online/offline detection for offline-first sync.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance =
      ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool _online = true;
  bool _started = false;

  bool get isOnline => _online;
  Stream<bool> get onStatus => _controller.stream;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    final results = await _connectivity.checkConnectivity();
    _update(results);
    _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = !results.contains(ConnectivityResult.none);
    if (online != _online) {
      _online = online;
      _controller.add(_online);
    }
  }

  void dispose() => _controller.close();
}
