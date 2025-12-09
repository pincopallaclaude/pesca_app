import 'dart:ui';

class WorkerStatus {
  String status;
  double load;
  Color color;
  WorkerStatus(this.status, this.load, this.color);
}

class LogEntry {
  final String timestamp;
  final String level;
  final String message;
  LogEntry(this.timestamp, this.level, this.message);
}
