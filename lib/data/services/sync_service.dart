import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_system/data/database/database.dart';

class SyncService {
  final AppDatabase db;
  final Dio dio;
  final String baseUrl; // http://localhost:3000

  SyncService(this.db, {String? baseUrl})
    : dio = Dio(),
      baseUrl = baseUrl ?? 'http://192.168.1.71:3000';

  Future<void> syncAll() async {
    try {
      await syncTables();
      await syncCategories();
      await syncMenuItems();
      await syncOrders();
      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> syncTables() async {
    final response = await dio.get('$baseUrl/tables');
    final List<dynamic> data = response.data;

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.restaurantTables,
        data.map(
          (json) => RestaurantTablesCompanion(
            id: Value(json['id']),
            name: Value(json['name']),
            status: Value(json['status']),
            x: Value(json['x']),
            y: Value(json['y']),
          ),
        ),
      );
    });
  }

  Future<void> syncCategories() async {
    final response = await dio.get('$baseUrl/categories');
    final List<dynamic> data = response.data;

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.categories,
        data.map(
          (json) => CategoriesCompanion(
            id: Value(json['id']),
            name: Value(json['name']),
            menuType: Value(json['menuType']),
            sortOrder: Value(json['sortOrder']),
            station: Value(json['station']),
            status: Value(json['status']),
          ),
        ),
      );
    });
  }

  Future<void> syncMenuItems() async {
    final response = await dio.get('$baseUrl/menu-items');
    final List<dynamic> data = response.data;

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.menuItems,
        data.map(
          (json) => MenuItemsCompanion(
            id: Value(json['id']),
            code: Value(json['code']),
            name: Value(json['name']),
            price: Value(json['price'].toDouble()),
            categoryId: Value(json['categoryId']),
            station: Value(json['station']),
            type: Value(json['type']),
            status: Value(json['status']),
            allowPriceEdit: Value(json['allowPriceEdit']),
          ),
        ),
      );
    });
  }

  Future<void> syncOrders() async {
    final response = await dio.get('$baseUrl/orders');
    final List<dynamic> data = response.data;

    // For orders, we might need more complex logic, but for now specific upsert
    // Note: This matches the basic structure. Full deep sync might require handling items separately.
    for (var json in data) {
      await db
          .into(db.orders)
          .insertOnConflictUpdate(
            OrdersCompanion(
              id: Value(json['id']),
              orderNumber: Value(json['orderNumber']),
              tableNumber: Value(json['tableNumber']),
              type: Value(json['type']),
              // waiterId: Value(json['waiterId']), // nullable
              status: Value(json['status']),
              totalAmount: Value(json['totalAmount'].toDouble()),
              // ... map other fields
            ),
          );
    }
  }

  Future<void> createOrder(
    OrdersCompanion order,
    List<OrderItemsCompanion> items,
  ) async {
    try {
      final orderJson = {
        'orderNumber': order.orderNumber.value,
        'tableNumber': order.tableNumber.value,
        'type': order.type.value,
        'status': order.status.value,
        'totalAmount': order.totalAmount.value,
        'items': items
            .map(
              (i) => {
                'menuItemId': i.menuItemId.value,
                'quantity': i.quantity.value,
                'priceAtTime': i.priceAtTime.value,
              },
            )
            .toList(),
      };
      await dio.post('$baseUrl/orders', data: orderJson);
    } catch (e) {
      debugPrint('Failed to sync order upstream: $e');
    }
  }

  Future<void> updateTableStatus(int id, String status) async {
    try {
      await dio.put('$baseUrl/tables/$id', data: {'status': status});
    } catch (e) {
      debugPrint('Failed to sync table status upstream: $e');
    }
  }
}
