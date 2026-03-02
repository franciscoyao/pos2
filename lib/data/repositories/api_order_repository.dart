import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/services/api_service.dart';

class ApiOrderModel {
  final String id;
  final String orderNumber;
  final String tableNumber;
  final String? waiterId;
  final String? waiterName;
  final String type;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double serviceAmount;
  final double totalAmount;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<ApiOrderItemModel>? items;

  ApiOrderModel({
    required this.id,
    required this.orderNumber,
    required this.tableNumber,
    this.waiterId,
    this.waiterName,
    required this.type,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceAmount,
    required this.totalAmount,
    this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.items,
  });

  factory ApiOrderModel.fromJson(Map<String, dynamic> json) {
    return ApiOrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      tableNumber: json['table_number'] as String,
      waiterId: json['waiter_id'] as String?,
      waiterName: json['waiter_name'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      serviceAmount: (json['service_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => ApiOrderItemModel.fromJson(item))
                .toList()
          : null,
    );
  }
}

class ApiOrderItemModel {
  final String id;
  final String orderId;
  final String menuItemId;
  final String? menuItemName;
  final String? station;
  final int quantity;
  final double priceAtTime;
  final String status;
  final String? notes;

  ApiOrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    this.menuItemName,
    this.station,
    required this.quantity,
    required this.priceAtTime,
    required this.status,
    this.notes,
  });

  factory ApiOrderItemModel.fromJson(Map<String, dynamic> json) {
    return ApiOrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? '',
      menuItemId: json['menu_item_id'] as String,
      menuItemName: json['menu_item_name'] as String?,
      station: json['station'] as String?,
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class ApiOrderRepository {
  final ApiService apiService;

  ApiOrderRepository(this.apiService);

  Future<List<ApiOrderModel>> getOrders({
    String? status,
    String? tableNumber,
    String? waiterId,
  }) async {
    try {
      final response = await apiService.getOrders(
        status: status,
        tableNumber: tableNumber,
        waiterId: waiterId,
      );
      return response
          .map<ApiOrderModel>((order) => ApiOrderModel.fromJson(order))
          .toList();
    } catch (e) {
      debugPrint('Failed to get orders: $e');
      return [];
    }
  }

  Future<List<ApiOrderModel>> getActiveOrders() async {
    try {
      final response = await apiService.getActiveOrders();
      return response
          .map<ApiOrderModel>((order) => ApiOrderModel.fromJson(order))
          .toList();
    } catch (e) {
      debugPrint('Failed to get active orders: $e');
      return [];
    }
  }

  Future<ApiOrderModel> getOrder(String id) async {
    final response = await apiService.getOrder(id);
    return ApiOrderModel.fromJson(response);
  }

  Future<ApiOrderModel> createOrder({
    required String tableNumber,
    String type = 'dine-in',
    String? waiterId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await apiService.createOrder({
      'table_number': tableNumber,
      'type': type,
      'waiter_id': waiterId,
      'items': items,
    });
    return ApiOrderModel.fromJson(response);
  }

  Future<ApiOrderModel> updateOrderStatus(String id, String status) async {
    final response = await apiService.updateOrderStatus(id, status);
    return ApiOrderModel.fromJson(response);
  }

  Future<ApiOrderItemModel> updateOrderItemStatus(
    String id,
    String status,
  ) async {
    final response = await apiService.updateOrderItemStatus(id, status);
    return ApiOrderItemModel.fromJson(response);
  }

  Future<ApiOrderModel> payOrder({
    required String orderId,
    required String method,
    required double amount,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await apiService.payOrder(orderId, method, amount, items);
    return ApiOrderModel.fromJson(response);
  }

  Future<void> splitTable({
    required String sourceOrderId,
    required String targetTable,
    required List<String> itemIds,
  }) async {
    await apiService.splitTable(sourceOrderId, targetTable, itemIds);
  }

  Future<void> mergeTables({
    required String fromTable,
    required String toTable,
  }) async {
    await apiService.mergeTables(fromTable, toTable);
  }
}

final apiOrderRepositoryProvider = Provider<ApiOrderRepository>((ref) {
  return ApiOrderRepository(ref.watch(apiServiceProvider));
});
