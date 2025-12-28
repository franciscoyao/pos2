import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/database/database_provider.dart';
import 'package:pos_system/data/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
});
