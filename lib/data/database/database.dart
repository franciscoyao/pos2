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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
        // Migration to 4: Clear fake data - DISABLED for production safety
        // In a real app, you should migrate data instead of deleting it.
        // If schema changes are incompatible, use migrator.alterTable or create new tables and copy data.
        
        // await delete(orderItems).go();
        // await delete(orders).go();
        // await delete(menuItems).go();
        // await delete(categories).go();
      }
      if (from < 5) {
        // Migration to 5: Clear existing tables - DISABLED for production safety
        // await delete(restaurantTables).go();
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
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
