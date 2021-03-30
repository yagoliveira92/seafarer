enum _LogLevel { info, warning }

String _logLevelToString(_LogLevel? level) {
  return level.toString().split(".")[1].toUpperCase();
}

class AppLogger {
  static late AppLogger _instance;

  final bool isLoggerEnabled;

  AppLogger._internal({
    required this.isLoggerEnabled,
  });

  static void init({required bool isLoggerEnabled,
  }) {
    _instance = AppLogger._internal(
      isLoggerEnabled: isLoggerEnabled,
    );
  }

  static AppLogger get instance => _instance;

  void info(String message) {
    _log(
      level: _LogLevel.info,
      message: message,
    );
  }

  void warning(String message) {
    _log(
      level: _LogLevel.warning,
      message: message,
    );
  }

  void _log({
    String? message,
    _LogLevel? level,
  }) {
    if (this.isLoggerEnabled) {
      print("[seafarer] ${_logLevelToString(level)} : $message");
    }
  }
}
