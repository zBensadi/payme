import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import '../storage/app_paths.dart';

final loggerProvider = Provider<LoggerService>((ref) {
  throw UnimplementedError('LoggerService not initialized. Overridden in main().');
});

class LoggerService {
  final Logger _logger;

  LoggerService(this._logger);

  static Future<LoggerService> init() async {
    final logDir = await AppPaths.getLogsPath();
    final now = DateTime.now();
    // Daily rotating file name, e.g., payme-2026-08-02.log
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final logFile = File(p.join(logDir, 'payme-$dateStr.log'));
    
    final logger = Logger(
      filter: ProductionFilter(), // Log all events > debug in prod
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        FileOutput(file: logFile),
      ]),
    );
    
    return LoggerService(logger);
  }

  void debug(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
