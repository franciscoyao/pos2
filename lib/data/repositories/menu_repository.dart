import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';
import 'package:pos_system/data/services/sync_provider.dart';
import 'package:pos_system/data/services/sync_service.dart';

part 'menu_repository.g.dart';

class MenuRepository {
  final AppDatabase db;
  final SyncService syncService;

  MenuRepository(this.db, this.syncService);

  Future<List<Category>> getCategories() => (db.select(
    db.categories,
  )..where((t) => t.status.isNotValue('deleted'))).get();

  Stream<List<Category>> watchCategories({String? menuType}) {
    var query = db.select(db.categories)
      ..where((t) => t.status.isNotValue('deleted'));

    if (menuType != null) {
      query.where((t) => t.menuType.equals(menuType));
    }

    return query.watch();
  }

  Future<List<MenuItem>> getItemsByCategory(int categoryId, {String? type}) {
    var query = db.select(db.menuItems)
      ..where((t) => t.categoryId.equals(categoryId))
      ..where((t) => t.status.isNotValue('deleted'));

    if (type != null) {
      query.where((t) => t.type.equals(type));
    }

    return query.get();
  }

  Stream<List<MenuItem>> watchItemsByCategory(int categoryId, {String? type}) {
    var query = db.select(db.menuItems)
      ..where((t) => t.categoryId.equals(categoryId))
      ..where((t) => t.status.isNotValue('deleted'));

    if (type != null) {
      query.where((t) => t.type.equals(type));
    }

    return query.watch();
  }

  Future<List<MenuItem>> getAllItems() => (db.select(
    db.menuItems,
  )..where((t) => t.status.isNotValue('deleted'))).get();

  Stream<List<MenuItem>> watchAllItems() => (db.select(
    db.menuItems,
  )..where((t) => t.status.isNotValue('deleted'))).watch();

  Future<int> addCategory(CategoriesCompanion category) async {
    final id = await db.into(db.categories).insert(category);
    // Push upstream
    try {
      final serverId = await syncService.createCategory(category);
      // Update local ID to match server ID immediately
      await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(id: Value(serverId)),
      );
      // If we had items using the old ID, we would need to migrate them here too
      // But addCategory usually happens before items are added to it.
      return serverId;
    } catch (e) {
      // Allow offline - will sync later or queue
      debugPrint('Upstream category creation failed: $e');
      return id;
    }
  }

  Future<void> updateCategory(Category category) async {
    await db.update(db.categories).replace(category);
    try {
      await syncService.updateCategory(category);
    } catch (e) {
      debugPrint('Upstream category update failed: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    await db.transaction(() async {
      // Soft delete all items in this category
      await (db.update(db.menuItems)..where((t) => t.categoryId.equals(id)))
          .write(const MenuItemsCompanion(status: Value('deleted')));
      // Soft delete the category
      await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
        const CategoriesCompanion(status: Value('deleted')),
      );
    });
    // Push upstream delete
    try {
      await syncService.deleteCategoryUpstream(id);
    } catch (e) {
      debugPrint('Upstream category deletion failed: $e');
    }
  }

  Future<int> addItem(MenuItemsCompanion item) async {
    final id = await db.into(db.menuItems).insert(item);
    try {
      final serverId = await syncService.createMenuItem(item);
      // Update local ID to match server ID immediately
      await (db.update(db.menuItems)..where((t) => t.id.equals(id))).write(
        MenuItemsCompanion(id: Value(serverId)),
      );
      return serverId;
    } catch (e) {
      debugPrint('Upstream item creation failed: $e');
      return id;
    }
  }

  Future<void> updateItem(MenuItem item) async {
    await db.update(db.menuItems).replace(item);
    try {
      await syncService.updateMenuItem(item);
    } catch (e) {
      debugPrint('Upstream item update failed: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    // Soft delete to preserve order history
    await (db.update(db.menuItems)..where((t) => t.id.equals(id))).write(
      const MenuItemsCompanion(status: Value('deleted')),
    );
    // Push upstream delete
    try {
      await syncService.deleteMenuItemUpstream(id);
    } catch (e) {
      debugPrint('Upstream item deletion failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
MenuRepository menuRepository(Ref ref) {
  return MenuRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
}
