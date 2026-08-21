import 'package:flutter/foundation.dart';
import 'dart:async';
import 'sync_domain.dart';

class SyncTrigger {
  final _controller = StreamController<SyncDomain>.broadcast();

  /// Exposes the stream of sync domains requested by local repositories.
  Stream<SyncDomain> get syncRequested => _controller.stream;

  /// Requests a synchronization cycle for a specific domain.
  void requestSync(SyncDomain domain) {
    debugPrint('[TRACE-VISIBILITY] SyncTrigger.requestSync: $domain');
    if (!_controller.isClosed) {
      _controller.add(domain);
    }
  }

  /// Requests a full synchronization cycle for all domains.
  void requestFullSync() {
    if (!_controller.isClosed) {
      for (final domain in SyncDomain.values) {
        _controller.add(domain);
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}
