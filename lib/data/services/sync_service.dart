import 'package:flutter/foundation.dart' hide Category;
import 'package:pocketbase/pocketbase.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/services/pocketbase_service.dart';
import 'package:drift/drift.dart';

class SyncService {
  final AppDatabase db;
  final PocketBaseService pbService;

  SyncService(this.db, this.pbService) {
    initRealtimeUpdates();
  }

  void initRealtimeUpdates() {
    // Subscribe to all relevant collections for realtime UI updates
    pbService.subscribe('orders', (e) => _handleRealtimeEvent(e, 'orders'));
    pbService.subscribe(
      'restaurant_tables',
      (e) => _handleRealtimeEvent(e, 'restaurant_tables'),
    );
    pbService.subscribe(
      'categories',
      (e) => _handleRealtimeEvent(e, 'categories'),
    );
    pbService.subscribe('printers', (e) => _handleRealtimeEvent(e, 'printers'));
    pbService.subscribe(
      'menu_items',
      (e) => _handleRealtimeEvent(e, 'menu_items'),
    );
    pbService.subscribe('settings', (e) => _handleRealtimeEvent(e, 'settings'));
    pbService.subscribe('users', (e) => _handleRealtimeEvent(e, 'users'));
    pbService.subscribe(
      'order_items',
      (e) => _handleRealtimeEvent(e, 'order_items'),
    );
    pbService.subscribe('payments', (e) => _handleRealtimeEvent(e, 'payments'));
  }

