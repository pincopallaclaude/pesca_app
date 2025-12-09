import 'package:flutter/material.dart';
import '../models.dart';
import 'core_widgets.dart';

Widget buildTerminalLogs(List<LogEntry> logs) {
  return PlatinumCard(
    child: SizedBox(
      height: 150,
      child: ListView.builder(
        reverse: true,
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(log.timestamp, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Courier')),
                const SizedBox(width: 8),
                Text(log.level,
                    style: TextStyle(
                        color: log.level == "INIT" ? Colors.green : (log.level == "TASK" || log.level == "CRON" ? Colors.orangeAccent : Colors.blue),
                        fontSize: 10,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(child: Text(log.message, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Courier'), overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        },
      ),
    ),
  );
}
