import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  final AppDatabase db;

  SettingsRepository(this.db);

  Stream<SystemSetting> watchSettings() {
    return (db.select(db.settings)..limit(1)).watchSingle().handleError((_) {
      // If no settings exist, return default
      // We should probably ensure a row exists on init
    });
  }

  Future<SystemSetting?> getSettings() {
    return (db.select(db.settings)..limit(1)).getSingleOrNull();
  }

  Future<void> updateSettings(SettingsCompanion settings) async {
    final count = await db.settings.count().getSingle();
    if (count == 0) {
      await db.into(db.settings).insert(settings);
    } else {
      // Update the first row
      final firstRow = await (db.select(db.settings)..limit(1)).getSingle();
      await (db.update(
        db.settings,
      )..where((t) => t.id.equals(firstRow.id))).write(settings);
    }
  }

  // Initialize default settings if needed
  Future<void> initSettings() async {
    final count = await db.settings.count().getSingle();
    if (count == 0) {
      await db
          .into(db.settings)
          .insert(
            const SettingsCompanion(
              taxRate: Value(10.0),
              serviceRate: Value(5.0),
              orderDelayThreshold: Value(15),
              kioskMode: Value(false),
            ),
          );
    }
  }

  Future<void> clearAllDataExceptMenu() async {
    await db.delete(db.orderItems).go();
    await db.delete(db.orders).go();
    await db.delete(db.restaurantTables).go();
  }
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(databaseProvider));
}
