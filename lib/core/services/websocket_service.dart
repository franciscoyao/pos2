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
    socket = socket_io.io('http://192.168.1.71:3000', <String, dynamic>{
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
      syncService
          .syncTables(); // For now, re-sync all or implement specific update
    });

    socket.on('order:new', (data) {
      debugPrint('New order received: $data');
      syncService.syncOrders();
    });

    socket.on('order:update', (data) {
      debugPrint('Order update received: $data');
      syncService.syncOrders();
    });
  }

  void sendMessage(String message) {
    socket.emit('msgToServer', message);
  }

  void dispose() {
    socket.dispose();
  }
}
