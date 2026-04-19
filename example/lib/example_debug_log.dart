import 'package:flutter/foundation.dart';

void logExampleEvent(String scope, String message) {
  debugPrint('[$scope ${_timestamp()}] $message');
}

String _timestamp() {
  final now = DateTime.now();
  return '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}.${_threeDigits(now.millisecond)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _threeDigits(int value) => value.toString().padLeft(3, '0');
