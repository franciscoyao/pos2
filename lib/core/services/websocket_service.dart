import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:pos_system/data/services/sync_service.dart';

class WebSocketService {
  final SyncService syncService;
  late socket_io.Socket socket;

  WebSocketService(this.syncService);

  void init() {
    // Replace with your backend URL.
    // For Android Emulator use 10.0.2.2 instead of localhost
    // For physical device use your machine's LAN IP
    socket = socket_io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('WebSocket: Connected');
    });

    socket.onDisconnect((_) {
      debugPrint('WebSocket: Disconnected');
    });

    socket.on('msgToClient', (data) {
      debugPrint('WebSocket Received: $data');
    });

    socket.on('table:update', (data) {
      debugPrint('Table update received: $data');
      if (data != null && data is Map<String, dynamic>) {
        syncService.upsertRestaurantTable(data);
      }
    });

    socket.on('category:update', (data) {
      debugPrint('Category update received: $data');
      if (data != null && data is Map<String, dynamic>) {
        syncService.upsertCategory(data);
      }
    });

    socket.on('menu-item:update', (data) {
      debugPrint('MenuItem update received: $data');
      if (data != null && data is Map<String, dynamic>) {
        syncService.upsertMenuItem(data);
      }
    });

    socket.on('order:new', (data) {
      debugPrint('New order received: $data');
      if (data != null && data is Map<String, dynamic>) {
        syncService.upsertOrder(data);
      }
    });

    socket.on('order:update', (data) {
      debugPrint('Order update received: $data');
      if (data != null && data is Map<String, dynamic>) {
        syncService.upsertOrder(data);
      }
    });
  }

  void sendMessage(String message) {
    socket.emit('msgToServer', message);
  }

  void dispose() {
    socket.dispose();
  }
}
