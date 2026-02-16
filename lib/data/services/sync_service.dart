import 'package:flutter/foundation.dart' hide Category;
import 'package:pocketbase/pocketbase.dart';
import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/services/pocketbase_service.dart';

class SyncService {
  final AppDatabase db;
  final PocketBaseService pbService;

  SyncService(this.db, this.pbService) {
    initRealtimeUpdates();
  }

  void initRealtimeUpdates() {
    // Subscribe to all relevant collections
    pbService.subscribe('orders', (e) => _handleRealtimeEvent(e, 'orders'));
    pbService.subscribe(
      'restaurant_tables',
      (e) => _handleRealtimeEvent(e, 'restaurant_tables'),
    );
    pbService.subscribe(
      'categories',
      (e) => _handleRealtimeEvent(e, 'categories'),
    );
    pbService.subscribe(
      'menu_items',
      (e) => _handleRealtimeEvent(e, 'menu_items'),
    );
    pbService.subscribe('users', (e) => _handleRealtimeEvent(e, 'users'));
    pbService.subscribe(
      'order_items',
      (e) => _handleRealtimeEvent(e, 'order_items'),
    );
    pbService.subscribe('payments', (e) => _handleRealtimeEvent(e, 'payments'));
  }

  Future<void> _handleRealtimeEvent(
    RecordSubscriptionEvent e,
    String collection,
  ) async {
    debugPrint(
      'Realtime event from $collection: ${e.action} - ${e.record?.id}',
    );
    final record = e.record;
    if (record == null) return;

    if (e.action == 'delete') {
      await _deleteLocal(collection, record.id);
    } else {
      await _upsertLocal(collection, record);
    }
  }

