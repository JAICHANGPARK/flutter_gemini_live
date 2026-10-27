import 'package:web_socket_channel/web_socket_channel.dart';

/// Whether the WebSocket transport forwards handshake HTTP headers.
const bool supportsHeaders = true;

// 다른 파일들과 함수 시그니처를 통일합니다.
Future<WebSocketChannel> connect(Uri uri, Map<String, dynamic> headers) {
  throw UnsupportedError(
      'Cannot create a web socket channel without dart:html or dart:io.');
}
