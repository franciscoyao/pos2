import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/database/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/services/sync_service.dart';
import 'package:pos_system/data/services/sync_provider.dart';

part 'table_repository.g.dart';

class TableRepository {
  final AppDatabase db;
  final SyncService syncService;

  TableRepository(this.db, this.syncService);

  Future<List<RestaurantTable>> getAllTables() {
    return db.select(db.restaurantTables).get();
  }

  Stream<List<RestaurantTable>> watchAllTables() {
    return db.select(db.restaurantTables).watch();
  }

  Future<int> addTable(String name) {
    return db
        .into(db.restaurantTables)
        .insert(
          RestaurantTablesCompanion(
            name: Value(name),
            status: const Value('available'),
          ),
        );
  }

  Future<void> deleteTable(int id) {
    return (db.delete(db.restaurantTables)..where((t) => t.id.equals(id))).go();
  }

  Future<void> ensureTableExists(String tableName) async {
    final existing = await (db.select(
      db.restaurantTables,
    )..where((t) => t.name.equals(tableName))).getSingleOrNull();

    if (existing == null) {
      await addTable(tableName);
    }
  }
}

@Riverpod(keepAlive: true)
TableRepository tableRepository(Ref ref) {
  return TableRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
}
