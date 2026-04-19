import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  ConnectivityService(this._connectivity) {
    _sub = _connectivity.onConnectivityChanged.listen(_onChange);
    _bootstrap();
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status = NetworkStatus.online;

  NetworkStatus get status => _status;
  Stream<NetworkStatus> get stream => _controller.stream;

  Future<void> _bootstrap() async {
    final result = await _connectivity.checkConnectivity();
    _onChange(result);
  }

  void _onChange(List<ConnectivityResult> result) {
    final online = result.any(
      (r) => r != ConnectivityResult.none && r != ConnectivityResult.bluetooth,
    );
    final next = online ? NetworkStatus.online : NetworkStatus.offline;
    if (next != _status) {
      _status = next;
      _controller.add(next);
    }
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService(Connectivity());
  ref.onDispose(service.dispose);
  return service;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.stream;
});
