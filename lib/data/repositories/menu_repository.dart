import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';

part 'menu_repository.g.dart';

class MenuRepository {
  final AppDatabase db;

  MenuRepository(this.db);

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

  Future<int> addCategory(CategoriesCompanion category) =>
      db.into(db.categories).insert(category);

  Future<void> updateCategory(Category category) =>
      db.update(db.categories).replace(category);

  Future<void> deleteCategory(int id) {
    return db.transaction(() async {
      // Soft delete all items in this category
      await (db.update(db.menuItems)..where((t) => t.categoryId.equals(id)))
          .write(const MenuItemsCompanion(status: Value('deleted')));
      // Soft delete the category
      await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
        const CategoriesCompanion(status: Value('deleted')),
      );
    });
  }

  Future<int> addItem(MenuItemsCompanion item) =>
      db.into(db.menuItems).insert(item);

  Future<void> updateItem(MenuItem item) =>
      db.update(db.menuItems).replace(item);

  Future<void> deleteItem(int id) {
    // Soft delete to preserve order history
    return (db.update(db.menuItems)..where((t) => t.id.equals(id))).write(
      const MenuItemsCompanion(status: Value('deleted')),
    );
  }
}

@Riverpod(keepAlive: true)
MenuRepository menuRepository(Ref ref) {
  return MenuRepository(ref.watch(databaseProvider));
}
