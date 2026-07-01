import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_manager.dart';

/// Logger manager singleton
final loggerManagerProvider = Provider<LoggerManager>((ref) {
  return LoggerManager();
});

/// Set log level provider
final setLogLevelProvider = Provider((ref) {
  return (LogLevel level) {
    ref.watch(loggerManagerProvider).setMinLevel(level);
  };
});

/// Log notifier for imperative logging
class LogNotifier extends StateNotifier<void> {
  final LoggerManager _logger;

  LogNotifier(this._logger) : super(null);

  void v(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error, stackTrace);
  }

  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error, stackTrace);
  }

  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error, stackTrace);
  }

  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
  }

  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
  }
}

final logNotifierProvider = StateNotifierProvider<LogNotifier, void>((ref) {
  final loggerManager = ref.watch(loggerManagerProvider);
  return LogNotifier(loggerManager);
});
