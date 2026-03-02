import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/core/services/config_service.dart';

// Auth token notifier
class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? token) {
    state = token;
  }

  void clearToken() {
    state = null;
  }
}

final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(
  AuthTokenNotifier.new,
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${ConfigService.baseUrl}/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null && options.extra['skipAuth'] != true) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, clear auth
          ref.read(authTokenProvider.notifier).clearToken();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), ref);
});

class ApiService {
  final Dio dio;
  final Ref ref;

  ApiService(this.dio, this.ref);

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.data['token'] != null) {
      ref.read(authTokenProvider.notifier).setToken(response.data['token']);
    }

    return response.data;
  }

  Future<void> logout() async {
    await dio.post('/auth/logout');
    ref.read(authTokenProvider.notifier).clearToken();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await dio.get('/auth/me');
    return response.data;
  }

  // Users
  Future<List<dynamic>> getUsers() async {
    final response = await dio.get('/users');
    return response.data;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await dio.post('/users', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/users/$id', data: data);
    return response.data;
  }

  Future<void> deleteUser(String id) async {
    await dio.delete('/users/$id');
  }

  // Menu
  Future<List<dynamic>> getCategories() async {
    final response = await dio.get('/menu/categories');
    return response.data;
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await dio.post('/menu/categories', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/menu/categories/$id', data: data);
    return response.data;
  }

  Future<List<dynamic>> getMenuItems() async {
    final response = await dio.get('/menu/items');
    return response.data;
  }

  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> data) async {
    final response = await dio.post('/menu/items', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateMenuItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/menu/items/$id', data: data);
    return response.data;
  }

  Future<void> deleteMenuItem(String id) async {
    await dio.delete('/menu/items/$id');
  }

  // Orders
  Future<List<dynamic>> getOrders({
    String? status,
    String? tableNumber,
    String? waiterId,
  }) async {
    final response = await dio.get(
      '/orders',
      queryParameters: {
        if (status != null) 'status': status,
        if (tableNumber != null) 'table_number': tableNumber,
        if (waiterId != null) 'waiter_id': waiterId,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getActiveOrders() async {
    final response = await dio.get('/orders/active');
    return response.data;
  }

  Future<Map<String, dynamic>> getOrder(String id) async {
    final response = await dio.get('/orders/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final response = await dio.post('/orders', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String id,
    String status,
  ) async {
    final response = await dio.patch(
      '/orders/$id/status',
      data: {'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateOrderItemStatus(
    String id,
    String status,
  ) async {
    final response = await dio.patch(
      '/orders/items/$id/status',
      data: {'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> payOrder(
    String id,
    String method,
    double amount,
    List<Map<String, dynamic>>? items,
  ) async {
    final response = await dio.post(
      '/orders/$id/pay',
      data: {'method': method, 'amount': amount, 'items': items},
    );
    return response.data;
  }

  Future<void> splitTable(
    String sourceOrderId,
    String targetTable,
    List<String> itemIds,
  ) async {
    await dio.post(
      '/orders/split',
      data: {
        'source_order_id': sourceOrderId,
        'target_table': targetTable,
        'item_ids': itemIds,
      },
    );
  }

  Future<void> mergeTables(String fromTable, String toTable) async {
    await dio.post(
      '/orders/merge',
      data: {'from_table': fromTable, 'to_table': toTable},
    );
  }

  // Tables
  Future<List<dynamic>> getTables() async {
    final response = await dio.get('/tables');
    return response.data;
  }

  Future<Map<String, dynamic>> getTableStatus(String tableNumber) async {
    final response = await dio.get('/tables/$tableNumber/status');
    return response.data;
  }

  Future<Map<String, dynamic>> createTable(Map<String, dynamic> data) async {
    final response = await dio.post('/tables', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTable(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/tables/$id', data: data);
    return response.data;
  }

  Future<void> deleteTable(String id) async {
    await dio.delete('/tables/$id');
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await dio.get(
        '/health',
        options: Options(extra: {'skipAuth': true}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
