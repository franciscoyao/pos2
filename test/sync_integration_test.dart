import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/services/pocketbase_service.dart';
import 'package:pos_system/data/services/sync_service.dart';

Future<void> wait([int secs = 1]) => Future.delayed(Duration(seconds: secs));

void main() {
  late AppDatabase db;
  late PocketBase pb;
  late PocketBaseService pbService;
  late SyncService syncService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pb = PocketBase('http://127.0.0.1:8090');
    pbService = PocketBaseService(pb);

    // PB v0.25+ auth - authenticate BEFORE creating SyncService
    // so realtime subscriptions have a valid token
    await pb
        .collection('_superusers')
        .authWithPassword('admin@pos.local', '1234567890');

    syncService = SyncService(db, pbService);
  });

  tearDown(() async {
    await db.close();
  });

  test('Create menu item syncs to PocketBase', () async {
    // 1. Create category in PB
    final catName = 'TestCat_${DateTime.now().millisecondsSinceEpoch}';
    final catRecord = await pb
        .collection('categories')
        .create(
          body: {
            'name': catName,
            'menuType': 'dine-in',
            'sortOrder': 1,
            'status': 'active',
          },
        );

    // Mirror locally
    final catId = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion(
            remoteId: Value(catRecord.id),
            name: Value(catName),
            menuType: Value('dine-in'),
            sortOrder: Value(1),
            status: Value('active'),
            station: Value('kitchen'),
          ),
        );

    // 2. Insert menu item locally
    final itemName = 'Burger_${DateTime.now().millisecondsSinceEpoch}';
    final companion = MenuItemsCompanion(
      name: Value(itemName),
      price: Value(15.0),
      categoryId: Value(catId),
      status: Value('active'),
      station: Value('kitchen'),
      type: Value('dine-in'),
      allowPriceEdit: Value(false),
    );
    final itemId = await db.into(db.menuItems).insert(companion);

    // 3. Push to PB via SyncService
    await syncService.createMenuItem(companion, itemId);
    await wait();

    // 4. Verify in PB
    final pbItems = await pb
        .collection('menu_items')
        .getList(filter: 'name = "$itemName"');
    expect(pbItems.items.length, 1, reason: 'Item should exist in PB');
    expect(pbItems.items.first.getStringValue('category'), catRecord.id);

    // 5. Verify local remoteId
    final localItem = await (db.select(
      db.menuItems,
    )..where((t) => t.id.equals(itemId))).getSingle();
    expect(
      localItem.remoteId,
      pbItems.items.first.id,
      reason: 'Local remoteId should match PB id',
    );

    // Cleanup
    await pb.collection('menu_items').delete(localItem.remoteId!);
    await pb.collection('categories').delete(catRecord.id);
  });

  test('Delete menu item syncs to PocketBase', () async {
    // 1. Create category in PB
    final catRecord = await pb
        .collection('categories')
        .create(
          body: {
            'name': 'DelCat_${DateTime.now().millisecondsSinceEpoch}',
            'menuType': 'dine-in',
            'sortOrder': 1,
            'status': 'active',
          },
        );

    final catId = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion(
            remoteId: Value(catRecord.id),
            name: Value('DelCat'),
            menuType: Value('dine-in'),
            sortOrder: Value(1),
            status: Value('active'),
            station: Value('kitchen'),
          ),
        );

    // 2. Create item in PB and locally (simulating a synced item)
    final itemName = 'DelItem_${DateTime.now().millisecondsSinceEpoch}';
    final itemRecord = await pb
        .collection('menu_items')
        .create(
          body: {
            'name': itemName,
            'price': 10.0,
            'category': catRecord.id,
            'station': 'kitchen',
            'type': 'dine-in',
            'status': 'active',
            'allowPriceEdit': false,
          },
        );

    final itemId = await db
        .into(db.menuItems)
        .insert(
          MenuItemsCompanion(
            remoteId: Value(itemRecord.id),
            name: Value(itemName),
            price: Value(10.0),
            categoryId: Value(catId),
            status: Value('active'),
            station: Value('kitchen'),
            type: Value('dine-in'),
            allowPriceEdit: Value(false),
          ),
        );

    // 3. Delete via SyncService
    await syncService.deleteMenuItemUpstream(itemId);
    await wait();

    // 4. Verify deleted from PB
    try {
      await pb.collection('menu_items').getOne(itemRecord.id);
      fail('Item should be deleted from PB');
    } catch (e) {
      expect(e, isA<ClientException>());
    }

    // Cleanup
    await pb.collection('categories').delete(catRecord.id);
  });
}
