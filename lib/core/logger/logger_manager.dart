import 'package:logger/logger.dart';

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// Centralized logging manager
class LoggerManager {
  static final LoggerManager _instance = LoggerManager._internal();

  late Logger _logger;
  LogLevel _minLevel = LogLevel.debug;

  factory LoggerManager() {
    return _instance;
  }

  LoggerManager._internal() {
    _initLogger();
  }

  void _initLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 3,
        errorMethodCount: 5,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: Level.verbose,
      output: ConsoleOutput(),
    );
  }

  /// Set minimum log level
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Get current log level
  LogLevel get minLevel => _minLevel;

  /// Get logger instance
  Logger get logger => _logger;

  /// Log verbose message
  void v(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLevel.index <= LogLevel.verbose.index) {
      _logger.v(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log debug message
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLevel.index <= LogLevel.debug.index) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLevel.index <= LogLevel.info.index) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning message
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLevel.index <= LogLevel.warning.index) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log error message
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLevel.index <= LogLevel.error.index) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Close logger (cleanup)
  void close() {
    // Cleanup if needed
  }
}

/// Global logger instance for easy access
final log = LoggerManager();
