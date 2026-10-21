// coverage:ignore-file
import 'package:web_socket_channel/html.dart' as ws;
import 'package:web_socket_channel/web_socket_channel.dart';

// 웹소켓 연결을 생성하는 함수
// io 파일과 시그니처(입력/출력 타입)를 동일하게 맞춰줍니다.
Future<WebSocketChannel> connect(Uri uri, Map<String, dynamic> headers) async {
  // 웹에서는 HtmlWebSocketChannel을 사용합니다.
  // headers 파라미터는 사용되지 않지만, 호환성을 위해 남겨둡니다.
  // 필요한 인증 정보(API 키 등)는 반드시 URI에 포함되어야 합니다.
  return ws.HtmlWebSocketChannel.connect(uri);
}
