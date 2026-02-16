import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';
import 'package:pos_system/data/services/sync_provider.dart';
import 'package:pos_system/data/services/sync_service.dart';

part 'order_repository.g.dart';

class OrderRepository {
  final AppDatabase db;
  final SyncService syncService;

  OrderRepository(this.db, this.syncService);

  Future<int> createOrder(OrdersCompanion order) =>
      db.into(db.orders).insert(order);

  Future<void> addOrderItems(List<OrderItemsCompanion> items) async {
    await db.batch((batch) {
      batch.insertAll(db.orderItems, items);
    });
  }

  Future<void> submitOrder({
    required OrdersCompanion order,
    required List<OrderItemsCompanion> items,
  }) async {
    // Local-First: Insert locally
    final orderId = await db.into(db.orders).insert(order);

    final itemsWithOrderId = items
        .map((i) => i.copyWith(orderId: Value(orderId)))
        .toList();
    await db.batch((batch) {
      batch.insertAll(db.orderItems, itemsWithOrderId);
    });

    // Sync
    syncService.createOrder(orderId).ignore();
  }

  Future<void> updateOrderItemStatus(int itemId, String status) async {
    await (db.update(db.orderItems)..where((t) => t.id.equals(itemId))).write(
      OrderItemsCompanion(status: Value(status)),
    );
    syncService.updateOrderItemStatus(itemId, status).ignore();
  }

