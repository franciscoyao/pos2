import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pos_system/core/services/config_service.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnected) return;

    try {
      final wsUrl = ConfigService.baseUrl.replaceFirst('http', 'ws');
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _controller.add(data);
          } catch (e) {
            debugPrint('WebSocket message parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('Attempting to reconnect WebSocket...');
        connect();
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
