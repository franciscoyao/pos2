import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/services/api_service.dart';
import 'package:pos_system/data/repositories/menu_repository.dart';

part 'order_repository.g.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String tableNumber;
  final String type;
  final String? waiterId;
  final String status;
  final double totalAmount;
  final double taxAmount;
  final double serviceAmount;
  final String paymentMethod;
  final double tipAmount;
  final String taxNumber;
  final DateTime createdAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.tableNumber,
    required this.type,
    this.waiterId,
    required this.status,
    required this.totalAmount,
    required this.taxAmount,
    required this.serviceAmount,
    required this.paymentMethod,
    required this.tipAmount,
    required this.taxNumber,
    required this.createdAt,
    this.completedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      tableNumber: json['table_number'] as String,
      type: json['type'] as String? ?? 'dine-in',
      waiterId: json['waiter_id'] as String?,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      serviceAmount: (json['service_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0.0,
      taxNumber: json['tax_number'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;
  final double priceAtTime;
  final String status;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.priceAtTime,
    required this.status,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final double amount;
  final String method;
  final String itemsJson;
  final String status;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.itemsJson,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      itemsJson: json['items_json'] as String? ?? '[]',
      status: json['status'] as String,
    );
  }
}

class OrderItemWithMenu {
  final OrderItemModel item;
  final MenuItemModel menu;

  OrderItemWithMenu(this.item, this.menu);
}

class OrderWithDetails {
  final OrderModel order;
  final List<OrderItemWithMenu> items;

  OrderWithDetails(this.order, this.items);
}

class OrderRepository {
  final ApiService apiService;

  OrderRepository(this.apiService);

  Future<List<OrderModel>> getOrders({
    String? status,
    String? tableNumber,
  }) async {
    try {
      final response = await apiService.getOrders(
        status: status,
        tableNumber: tableNumber,
      );
      return response
          .map<OrderModel>((order) => OrderModel.fromJson(order))
          .toList();
    } catch (e) {
      debugPrint('Failed to get orders: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final response = await apiService.getActiveOrders();
      return response
          .map<OrderModel>((order) => OrderModel.fromJson(order))
          .toList();
    } catch (e) {
      debugPrint('Failed to get active orders: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    return getOrders();
  }

  Future<List<OrderModel>> getPaidOrders() async {
    return getOrders(status: 'paid');
  }

  Future<List<OrderWithDetails>> getActiveTables() async {
    final orders = await getActiveOrders();

    final List<OrderWithDetails> result = [];
    for (final order in orders) {
      final items = await getOrderItemsWithMenuForOrder(order.id);
      result.add(OrderWithDetails(order, items));
    }
    return result;
  }

  Future<List<OrderItemWithMenu>> getOrderItemsWithMenuForOrder(
    String orderId,
  ) async {
    try {
      final orderData = await apiService.getOrder(orderId);
      final items = orderData['items'] as List<dynamic>;

      // Get all menu items for reference
      final menuItems = await apiService.getMenuItems();
      final menuMap = {for (var item in menuItems) item['id'] as String: item};

      return items.map((itemJson) {
        final item = OrderItemModel.fromJson(itemJson);
        final menuData = menuMap[item.menuItemId];
        if (menuData == null) {
          throw Exception('Menu item not found for order item ${item.id}');
        }
        final menu = MenuItemModel.fromJson(menuData);
        return OrderItemWithMenu(item, menu);
      }).toList();
    } catch (e) {
      debugPrint('Failed to get order items: $e');
      return [];
    }
  }

  Future<List<OrderWithDetails>> getOrdersWithDetailsByTable(
    String tableNumber,
  ) async {
    final orders = await getOrders(tableNumber: tableNumber);

    // Filter out paid and cancelled orders
    final activeOrders = orders
        .where((o) => o.status != 'paid' && o.status != 'cancelled')
        .toList();

    final List<OrderWithDetails> result = [];
    for (final order in activeOrders) {
      final items = await getOrderItemsWithMenuForOrder(order.id);
      result.add(OrderWithDetails(order, items));
    }
    return result;
  }

  Future<List<OrderWithDetails>> getOrdersByStation(String station) async {
    final orders = await getActiveOrders();

    final List<OrderWithDetails> result = [];
    for (final order in orders) {
      final items = await getOrderItemsWithMenuForOrder(order.id);
      // Filter items by station
      final stationItems = items
          .where((item) => item.menu.station == station)
          .toList();
      if (stationItems.isNotEmpty) {
        result.add(OrderWithDetails(order, stationItems));
      }
    }
    return result;
  }

  Future<OrderModel> submitOrder({
    required String orderNumber,
    required String tableNumber,
    required String type,
    String? waiterId,
    required String status,
    required double totalAmount,
    required double taxAmount,
    required double serviceAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final orderData = {
      'table_number': tableNumber,
      'type': type,
      'waiter_id': waiterId,
      'items': items
          .map(
            (item) => {
              'menu_item_id': item['menuItemId'],
              'quantity': item['quantity'],
              'price_at_time': item['priceAtTime'],
            },
          )
          .toList(),
    };

    final response = await apiService.createOrder(orderData);
    return OrderModel.fromJson(response);
  }

  Future<OrderItemModel> updateOrderItemStatus(
    String itemId,
    String status,
  ) async {
    final response = await apiService.updateOrderItemStatus(itemId, status);
    return OrderItemModel.fromJson(response);
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final response = await apiService.updateOrderStatus(orderId, status);
    return OrderModel.fromJson(response);
  }

  Future<void> markOrdersAsPaid(List<String> orderIds) async {
    for (final id in orderIds) {
      await apiService.updateOrderStatus(id, 'paid');
    }
  }

  Future<PaymentModel> payItems(
    String orderId,
    List<Map<String, dynamic>> items,
    String method,
  ) async {
    double totalAmount = 0;
    final List<Map<String, dynamic>> paidItems = [];

    for (var itemData in items) {
      final itemId = itemData['id'] as String;
      final qty = itemData['quantity'] as int;
      final priceAtTime = itemData['priceAtTime'] as double;

      totalAmount += priceAtTime * qty;

      paidItems.add({
        'id': itemId,
        'quantity': qty,
        'price_at_time': priceAtTime,
      });
    }

    // Pay order with items
    await apiService.payOrder(orderId, method, totalAmount, paidItems);

    // Return a payment model (API doesn't return payment details)
    return PaymentModel(
      id: 'payment-$orderId',
      orderId: orderId,
      amount: totalAmount,
      method: method,
      itemsJson: jsonEncode(paidItems),
      status: 'completed',
    );
  }

  Future<PaymentModel> addPayment(
    String orderId,
    double amount,
    String method,
  ) async {
    await apiService.payOrder(orderId, method, amount, null);

    return PaymentModel(
      id: 'payment-$orderId',
      orderId: orderId,
      amount: amount,
      method: method,
      itemsJson: '[]',
      status: 'completed',
    );
  }

  Future<void> splitTable(
    String sourceOrderId,
    String targetTable,
    List<String> itemIds,
  ) async {
    await apiService.splitTable(sourceOrderId, targetTable, itemIds);
  }

  Future<void> mergeTables(String fromTable, String toTable) async {
    await apiService.mergeTables(fromTable, toTable);
  }
}

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  return OrderRepository(ref.watch(apiServiceProvider));
}
