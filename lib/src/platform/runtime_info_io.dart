import 'dart:io' show Platform;

String dartVersion() {
  final version = Platform.version;
  final match = RegExp(r'(\d+)\.(\d+)').firstMatch(version);
  return match != null ? '${match.group(1)}.${match.group(2)}' : '3.0';
}
