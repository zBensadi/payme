import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncRefreshNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRefreshing(bool isRefreshing) {
    state = isRefreshing;
  }
}

final syncRefreshStateProvider = NotifierProvider<SyncRefreshNotifier, bool>(SyncRefreshNotifier.new);
