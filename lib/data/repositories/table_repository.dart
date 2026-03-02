import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/services/api_service.dart';

part 'table_repository.g.dart';

class RestaurantTableModel {
  final String id;
  final String name;
  final String status;
  final int x;
  final int y;

  RestaurantTableModel({
    required this.id,
    required this.name,
    required this.status,
    required this.x,
    required this.y,
  });

  factory RestaurantTableModel.fromJson(Map<String, dynamic> json) {
    return RestaurantTableModel(
      id: json['id'] as String,
      name: json['table_number'] as String,
      status: json['status'] as String? ?? 'available',
      x: 0, // API doesn't have x/y coordinates
      y: 0,
    );
  }
}

class TableRepository {
  final ApiService apiService;

  TableRepository(this.apiService);

  Future<List<RestaurantTableModel>> getTables() async {
    try {
      final response = await apiService.getTables();
      return response
          .map<RestaurantTableModel>(
            (table) => RestaurantTableModel.fromJson(table),
          )
          .toList();
    } catch (e) {
      debugPrint('Failed to get tables: $e');
      return [];
    }
  }

  Future<RestaurantTableModel> addTable({
    required String name,
    String status = 'available',
    int x = 0,
    int y = 0,
  }) async {
    final response = await apiService.createTable({
      'table_number': name,
      'capacity': 4,
    });
    return RestaurantTableModel.fromJson(response);
  }

  Future<RestaurantTableModel> updateTable(RestaurantTableModel table) async {
    final response = await apiService.updateTable(table.id, {
      'table_number': table.name,
      'status': table.status,
      'capacity': 4,
    });
    return RestaurantTableModel.fromJson(response);
  }

  Future<RestaurantTableModel> updateTableStatus(
    String id,
    String status,
  ) async {
    final response = await apiService.updateTable(id, {'status': status});
    return RestaurantTableModel.fromJson(response);
  }

  Future<void> deleteTable(String id) async {
    await apiService.deleteTable(id);
  }
}

@Riverpod(keepAlive: true)
TableRepository tableRepository(Ref ref) {
  return TableRepository(ref.watch(apiServiceProvider));
}