  Future<void> syncAll() async {
    try {
      debugPrint('Starting full sync...');

      // 1. Fetch Sync (Pull)
      await _syncCollection('restaurant_tables');
      await _syncCollection('categories');
      await _syncCollection('menu_items');
      await _syncCollection('users');
      await _syncCollection('orders');
      await _syncCollection('order_items');
      await _syncCollection('payments');

      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> _syncCollection(String collection) async {
    try {
      final records = await pbService.getFullList(collection);
      debugPrint('Fetched ${records.length} records for $collection');

      for (var record in records) {
        await _upsertLocal(collection, record);
      }
    } catch (e) {
      debugPrint('Failed to sync collection $collection: $e');
    }
  }

  // --- Local DB Ops ---

  Future<void> _upsertLocal(String collection, RecordModel record) async {
    switch (collection) {
      case 'restaurant_tables':
        await _upsertTable(record);
        break;
      case 'categories':
        await _upsertCategory(record);
        break;
      case 'menu_items':
        await _upsertMenuItem(record);
        break;
      case 'orders':
        await _upsertOrder(record);
        break;
      case 'users':
        await _upsertUser(record);
        break;
      case 'order_items':
        await _upsertOrderItem(record);
        break;
      case 'payments':
        await _upsertPayment(record);
        break;
    }
  }

  Future<void> _deleteLocal(String collection, String remoteId) async {
    switch (collection) {
      case 'restaurant_tables':
        await (db.delete(
          db.restaurantTables,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'categories':
        await (db.delete(
          db.categories,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'menu_items':
        await (db.delete(
          db.menuItems,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'orders':
        await (db.delete(
          db.orders,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'users':
        await (db.delete(
          db.users,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'payments':
        await (db.delete(
          db.payments,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
    }
  }

  Future<void> _upsertTable(RecordModel record) async {
    await db
        .into(db.restaurantTables)
        .insertOnConflictUpdate(
          RestaurantTablesCompanion(
            remoteId: Value(record.id),
            name: Value(record.getStringValue('name')),
            status: Value(record.getStringValue('status')),
            x: Value(record.getIntValue('x')),
            y: Value(record.getIntValue('y')),
          ),
        );
    // If we have a local record with same name but no remoteId, we should probably link them?
    // For now, let's assume authoritative sync from server.
  }

  Future<void> _upsertCategory(RecordModel record) async {
    await db
        .into(db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion(
            remoteId: Value(record.id),
            name: Value(record.getStringValue('name')),
            menuType: Value(record.getStringValue('menuType')),
            sortOrder: Value(record.getIntValue('sortOrder')),
            station: Value(record.getStringValue('station')),
            status: Value(record.getStringValue('status')),
          ),
        );
  }

  Future<void> _upsertMenuItem(RecordModel record) async {
    // We need to resolve categoryId (local int ID) from remote ID
    final categoryRemoteId = record.getStringValue('category');
    final category = await (db.select(
      db.categories,
    )..where((t) => t.remoteId.equals(categoryRemoteId))).getSingleOrNull();

    if (category == null) {
      debugPrint(
        'Skipping Item ${record.getStringValue('name')}: Category $categoryRemoteId not found locally',
      );
      return;
    }

    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion(
            remoteId: Value(record.id),
            code: Value(record.getStringValue('code')),
            name: Value(record.getStringValue('name')),
            price: Value(record.getDoubleValue('price')),
            categoryId: Value(category.id),
            station: Value(record.getStringValue('station')),
            type: Value(record.getStringValue('type')),
            status: Value(record.getStringValue('status')),
            allowPriceEdit: Value(record.getBoolValue('allowPriceEdit')),
          ),
        );
  }

  Future<void> _upsertUser(RecordModel record) async {
    await db
        .into(db.users)
        .insertOnConflictUpdate(
          UsersCompanion(
            remoteId: Value(record.id),
            fullName: Value(
              record.getStringValue('name'),
            ), // 'name' in PB users collection default
            username: Value(record.getStringValue('username')),
            // pin: Value(record.getStringValue('pin')), // Sensitive?
            role: Value(
              record.getStringValue('role'),
            ), // We might need a custom field in PB users
            status: Value(
              'active',
            ), // PB doesn't have status by default like this
          ),
        );
  }

  Future<void> _upsertOrder(RecordModel record) async {
    // Orders are complex because of OrderItems.
    // We assume OrderItems are stored as a JSON array in the 'items' field of the Order collection in PB for simplicity,
    // OR we can sync a separate 'order_items' collection.
    // Given the previous implementation used a nested JSON approach, let's try to stick to that if possible,
    // OR fetch 'order_items' separately.
    // FOR ROBUSTNESS: Let's assume 'order_items' is a separate collection in PB, or expanded.

    // If we receive the order with expanded items:
    // This requires the 'expand' parameter in getFullList.
    // For now, let's just sync the Order header.

    await db
        .into(db.orders)
        .insertOnConflictUpdate(
          OrdersCompanion(
            remoteId: Value(record.id),
            orderNumber: Value(record.getStringValue('orderNumber')),
            tableNumber: Value(record.getStringValue('tableNumber')),
            type: Value(record.getStringValue('type')),
            status: Value(record.getStringValue('status')),
            totalAmount: Value(record.getDoubleValue('totalAmount')),
            taxAmount: Value(record.getDoubleValue('taxAmount')),
            serviceAmount: Value(record.getDoubleValue('serviceAmount')),
            paymentMethod: Value(record.getStringValue('paymentMethod')),
            tipAmount: Value(record.getDoubleValue('tipAmount')),
            taxNumber: Value(record.getStringValue('taxNumber')),
            completedAt: Value(
              msgDateToDateTime(record.getStringValue('completedAt')),
            ),
          ),
        );

    // If we want to sync items, we probably need to query the `order_items` collection filtering by this order ID.
    // Or if they are embedded in a JSON field 'itemsJson':
    // final items = record.data['items'] ...
  }

  Future<void> _upsertOrderItem(RecordModel record) async {
    // We need orderId (local int) and menuItemId (local int)
    final orderRemoteId = record.getStringValue('order');
    final menuItemRemoteId = record.getStringValue('menuItem');

    final order = await (db.select(
      db.orders,
    )..where((t) => t.remoteId.equals(orderRemoteId))).getSingleOrNull();
    final menuItem = await (db.select(
      db.menuItems,
    )..where((t) => t.remoteId.equals(menuItemRemoteId))).getSingleOrNull();

    if (order == null || menuItem == null) {
      // Dependencies not synced yet.
      return;
    }

    await db
        .into(db.orderItems)
        .insertOnConflictUpdate(
          OrderItemsCompanion(
            remoteId: Value(record.id),
            orderId: Value(order.id),
            menuItemId: Value(menuItem.id),
            quantity: Value(record.getIntValue('quantity')),
            priceAtTime: Value(record.getDoubleValue('priceAtTime')),
            status: Value(record.getStringValue('status')),
          ),
        );
  }

  DateTime? msgDateToDateTime(String? date) {
    if (date == null || date.isEmpty) return null;
    return DateTime.tryParse(date);
  }

  // --- Upstream Push Methods ---

  Future<void> createOrder(int localOrderId) async {
    // 1. Fetch Local Order & Items
    final order = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(localOrderId))).getSingleOrNull();
    if (order == null) return;

    final items = await (db.select(
      db.orderItems,
    )..where((t) => t.orderId.equals(localOrderId))).get();

    // 2. Create Order in PB
    final body = {
      'orderNumber': order.orderNumber,
      'tableNumber': order.tableNumber,
      'type': order.type,
      'status': order.status,
      'totalAmount': order.totalAmount,
      'taxAmount': order.taxAmount,
      'serviceAmount': order.serviceAmount,
      'paymentMethod': order.paymentMethod,
      'tipAmount': order.tipAmount,
      'taxNumber': order.taxNumber,
    };

    try {
      final record = await pbService.create('orders', body);

      // 3. Update local ID to link with remote
      await (db.update(db.orders)..where((t) => t.id.equals(localOrderId)))
          .write(OrdersCompanion(remoteId: Value(record.id)));

      // 4. Create Items in PB (Separate collection 'order_items')
      for (var item in items) {
        // Need to find remoteId for menuItem
        final menuItem = await (db.select(
          db.menuItems,
        )..where((t) => t.id.equals(item.menuItemId))).getSingleOrNull();

        if (menuItem?.remoteId == null) continue;

        final itemRecord = await pbService.create('order_items', {
          'order': record.id,
          'menuItem': menuItem!.remoteId,
          'quantity': item.quantity,
          'priceAtTime': item.priceAtTime,
          'status': item.status,
        });

        // Update local item remoteId
        await (db.update(db.orderItems)..where((t) => t.id.equals(item.id)))
            .write(OrderItemsCompanion(remoteId: Value(itemRecord.id)));
      }
    } catch (e) {
      debugPrint('Failed to push order to PB: $e');
      // rethrow;
    }
  }

  Future<void> updateOrderStatus(int localId, String status) async {
    final order = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(localId))).getSingleOrNull();
    if (order?.remoteId == null) return;

    await pbService.update('orders', order!.remoteId!, {'status': status});
  }

  Future<void> updateOrderItemStatus(int localItemId, String status) async {
    final item = await (db.select(
      db.orderItems,
    )..where((t) => t.id.equals(localItemId))).getSingleOrNull();
    if (item?.remoteId == null) return;

    await pbService.update('order_items', item!.remoteId!, {'status': status});
  }

  // Menu Sync Methods

  Future<void> createCategory(CategoriesCompanion category, int localId) async {
    final body = {
      'name': category.name.value,
      'menuType': category.menuType.value,
      'sortOrder': category.sortOrder.value,
      'station': category.station.present ? category.station.value : null,
      'status': category.status.present ? category.status.value : 'active',
    };

    await pbService.create('categories', body);

    // Update local remoteId. We need to find the local record first.
    // Actually, usually this is called AFTER local insert, so we might have the ID.
    // But the signature returns Future<int>, implying it might be doing the insert?
    // In the previous code, it returned response.data['id'].
    // Here we should probably just return 0 or the local ID if we had it.
    // Let's assume the caller handles local insert, or we do it here.
    // The previous implementation sent to server then returned ID.
    // return 0; // Removed as return type is void
  }

  Future<void> updateCategory(Category category) async {
    if (category.remoteId == null) return;
    final body = {
      'name': category.name,
      'menuType': category.menuType,
      'sortOrder': category.sortOrder,
      'station': category.station,
      'status': category.status,
    };
    await pbService.update('categories', category.remoteId!, body);
  }

  Future<void> deleteCategoryUpstream(int localId) async {
    final category = await (db.select(
      db.categories,
    )..where((t) => t.id.equals(localId))).getSingleOrNull();
    if (category?.remoteId != null) {
      await pbService.delete('categories', category!.remoteId!);
    }
  }

  Future<void> createMenuItem(MenuItemsCompanion item, int localId) async {
    // We need category remoteId
    final category = await (db.select(
      db.categories,
    )..where((t) => t.id.equals(item.categoryId.value))).getSingleOrNull();
    if (category?.remoteId == null) throw Exception("Category not synced yet");

    final body = {
      'code': item.code.present ? item.code.value : null,
      'name': item.name.value,
      'price': item.price.value,
      'category': category!.remoteId, // Relations use ID in PB
      'station': item.station.present ? item.station.value : 'kitchen',
      'type': item.type.present ? item.type.value : 'dine-in',
      'status': item.status.present ? item.status.value : 'active',
      'allowPriceEdit': item.allowPriceEdit.present
          ? item.allowPriceEdit.value
          : false,
    };

    try {
      final record = await pbService.create('menu_items', body);

      await (db.update(db.menuItems)..where((t) => t.id.equals(localId))).write(
        MenuItemsCompanion(remoteId: Value(record.id)),
      );
    } catch (e) {
      if (e is ClientException) {
        debugPrint('PB Error Response: ${e.response}');
      }
      debugPrint('Failed to create menu item upstream: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    if (item.remoteId == null) return;

    final category = await (db.select(
      db.categories,
    )..where((t) => t.id.equals(item.categoryId))).getSingleOrNull();

    final body = {
      'code': item.code,
      'name': item.name,
      'price': item.price,
      'category': category?.remoteId,
      'station': item.station,
      'type': item.type,
      'status': item.status,
      'allowPriceEdit': item.allowPriceEdit,
    };
    await pbService.update('menu_items', item.remoteId!, body);
  }

  Future<void> deleteMenuItemUpstream(int localId) async {
    final item = await (db.select(
      db.menuItems,
    )..where((t) => t.id.equals(localId))).getSingleOrNull();
    if (item?.remoteId != null) {
      await pbService.delete('menu_items', item!.remoteId!);
    }
  }

  Future<void> _upsertPayment(RecordModel record) async {
    final orderRemoteId = record.getStringValue('order');
    final order = await (db.select(
      db.orders,
    )..where((t) => t.remoteId.equals(orderRemoteId))).getSingleOrNull();

    if (order == null) return;

    await db
        .into(db.payments)
        .insertOnConflictUpdate(
          PaymentsCompanion(
            remoteId: Value(record.id),
            orderId: Value(order.id),
            amount: Value(record.getDoubleValue('amount')),
            method: Value(record.getStringValue('method')),
            status: Value(record.getStringValue('status')),
            itemsJson: Value(record.getStringValue('itemsJSON')),
          ),
        );
  }

  // Stubs for complex order actions to satisfy linter
  Future<void> payItems(
    int orderId,
    List<Map<String, dynamic>> items,
    String method,
  ) async {
    // 1. Get Order
    final order = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(orderId))).getSingleOrNull();
    if (order?.remoteId == null) {
      debugPrint("Cannot pay items: Order not synced or does not exist");
      return;
    }

    // 2. Calculate Total for these items
    double amount = 0;
    // We also need to mark these items as paid in order_items
    for (var itemData in items) {
      final itemId = itemData['id'] as int;
      final qty =
          itemData['quantity']
              as int; // Part of payment logic if needed, but for now we mark whole item or we need split logic

      final item = await (db.select(
        db.orderItems,
      )..where((t) => t.id.equals(itemId))).getSingleOrNull();
      if (item != null && item.remoteId != null) {
        amount += item.priceAtTime * qty;

        // If fully paid (quantity matches), update status
        if (qty >= item.quantity) {
          await pbService.update('order_items', item.remoteId!, {
            'status': 'paid',
          });
          // Also update local? Handled by sync usually, but optimistic update is good
        }
        // Use 'itemsJSON' to store what was paid in this transaction
      }
    }

    // 3. Create Payment Record
    await pbService.create('payments', {
      'order': order!.remoteId,
      'amount': amount,
      'method': method,
      'status': 'completed',
      'itemsJSON': items, // Storing what we paid for
    });
  }

  Future<void> addPayment(int orderId, double amount, String method) async {
    // Simple payment (e.g. split by people)
    final order = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(orderId))).getSingleOrNull();
    if (order?.remoteId == null) return;

    await pbService.create('payments', {
      'order': order!.remoteId,
      'amount': amount,
      'method': method,
      'status': 'completed',
    });

    // Check if total paid >= order total, then mark order as paid
    // This requires fetching all payments for this order.
    // For now, we rely on backend or client to check this.
  }

  Future<void> splitTable(
    String orderNumber,
    String targetTable,
    List<Map<String, dynamic>> items, {
    String? newOrderNumber,
  }) async {
    // Logic:
    // 1. Find source order
    // 2. Create new order for target table (if newOrderNumber provided) or find existing
    // 3. Move items to new order
    // For PB: We update 'order' field of the order_items.

    // This is complex. For now, let's implement basic item moving.
    debugPrint(
      "splitTable logic involves moving items between orders. Not fully implemented in this pass.",
    );
  }

  Future<void> mergeTables(String fromTable, String intoTable) async {
    // Logic:
    // 1. Find all orders for fromTable
    // 2. Update their tableNumber to intoTable
    // 3. Merge orders if needed? Or just keep multiple orders on one table.

    // Simplest: Update tableNumber for all active orders on fromTable
    final records = await pbService.pb
        .collection('orders')
        .getList(
          filter:
              'tableNumber = "$fromTable" && status != "completed" && status != "paid"',
        );

    for (var record in records.items) {
      await pbService.update('orders', record.id, {'tableNumber': intoTable});
    }
  }
}