  Stream<List<Order>> watchActiveOrders() {
    return (db.select(db.orders)
          ..where(
            (t) => t.status.isIn([
              'pending',
              'sent',
              'accepted',
              'cooking',
              'ready',
            ]),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<OrderWithDetails>> watchActiveTables() {
    // This is a bit complex, we need to join orders and items to get totals and counts per table
    // For now, let's just get active orders and group them in memory or use a simpler query
    // Actually, tables view needs: Table Number, # of orders, Total Amount.
    // We can just query active orders.
    return (db.select(db.orders)..where(
          (t) => t.status.isNotIn(['paid', 'cancelled', 'completed']),
        ) // Assuming 'paid' clears the table
        )
        .watch()
        .map((orders) async {
          // We might need to fetch items for each order to calculate total if it's not stored in order table yet
          // But our schema has totalAmount in Orders table.
          // Let's assume totalAmount is updated when items are added.
          return []; // Placeholder for complex return type, implementing simpler below
        })
        .asyncMap((_) => _getActiveTablesWithDetails());
  }

  Future<List<Order>> getOrdersByTable(String tableNumber) {
    return (db.select(db.orders)..where(
          (t) =>
              t.tableNumber.equals(tableNumber) &
              t.status.isNotIn(['paid', 'cancelled']),
        ))
        .get();
  }

  Future<List<OrderWithDetails>> getOrdersWithDetailsByTable(
    String tableNumber,
  ) async {
    final query =
        db.select(db.orders).join([
          leftOuterJoin(
            db.orderItems,
            db.orderItems.orderId.equalsExp(db.orders.id),
          ),
          leftOuterJoin(
            db.menuItems,
            db.menuItems.id.equalsExp(db.orderItems.menuItemId),
          ),
        ])..where(
          db.orders.tableNumber.equals(tableNumber) &
              db.orders.status.isNotIn(['paid', 'cancelled']),
        );

    final rows = await query.get();
    final grouped = <int, OrderWithDetails>{};

    for (final row in rows) {
      final order = row.readTable(db.orders);
      final orderItem = row.readTableOrNull(db.orderItems);
      final menuItem = row.readTableOrNull(db.menuItems);

      if (!grouped.containsKey(order.id)) {
        grouped[order.id] = OrderWithDetails(order, []);
      }

      if (orderItem != null && menuItem != null) {
        grouped[order.id]!.items.add(OrderItemWithMenu(orderItem, menuItem));
      }
    }

    return grouped.values.toList();
  }

  Stream<List<Order>> watchAllOrders() {
    return (db.select(db.orders)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Stream<List<Order>> watchPaidOrders() {
    return (db.select(db.orders)
          ..where((t) => t.status.equals('paid'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> updateOrderStatus(int id, String status) async {
    // Online-First: Sync upstream
    await syncService.updateOrderStatus(id, status);
  }

  Future<void> markOrdersAsPaid(List<int> orderIds) async {
    // Online-First: Sync each order status change
    await Future.wait(
      orderIds.map((id) => syncService.updateOrderStatus(id, 'paid')),
    );
  }

  // Watch orders for a specific station (kitchen/bar)
  Stream<List<OrderWithDetails>> watchOrdersByStation(String station) {
    // We want all active orders that have at least one item for this station
    final query =
        db.select(db.orders).join([
            innerJoin(
              db.orderItems,
              db.orderItems.orderId.equalsExp(db.orders.id),
            ),
            innerJoin(
              db.menuItems,
              db.menuItems.id.equalsExp(db.orderItems.menuItemId),
            ),
          ])
          ..where(
            db.orders.status.isIn([
                  'pending',
                  'sent',
                  'accepted',
                  'cooking',
                  'ready',
                ]) &
                db.menuItems.station.equals(station),
          )
          ..orderBy([
            OrderingTerm(
              expression: db.orders.createdAt,
              mode: OrderingMode.asc,
            ),
          ]);

    return query.watch().map((rows) {
      // Group by Order
      final grouped = <int, OrderWithDetails>{};

      for (final row in rows) {
        final order = row.readTable(db.orders);
        final orderItem = row.readTable(db.orderItems);
        final menuItem = row.readTable(db.menuItems);

        if (!grouped.containsKey(order.id)) {
          grouped[order.id] = OrderWithDetails(order, []);
        }
        grouped[order.id]!.items.add(OrderItemWithMenu(orderItem, menuItem));
      }

      return grouped.values.toList();
    });
  }

  // Watch ALL active orders with items (for general view if needed)
  Stream<List<OrderWithDetails>> watchAllActiveOrdersWithItems() {
    final query =
        db.select(db.orders).join([
            innerJoin(
              db.orderItems,
              db.orderItems.orderId.equalsExp(db.orders.id),
            ),
            innerJoin(
              db.menuItems,
              db.menuItems.id.equalsExp(db.orderItems.menuItemId),
            ),
          ])
          ..where(
            db.orders.status.isIn([
              'pending',
              'sent',
              'accepted',
              'cooking',
              'ready',
            ]),
          )
          ..orderBy([
            OrderingTerm(
              expression: db.orders.createdAt,
              mode: OrderingMode.asc,
            ),
          ]);

    return query.watch().map((rows) {
      final grouped = <int, OrderWithDetails>{};

      for (final row in rows) {
        final order = row.readTable(db.orders);
        final orderItem = row.readTable(db.orderItems);
        final menuItem = row.readTable(db.menuItems);

        if (!grouped.containsKey(order.id)) {
          grouped[order.id] = OrderWithDetails(order, []);
        }
        grouped[order.id]!.items.add(OrderItemWithMenu(orderItem, menuItem));
      }

      return grouped.values.toList();
    });
  }

  // Helper to get active orders with details
  Future<List<OrderWithDetails>> _getActiveTablesWithDetails() async {
    return [];
  }

  Future<void> payItems(
    int orderId,
    List<Map<String, dynamic>> items,
    String method,
  ) async {
    await syncService.payItems(orderId, items, method);
    // Local DB update will happen via socket event usually,
    // but we could optimistically update local DB here if we wanted.
    // For now rely on sync.
  }

  Future<void> addPayment(int orderId, double amount, String method) async {
    await syncService.addPayment(orderId, amount, method);
  }

  Future<void> splitTable(
    int orderId,
    String targetTable,
    List<Map<String, dynamic>> items,
  ) async {
    final currentOrder = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(orderId))).getSingle();

    // Online-First: Direct API call
    await syncService.splitTable(
      currentOrder.orderNumber,
      targetTable,
      items,
      newOrderNumber: null, // Let backend generate it
    );
  }

  Future<void> mergeTables(String fromTable, String toTable) async {
    await syncService.mergeTables(fromTable, toTable);
  }
}

class OrderItemWithMenu {
  final OrderItem item;
  final MenuItem menu;

  OrderItemWithMenu(this.item, this.menu);
}

class OrderWithDetails {
  final Order order;
  final List<OrderItemWithMenu> items;

  OrderWithDetails(this.order, this.items);
}

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  return OrderRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
}
