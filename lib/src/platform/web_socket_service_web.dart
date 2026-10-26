// coverage:ignore-file
import 'package:web_socket_channel/web_socket_channel.dart';

// 웹소켓 연결을 생성하는 함수
// io 파일과 시그니처(입력/출력 타입)를 동일하게 맞춰줍니다.
Future<WebSocketChannel> connect(Uri uri, Map<String, dynamic> headers) async {
  // 웹에서는 표준 WebSocketChannel.connect를 사용하고 ready 핸드셰이크를 대기합니다.
  // 필요한 인증 정보(API 키 등)는 URI 쿼리 파라미터에 포함됩니다.
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return channel;
}
