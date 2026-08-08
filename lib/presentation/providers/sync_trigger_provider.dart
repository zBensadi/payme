import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_trigger.dart';

final syncTriggerProvider = Provider<SyncTrigger>((ref) {
  final trigger = SyncTrigger();
  ref.onDispose(() => trigger.dispose());
  return trigger;
});
