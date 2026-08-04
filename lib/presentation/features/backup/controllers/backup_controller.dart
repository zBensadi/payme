import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/backup_service.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';

final backupControllerProvider = AsyncNotifierProvider<BackupController, void>(BackupController.new);

class BackupController extends AsyncNotifier<void> {
  late BackupService _backupService;

  @override
  Future<void> build() async {
    _backupService = ref.watch(backupServiceProvider);
  }

  Future<bool> createBackup(String destinationZipPath) async {
    state = const AsyncLoading();
    final result = await _backupService.createBackup(destinationZipPath);
    if (result is Success) {
      state = const AsyncData(null);
      return true;
    } else {
      final failure = (result as Failure).failure;
      state = AsyncValue<void>.error(failure.message, StackTrace.current);
      return false;
    }
  }

  Future<bool> restoreBackup(String sourceZipPath) async {
    state = const AsyncLoading();
    final result = await _backupService.restoreBackup(sourceZipPath);
    if (result is Success) {
      state = const AsyncData(null);
      return true;
    } else {
      final failure = (result as Failure).failure;
      state = AsyncValue<void>.error(failure.message, StackTrace.current);
      return false;
    }
  }
}
