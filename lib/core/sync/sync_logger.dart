import 'package:flutter/foundation.dart';

class SyncLogger {
  void logOperation(String repoName, String operation, int count, String status, [String? error]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [SYNC] [$repoName] $operation: $count $status ${error != null ? '- Reason: $error' : ''}';
    debugPrint(logMessage);
  }
  
  void logInfo(String message) {
    debugPrint('[SYNC] INFO: $message');
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[SYNC] ERROR: $message - $error\n$stackTrace');
  }
}
