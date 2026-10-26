import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 웹소켓 연결을 생성하는 함수
// 헤더를 포함할 수 있도록 IOWebSocketChannel.connect와 channel.ready를 사용합니다.
Future<WebSocketChannel> connect(Uri uri, Map<String, dynamic> headers) async {
  final channel = IOWebSocketChannel.connect(
    uri,
    headers: headers,
  );
  await channel.ready;
  return channel;
}