import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pos_system/data/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Categories,
    MenuItems,
    Orders,
    OrderItems,
    Printers,
    Settings,
    RestaurantTables,
    Payments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Migration from version 1 to 2: Add restaurant_tables table
        await migrator.createTable(restaurantTables);
      }
      if (from < 3) {
        // Migration to 3: Add status to categories
        await migrator.addColumn(categories, categories.status);
      }
      if (from < 4) {
        // Migration to 4: (no-op, was data cleanup)
      }
      if (from < 5) {
        // Migration to 5: (no-op)
      }
      if (from < 6) {
        // Migration to 6: Add remoteId columns for PocketBase sync
        await _safeAddRemoteId(migrator, users, users.remoteId);
        await _safeAddRemoteId(migrator, categories, categories.remoteId);
        await _safeAddRemoteId(migrator, menuItems, menuItems.remoteId);
        await _safeAddRemoteId(migrator, orders, orders.remoteId);
        await _safeAddRemoteId(migrator, orderItems, orderItems.remoteId);
        await _safeAddRemoteId(
          migrator,
          restaurantTables,
          restaurantTables.remoteId,
        );
      }
      if (from < 7) {
        // Migration to 7: Add payments table
        await migrator.createTable(payments);
      }
      if (from < 8) {
        // Migration to 8: Retry adding remoteId to orderItems (fix for missing col)
        await _safeAddRemoteId(migrator, orderItems, orderItems.remoteId);
      }
      if (from < 9) {
        // Migration to 9: Ensure remoteId exists on ALL tables (catch-all for missing columns)
        await _safeAddRemoteId(migrator, users, users.remoteId);
        await _safeAddRemoteId(migrator, categories, categories.remoteId);
        await _safeAddRemoteId(migrator, menuItems, menuItems.remoteId);
        await _safeAddRemoteId(migrator, orders, orders.remoteId);
        await _safeAddRemoteId(
          migrator,
          restaurantTables,
          restaurantTables.remoteId,
        );
        // (orderItems covered in v8, but harmless to retry)
        await _safeAddRemoteId(migrator, orderItems, orderItems.remoteId);
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _safeAddRemoteId(
    Migrator m,
    TableInfo table,
    GeneratedColumn col,
  ) async {
    try {
      await m.addColumn(table, col);
    } catch (e) {
      // Column likely exists
    }
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_system.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
