import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_domain.dart';
import 'sync_trigger_provider.dart';

final syncSignalProvider = StreamProvider<SyncDomain>((ref) {
  return ref.watch(syncTriggerProvider).syncRequested;
});