  Future<void> dispose() async {
    await pbService.unsubscribe('orders');
    await pbService.unsubscribe('restaurant_tables');
    await pbService.unsubscribe('categories');
    await pbService.unsubscribe('printers');
    await pbService.unsubscribe('menu_items');
    await pbService.unsubscribe('settings');
    await pbService.unsubscribe('users');
    await pbService.unsubscribe('order_items');
    await pbService.unsubscribe('payments');
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

  Future<bool> syncAll() async {
    try {
      debugPrint('Starting initial online fetch...');
      // Check connection first
      final isConnected = await pbService.checkConnection();
      if (!isConnected) {
        debugPrint('Sync failed: No connection to server');
        return false;
      }

      await _syncCollection('restaurant_tables');
      await _syncCollection('categories');
      await _syncCollection('printers');
      await _syncCollection('menu_items');
      await _syncCollection('settings');
      await _syncCollection('users');
      await _syncCollection('orders');
      await _syncCollection('order_items');
      await _syncCollection('payments');
      debugPrint('Initial fetch completed successfully');
      return true;
    } catch (e) {
      debugPrint('Initial fetch failed: $e');
      return false;
    }
  }

  Future<void> _syncCollection(String collection) async {
    try {
      final records = await pbService.getFullList(collection);
      final remoteIds = records.map((e) => e.id).toList();

      // Cleanup local mirror
      await _deleteLocalNotInRemote(collection, remoteIds);

      // Update local mirror
      for (var record in records) {
        await _upsertLocal(collection, record);
      }
    } catch (e) {
      debugPrint('Failed to sync collection $collection: $e');
    }
  }

  Future<void> _deleteLocalNotInRemote(
    String collection,
    List<String> remoteIds,
  ) async {
    switch (collection) {
      case 'restaurant_tables':
        await (db.delete(db.restaurantTables)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'categories':
        await (db.delete(db.categories)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'menu_items':
        await (db.delete(db.menuItems)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'printers':
        await (db.delete(db.printers)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'settings':
        await (db.delete(db.settings)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'orders':
        await (db.delete(db.orders)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'users':
        await (db.delete(db.users)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'order_items':
        await (db.delete(db.orderItems)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
        break;
      case 'payments':
        await (db.delete(db.payments)..where(
              (t) => t.remoteId.isNotIn(remoteIds) & t.remoteId.isNotNull(),
            ))
            .go();
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
      case 'printers':
        await (db.delete(
          db.printers,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'settings':
        await (db.delete(
          db.settings,
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
      case 'order_items':
        await (db.delete(
          db.orderItems,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
      case 'payments':
        await (db.delete(
          db.payments,
        )..where((t) => t.remoteId.equals(remoteId))).go();
        break;
    }
  }

  Future<void> _upsertLocal(String collection, RecordModel record) async {
    switch (collection) {
      case 'restaurant_tables':
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
        break;
      case 'categories':
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
        break;
      case 'menu_items':
        final catRemoteId = record.getStringValue('category');
        final cat = await (db.select(
          db.categories,
        )..where((t) => t.remoteId.equals(catRemoteId))).getSingleOrNull();
        if (cat != null) {
          await db
              .into(db.menuItems)
              .insertOnConflictUpdate(
                MenuItemsCompanion(
                  remoteId: Value(record.id),
                  code: Value(record.getStringValue('code')),
                  name: Value(record.getStringValue('name')),
                  price: Value(record.getDoubleValue('price')),
                  categoryId: Value(cat.id),
                  station: Value(record.getStringValue('station')),
                  type: Value(record.getStringValue('type')),
                  status: Value(record.getStringValue('status')),
                  allowPriceEdit: Value(record.getBoolValue('allowPriceEdit')),
                ),
              );
        }
        break;
      case 'orders':
        final waiterRemoteId = record.getStringValue('waiter');
        int? waiterId;
        if (waiterRemoteId.isNotEmpty) {
          final waiter = await (db.select(
            db.users,
          )..where((u) => u.remoteId.equals(waiterRemoteId))).getSingleOrNull();
          waiterId = waiter?.id;
        }
        await db
            .into(db.orders)
            .insertOnConflictUpdate(
              OrdersCompanion(
                remoteId: Value(record.id),
                orderNumber: Value(record.getStringValue('orderNumber')),
                tableNumber: Value(record.getStringValue('tableNumber')),
                type: Value(record.getStringValue('type')),
                waiterId: Value(waiterId),
                status: Value(record.getStringValue('status')),
                totalAmount: Value(record.getDoubleValue('totalAmount')),
                taxAmount: Value(record.getDoubleValue('taxAmount')),
                serviceAmount: Value(record.getDoubleValue('serviceAmount')),
                paymentMethod: Value(record.getStringValue('paymentMethod')),
                tipAmount: Value(record.getDoubleValue('tipAmount')),
                taxNumber: Value(record.getStringValue('taxNumber')),
                createdAt: Value(
                  DateTime.parse(record.getStringValue('created')),
                ),
                completedAt: record.getStringValue('completedAt').isNotEmpty
                    ? Value(
                        DateTime.parse(record.getStringValue('completedAt')),
                      )
                    : const Value.absent(),
              ),
            );
        break;
      case 'order_items':
        final orderRemoteId = record.getStringValue('order');
        final menuRemoteId = record.getStringValue('menuItem');
        final order = await (db.select(
          db.orders,
        )..where((o) => o.remoteId.equals(orderRemoteId))).getSingleOrNull();
        final menu = await (db.select(
          db.menuItems,
        )..where((m) => m.remoteId.equals(menuRemoteId))).getSingleOrNull();
        if (order != null && menu != null) {
          await db
              .into(db.orderItems)
              .insertOnConflictUpdate(
                OrderItemsCompanion(
                  remoteId: Value(record.id),
                  orderId: Value(order.id),
                  menuItemId: Value(menu.id),
                  quantity: Value(record.getIntValue('quantity')),
                  priceAtTime: Value(record.getDoubleValue('priceAtTime')),
                  status: Value(record.getStringValue('status')),
                ),
              );
        }
        break;
      case 'users':
        await db
            .into(db.users)
            .insertOnConflictUpdate(
              UsersCompanion(
                remoteId: Value(record.id),
                email: Value(record.getStringValue('email')),
                username: Value(record.getStringValue('username')),
                fullName: Value(record.getStringValue('name')),
                role: Value(record.getStringValue('role')),
                pin: Value(record.getStringValue('pin')),
                status: Value(record.getStringValue('status')),
              ),
            );
        break;
      case 'printers':
        await db
            .into(db.printers)
            .insertOnConflictUpdate(
              PrintersCompanion(
                remoteId: Value(record.id),
                name: Value(record.getStringValue('name')),
                macAddress: Value(record.getStringValue('macAddress')),
                role: Value(record.getStringValue('role')),
                status: Value(record.getStringValue('status')),
              ),
            );
        break;
      case 'settings':
        await db
            .into(db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion(
                remoteId: Value(record.id),
                taxRate: Value(record.getDoubleValue('taxRate')),
                serviceRate: Value(record.getDoubleValue('serviceRate')),
                currencySymbol: Value(record.getStringValue('currencySymbol')),
                kioskMode: Value(record.getBoolValue('kioskMode')),
                orderDelayThreshold: Value(
                  record.getIntValue('orderDelayThreshold'),
                ),
              ),
            );
        break;
    }
  }
}
