import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:pos_system/data/database/database.dart';

class SyncService {
  final AppDatabase db;
  final Dio dio;
  final String baseUrl; // http://localhost:3000
  late socket_io.Socket socket;

  final List<Map<String, dynamic>> _retryQueue = [];
  bool _isProcessingQueue = false;

  SyncService(this.db, {String? baseUrl})
    : dio = Dio(),
      baseUrl = baseUrl ?? 'http://localhost:3000' {
    initRealtimeUpdates();
  }

  void initRealtimeUpdates() {
    // Connect to the /sync namespace
    socket = socket_io.io('$baseUrl/sync', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      debugPrint('Connected to WebSocket server');
      _processRetryQueue();
    });

    socket.onDisconnect(
      (_) => debugPrint('Disconnected from WebSocket server'),
    );

    socket.on('order:new', (data) => upsertOrder(data));
    socket.on('order:update', (data) => upsertOrder(data));
    socket.on('order:delete', (data) => deleteOrder(data));
    socket.on('table:update', (data) => upsertRestaurantTable(data));
    socket.on('category:update', (data) => upsertCategory(data));
    socket.on('menu-item:update', (data) => upsertMenuItem(data));
    socket.on('user:update', (data) => upsertUser(data));
  }

  Future<void> _processRetryQueue() async {
    if (_retryQueue.isEmpty || _isProcessingQueue) return;
    _isProcessingQueue = true;
    debugPrint('Processing retry queue: ${_retryQueue.length} items');

    // Copy queue to iterate safely
    final queueCopy = List<Map<String, dynamic>>.from(_retryQueue);
    _retryQueue
        .clear(); // Clear main queue; failed items will re-add themselves

    for (var item in queueCopy) {
      try {
        if (item['action'] == 'splitTable') {
          final p = item['payload'];
          await splitTable(
            p['orderNumber'],
            p['targetTable'],
            p['items'],
            newOrderNumber: p['newOrderNumber'],
          );
        }
      } catch (e) {
        debugPrint('Retry failed for item: $e');
      }
    }
    _isProcessingQueue = false;
  }

  Future<void> syncAll() async {
    try {
      // 1. Fetch all data first
      final tableRes = await dio.get('$baseUrl/api/v1/tables');
      final catRes = await dio.get('$baseUrl/api/v1/categories');
      final itemRes = await dio.get('$baseUrl/api/v1/menu-items');
      final orderRes = await dio.get('$baseUrl/api/v1/orders/sync');
      final userRes = await dio.get('$baseUrl/api/v1/users');

      final tableData = tableRes.data as List<dynamic>;
      final catData = catRes.data as List<dynamic>;
      final itemData = itemRes.data as List<dynamic>;
      final orderData = orderRes.data as List<dynamic>;
      final userData = userRes.data as List<dynamic>;

      // 2. Perform Cleanups (Children First -> Parents Last)
      // This prevents FK violations (e.g. deleting a category used by an item)

      await _cleanupOrders(orderData);
      await _cleanupMenuItems(itemData);
      await _cleanupCategories(catData);
      await _cleanupTables(tableData);

      // 3. Perform Upserts (Parents First -> Children Last)
      await _upsertTablesBatch(tableData);
      await _upsertCategoriesBatch(catData);
      await _upsertMenuItemsBatch(itemData);
      await _upsertOrdersBatch(orderData);
      await _upsertUsersBatch(userData);

      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  // --- Helper Methods ---

  Future<void> _cleanupOrders(List<dynamic> serverData) async {
    final serverIds = serverData.map((e) => e['id'] as int).toList();
    final ordersToDelete = await (db.select(
      db.orders,
    )..where((t) => t.id.isNotIn(serverIds))).get();
    for (var order in ordersToDelete) {
      // Manually delete items to ensure clean removal
      await (db.delete(
        db.orderItems,
      )..where((t) => t.orderId.equals(order.id))).go();
      await db.delete(db.orders).delete(order);
    }
  }

  Future<void> _cleanupMenuItems(List<dynamic> serverData) async {
    final serverIds = serverData.map((e) => e['id'] as int).toList();
    // First delete order_items that reference menu items being deleted
    await (db.delete(
      db.orderItems,
    )..where((t) => t.menuItemId.isNotIn(serverIds))).go();
    // Then delete the menu items
    await (db.delete(db.menuItems)..where((t) => t.id.isNotIn(serverIds))).go();
  }

  Future<void> _cleanupCategories(List<dynamic> serverData) async {
    final serverIds = serverData.map((e) => e['id'] as int).toList();
    await (db.delete(
      db.categories,
    )..where((t) => t.id.isNotIn(serverIds))).go();
  }

  Future<void> _cleanupTables(List<dynamic> serverData) async {
    final serverIds = serverData.map((e) => e['id'] as int).toList();
    await (db.delete(
      db.restaurantTables,
    )..where((t) => t.id.isNotIn(serverIds))).go();
  }

  Future<void> _upsertTablesBatch(List<dynamic> data) async {
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

  Future<void> _upsertCategoriesBatch(List<dynamic> data) async {
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

  Future<void> _upsertMenuItemsBatch(List<dynamic> data) async {
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

  Future<void> _upsertOrdersBatch(List<dynamic> data) async {
    for (var json in data) {
      await upsertOrder(json);
    }
  }

  Future<void> _upsertUsersBatch(List<dynamic> data) async {
    for (var json in data) {
      await upsertUser(json);
    }
  }

  // Wrappers
  Future<void> syncTables() async {
    final response = await dio.get('$baseUrl/api/v1/tables');
    final data = response.data as List<dynamic>;
    await _cleanupTables(data);
    await _upsertTablesBatch(data);
  }

  Future<void> syncCategories() async {
    final response = await dio.get('$baseUrl/api/v1/categories');
    final data = response.data as List<dynamic>;
    await _cleanupCategories(data);
    await _upsertCategoriesBatch(data);
  }

  Future<void> syncMenuItems() async {
    final response = await dio.get('$baseUrl/api/v1/menu-items');
    final data = response.data as List<dynamic>;
    await _cleanupMenuItems(data);
    await _upsertMenuItemsBatch(data);
  }

  Future<void> syncOrders() async {
    final response = await dio.get('$baseUrl/api/v1/orders/sync');
    final data = response.data as List<dynamic>;
    await _cleanupOrders(data);
    await _upsertOrdersBatch(data);
  }

  Future<void> syncUsers() async {
    // Users usually purely additive or status update, but we can add cleanup if stricter sync needed
    await _upsertUsersBatch((await dio.get('$baseUrl/api/v1/users')).data);
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
      await dio.post('$baseUrl/api/v1/orders', data: orderJson);
    } catch (e) {
      debugPrint('Failed to sync order upstream: $e');
    }
  }

  Future<void> updateTableStatus(int id, String status) async {
    try {
      await dio.put('$baseUrl/api/v1/tables/$id', data: {'status': status});
    } catch (e) {
      debugPrint('Failed to sync table status upstream: $e');
    }
  }

  Future<void> updateOrderStatus(int id, String status) async {
    try {
      await dio.put('$baseUrl/api/v1/orders/$id', data: {'status': status});
    } catch (e) {
      debugPrint('Failed to sync order status upstream: $e');
    }
  }

  Future<void> payItems(
    int orderId,
    List<Map<String, dynamic>> items,
    String method,
  ) async {
    try {
      await dio.post(
        '$baseUrl/api/v1/orders/$orderId/pay-items',
        data: {'items': items, 'paymentMethod': method},
      );
    } catch (e) {
      debugPrint('Failed to pay items upstream: $e');
      rethrow;
    }
  }

  Future<void> addPayment(int orderId, double amount, String method) async {
    try {
      await dio.post(
        '$baseUrl/api/v1/orders/$orderId/pay',
        data: {'amount': amount, 'method': method},
      );
    } catch (e) {
      debugPrint('Failed to add payment upstream: $e');
      rethrow;
    }
  }

  Future<void> splitTable(
    String orderNumber,
    String targetTable,
    List<Map<String, dynamic>> items, {
    String? newOrderNumber,
  }) async {
    try {
      await dio.post(
        '$baseUrl/api/v1/orders/$orderNumber/split-table',
        data: {
          'targetTableNumber': targetTable,
          'items': items,
          'newOrderNumber': newOrderNumber,
        },
      );
    } catch (e) {
      debugPrint('Failed to split table upstream: $e');
      // Do not rethrow, so app continues offline
    }
  }

  Future<void> mergeTables(String fromTable, String toTable) async {
    try {
      await dio.post(
        '$baseUrl/api/v1/orders/merge-tables',
        data: {'fromTableNumber': fromTable, 'toTableNumber': toTable},
      );
    } catch (e) {
      debugPrint('Failed to merge tables upstream: $e');
      rethrow;
    }
  }

  // Real-time update handlers
  Future<void> upsertRestaurantTable(Map<String, dynamic> json) async {
    await db
        .into(db.restaurantTables)
        .insertOnConflictUpdate(
          RestaurantTablesCompanion(
            id: Value(json['id']),
            name: Value(json['name']),
            status: Value(json['status']),
            x: Value(json['x']),
            y: Value(json['y']),
          ),
        );
  }

  Future<void> upsertCategory(Map<String, dynamic> json) async {
    final serverId = json['id'] as int;
    final name = json['name'] as String;

    // 1. Check if category with this ID exists (Update scenario)
    final existingById = await (db.select(
      db.categories,
    )..where((t) => t.id.equals(serverId))).getSingleOrNull();

    if (existingById != null) {
      await db
          .into(db.categories)
          .insertOnConflictUpdate(
            CategoriesCompanion(
              id: Value(json['id']),
              name: Value(json['name']),
              menuType: Value(json['menuType']),
              sortOrder: Value(json['sortOrder']),
              station: Value(json['station']),
              status: Value(json['status']),
            ),
          );
      return;
    }

    // 2. Check if category with this NAME exists (ID conflict scenario)
    // This happens when we created category locally (ID X) but server assigns ID Y.
    // We need to migrate Menu Items from X to Y, then delete X.
    final existingByName = await (db.select(
      db.categories,
    )..where((t) => t.name.equals(name))).getSingleOrNull();

    if (existingByName != null && existingByName.id != serverId) {
      debugPrint(
        'SyncService: Conflict detected for category ${existingByName.name}. Local ID: ${existingByName.id}, Server ID: $serverId. Migrating...',
      );

      await db.transaction(() async {
        // A. Migrate children (MenuItems)
        // Update menu_items set categoryId = serverId where categoryId = localId
        await (db.update(db.menuItems)
              ..where((t) => t.categoryId.equals(existingByName.id)))
            .write(MenuItemsCompanion(categoryId: Value(serverId)));

        // B. Delete the old local category
        await (db.delete(
          db.categories,
        )..where((t) => t.id.equals(existingByName.id))).go();

        // C. Insert the new server category
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion(
                id: Value(json['id']),
                name: Value(json['name']),
                menuType: Value(json['menuType']),
                sortOrder: Value(json['sortOrder']),
                station: Value(json['station']),
                status: Value(json['status']),
              ),
            );
      });
      return;
    }

    // 3. Standard Insert
    await db
        .into(db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion(
            id: Value(json['id']),
            name: Value(json['name']),
            menuType: Value(json['menuType']),
            sortOrder: Value(json['sortOrder']),
            station: Value(json['station']),
            status: Value(json['status']),
          ),
        );
  }

  Future<void> upsertMenuItem(Map<String, dynamic> json) async {
    final serverId = json['id'] as int;
    final code = json['code'] as String?;

    // 1. Check if item with this ID exists (Update scenario)
    final existingById = await (db.select(
      db.menuItems,
    )..where((t) => t.id.equals(serverId))).getSingleOrNull();

    if (existingById != null) {
      await db
          .into(db.menuItems)
          .insertOnConflictUpdate(
            MenuItemsCompanion(
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
          );
      return;
    }

    // 2. Check if item with this CODE exists (ID conflict scenario)
    // This happens when we created item locally (ID X) but server assigns ID Y.
    // We need to migrate local dependencies from X to Y, then delete X.
    if (code != null) {
      final existingByCode = await (db.select(
        db.menuItems,
      )..where((t) => t.code.equals(code))).getSingleOrNull();

      if (existingByCode != null && existingByCode.id != serverId) {
        debugPrint(
          'SyncService: Conflict detected for item ${existingByCode.name} (Code: $code). Local ID: ${existingByCode.id}, Server ID: $serverId. Migrating...',
        );

        await db.transaction(() async {
          // A. Migrate dependencies (OrderItems)
          // Update order_items set menuItemId = serverId where menuItemId = localId
          await (db.update(db.orderItems)
                ..where((t) => t.menuItemId.equals(existingByCode.id)))
              .write(OrderItemsCompanion(menuItemId: Value(serverId)));

          // B. Delete the old local item
          await (db.delete(
            db.menuItems,
          )..where((t) => t.id.equals(existingByCode.id))).go();

          // C. Insert the new server item
          await db
              .into(db.menuItems)
              .insert(
                MenuItemsCompanion(
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
              );
        });
        return;
      }
    }

    // 3. Standard Insert (No conflicts)
    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion(
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
        );
  }

  Future<void> upsertOrder(Map<String, dynamic> json) async {
    final serverId = json['id'] as int;
    final orderNumber = json['orderNumber'] as String;

    // 0. Ensure Table Exists Locally (for multi-device sync)
    final tableNum = json['tableNumber'] as String?;
    if (tableNum != null) {
      final existingTable = await (db.select(
        db.restaurantTables,
      )..where((t) => t.name.equals(tableNum))).getSingleOrNull();

      if (existingTable == null) {
        await db
            .into(db.restaurantTables)
            .insert(
              RestaurantTablesCompanion(
                name: Value(tableNum),
                status: const Value('occupied'),
                x: const Value(0),
                y: const Value(0),
              ),
            );
      }
    }

    // 1. Check if Order with this ID exists (Update scenario)
    final existingById = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(serverId))).getSingleOrNull();

    if (existingById != null) {
      await _performOrderUpsert(json);
      return;
    }

    // 2. Check if Order with this NUMBER exists (ID Conflict scenario)
    // Happens when local order (temp ID) gets permanent ID from server.
    final existingByNumber = await (db.select(
      db.orders,
    )..where((t) => t.orderNumber.equals(orderNumber))).getSingleOrNull();

    if (existingByNumber != null && existingByNumber.id != serverId) {
      debugPrint(
        'SyncService: Conflict detected for Order $orderNumber. Local ID: ${existingByNumber.id}, Server ID: $serverId. Migrating...',
      );

      await db.transaction(() async {
        // A. Migrate children (OrderItems)
        // Update order_items set orderId = serverId where orderId = localId
        await (db.update(db.orderItems)
              ..where((t) => t.orderId.equals(existingByNumber.id)))
            .write(OrderItemsCompanion(orderId: Value(serverId)));

        // B. Delete the old local order
        await (db.delete(
          db.orders,
        )..where((t) => t.id.equals(existingByNumber.id))).go();

        // C. Insert the new server order (without items first to avoid composite key issues if any)
        await db
            .into(db.orders)
            .insert(
              OrdersCompanion(
                id: Value(json['id']),
                orderNumber: Value(json['orderNumber']),
                tableNumber: Value(json['tableNumber']),
                type: Value(json['type']),
                status: Value(json['status']),
                totalAmount: Value(json['totalAmount'].toDouble()),
                taxAmount: Value(json['taxAmount']?.toDouble() ?? 0.0),
                serviceAmount: Value(json['serviceAmount']?.toDouble() ?? 0.0),
                paymentMethod: Value(json['paymentMethod']),
                tipAmount: Value(json['tipAmount']?.toDouble() ?? 0.0),
                taxNumber: Value(json['taxNumber']),
                completedAt: Value(
                  json['completedAt'] != null
                      ? DateTime.parse(json['completedAt'])
                      : null,
                ),
              ),
            );
      });

      // D. Upsert items from server response (to ensure sync)
      if (json['items'] != null) {
        final List<dynamic> items = json['items'];
        for (var item in items) {
          await db
              .into(db.orderItems)
              .insertOnConflictUpdate(
                OrderItemsCompanion(
                  id: Value(item['id']),
                  orderId: Value(serverId), // Use new server ID
                  menuItemId: Value(item['menuItemId']),
                  quantity: Value(item['quantity']),
                  priceAtTime: Value(item['priceAtTime']?.toDouble() ?? 0.0),
                  status: Value(item['status'] ?? 'pending'),
                ),
              );
        }
      }
      return;
    }

    // 3. Standard Insert (New Order from Server)
    await _performOrderUpsert(json);
  }

  Future<void> _performOrderUpsert(Map<String, dynamic> json) async {
    // Upsert order
    await db
        .into(db.orders)
        .insertOnConflictUpdate(
          OrdersCompanion(
            id: Value(json['id']),
            orderNumber: Value(json['orderNumber']),
            tableNumber: Value(json['tableNumber']),
            type: Value(json['type']),
            status: Value(json['status']),
            totalAmount: Value(json['totalAmount'].toDouble()),
            taxAmount: Value(json['taxAmount']?.toDouble() ?? 0.0),
            serviceAmount: Value(json['serviceAmount']?.toDouble() ?? 0.0),
            paymentMethod: Value(json['paymentMethod']),
            tipAmount: Value(json['tipAmount']?.toDouble() ?? 0.0),
            taxNumber: Value(json['taxNumber']),
            completedAt: Value(
              json['completedAt'] != null
                  ? DateTime.parse(json['completedAt'])
                  : null,
            ),
          ),
        );

    // Upsert items if present
    if (json['items'] != null) {
      final List<dynamic> items = json['items'];
      for (var item in items) {
        await db
            .into(db.orderItems)
            .insertOnConflictUpdate(
              OrderItemsCompanion(
                id: Value(item['id']),
                orderId: Value(item['orderId']),
                menuItemId: Value(item['menuItemId']),
                quantity: Value(item['quantity']),
                priceAtTime: Value(item['priceAtTime']?.toDouble() ?? 0.0),
                status: Value(item['status'] ?? 'pending'),
              ),
            );
      }
    }
  }

  Future<void> upsertUser(Map<String, dynamic> json) async {
    await db
        .into(db.users)
        .insertOnConflictUpdate(
          UsersCompanion(
            id: Value(json['id']),
            fullName: Value(json['fullName']),
            username: Value(json['username']),
            pin: Value(json['pin']),
            role: Value(json['role']),
            status: Value(json['status'] ?? 'active'),
            createdAt: Value(
              json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : DateTime.now(),
            ),
          ),
        );
  }

  Future<void> deleteOrder(Map<String, dynamic> json) async {
    await (db.delete(db.orders)..where((t) => t.id.equals(json['id']))).go();
    // Also delete items? Drift cascade?
    // Assuming DB has cascade or we should delete items manually.
    await (db.delete(
      db.orderItems,
    )..where((t) => t.orderId.equals(json['id']))).go();
  }

  // --- Upstream Sync Methods (Menu & Categories) ---

  Future<int> createCategory(CategoriesCompanion category) async {
    try {
      final json = {
        'name': category.name.value,
        'menuType': category.menuType.value,
        'sortOrder': category.sortOrder.value,
        // Optional fields might be absent, check key presence or use defaults
        'station': category.station.present ? category.station.value : null,
        'status': category.status.present ? category.status.value : 'active',
      };
      debugPrint('SyncService: Creating category with JSON: $json');
      final response = await dio.post('$baseUrl/api/v1/categories', data: json);
      return response.data['id'] as int;
    } catch (e) {
      debugPrint('Failed to create category upstream: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final json = {
        'name': category.name,
        'menuType': category.menuType,
        'sortOrder': category.sortOrder,
        'station': category.station,
        'status': category.status,
      };
      await dio.put('$baseUrl/api/v1/categories/${category.id}', data: json);
    } catch (e) {
      debugPrint('Failed to update category upstream: $e');
      rethrow;
    }
  }

  Future<int> createMenuItem(MenuItemsCompanion item) async {
    try {
      final json = {
        'code': item.code.present ? item.code.value : null,
        'name': item.name.value,
        'price': item.price.value,
        'categoryId': item.categoryId.value,
        'station': item.station.present ? item.station.value : 'kitchen',
        'type': item.type.present ? item.type.value : 'dine-in',
        'status': item.status.present ? item.status.value : 'active',
        'allowPriceEdit': item.allowPriceEdit.present
            ? item.allowPriceEdit.value
            : false,
      };
      final response = await dio.post('$baseUrl/api/v1/menu-items', data: json);
      return response.data['id'] as int;
    } catch (e) {
      debugPrint('Failed to create menu item upstream: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    try {
      final json = {
        'code': item.code,
        'name': item.name,
        'price': item.price,
        'categoryId': item.categoryId,
        'station': item.station,
        'type': item.type,
        'status': item.status,
        'allowPriceEdit': item.allowPriceEdit,
      };
      await dio.put('$baseUrl/api/v1/menu-items/${item.id}', data: json);
    } catch (e) {
      debugPrint('Failed to update menu item upstream: $e');
      rethrow;
    }
  }

  Future<void> deleteCategoryUpstream(int id) async {
    try {
      await dio.delete('$baseUrl/api/v1/categories/$id');
    } catch (e) {
      debugPrint('Failed to delete category upstream: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItemUpstream(int id) async {
    try {
      await dio.delete('$baseUrl/api/v1/menu-items/$id');
    } catch (e) {
      debugPrint('Failed to delete menu item upstream: $e');
      rethrow;
    }
  }
}
