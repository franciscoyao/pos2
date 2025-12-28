import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/core/services/websocket_service.dart';
import 'package:pos_system/data/services/sync_provider.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return WebSocketService(syncService);
});
