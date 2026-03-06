import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/src/platform/web_socket_service_io.dart' as io_ws;

void main() {
  test('io websocket connector opens a socket and forwards headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final upgradeComplete = Completer<void>();
    String? seenHeader;

    unawaited(
      server.forEach((request) async {
        seenHeader = request.headers.value('x-test-header');
        final socket = await WebSocketTransformer.upgrade(request);
        socket.add('ready');
        await socket.close(WebSocketStatus.normalClosure, 'bye');
        if (!upgradeComplete.isCompleted) {
          upgradeComplete.complete();
        }
      }),
    );

    final channel = await io_ws.connect(
      Uri.parse('ws://${server.address.address}:${server.port}'),
      {'x-test-header': 'present'},
    );

    expect(await channel.stream.first, 'ready');
    expect(seenHeader, 'present');

    await upgradeComplete.future;
    await channel.sink.close();
    await server.close(force: true);
  });
}
