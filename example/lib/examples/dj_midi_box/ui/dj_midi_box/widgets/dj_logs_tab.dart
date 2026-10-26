import 'package:flutter/material.dart';

import '../dj_midi_box_i18n.dart';
import '../view_models/dj_midi_box_view_model.dart';

/// "LOGS" tab of the DJ console: real-time WebSocket event log.
Widget buildDjLogsTab(
  DjMidiBoxViewModel vm,
  ScrollController logScrollController,
) {
  final i18n = DjMidiBoxI18n.current;
  final logs = vm.logs;
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: Colors.black26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              i18n.eventsHeader(logs.length),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            InkWell(
              onTap: vm.clearLogs,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  i18n.clearLogsButton,
                  style: const TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: logs.isEmpty
            ? Center(
                child: Text(
                  i18n.emptyLogsText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              )
            : ListView.builder(
                controller: logScrollController,
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (ctx, i) {
                  final log = logs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[${log.timeFormatted}] ',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            log.text,
                            style: TextStyle(
                              color: log.color,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );
}
