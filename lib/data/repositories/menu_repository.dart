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
    // Local-First: Insert locally
    final id = await db.into(db.categories).insert(category);

    // Sync in background
    syncService.createCategory(category, id).ignore();

    return id;
  }

  Future<void> updateCategory(Category category) async {
    await db.update(db.categories).replace(category);
    syncService.updateCategory(category).ignore();
  }

  Future<void> deleteCategory(int id) async {
    // Get remoteId before deleting? Or just call upstream first?
    // If we call upstream first and it fails (offline), we might want to delete locally anyway if we want local-first?
    // Ideally: Mark as deleted locally or store action in queue.
    // For now: Attempt sync, then delete locally. Or simpler: SyncService handles lookup before delete.

    // Better approach:
    await syncService.deleteCategoryUpstream(id);
    // Realtime will handle local delete if successful?
    // If we rely on realtime, it's online-only.
    // To support offline:
    await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
  }

  Future<int> addItem(MenuItemsCompanion item) async {
    final id = await db.into(db.menuItems).insert(item);
    syncService.createMenuItem(item, id).ignore();
    return id;
  }

  Future<void> updateItem(MenuItem item) async {
    try {
      await syncService.updateMenuItem(item);
    } catch (e) {
      debugPrint('Upstream item update failed: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(int id) async {
    // Try upstream first (best effort)
    try {
      await syncService.deleteMenuItemUpstream(id);
    } catch (e) {
      debugPrint('Upstream item deletion failed (offline?): $e');
    }
    // Delete locally regardless to ensure UI responsiveness
    await (db.delete(db.menuItems)..where((t) => t.id.equals(id))).go();
  }
}

@Riverpod(keepAlive: true)
MenuRepository menuRepository(Ref ref) {
  return MenuRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
}
