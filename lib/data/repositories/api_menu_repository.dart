import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/services/api_service.dart';

class ApiCategoryModel {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final bool active;

  ApiCategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.active,
  });

  factory ApiCategoryModel.fromJson(Map<String, dynamic> json) {
    return ApiCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}

class ApiMenuItemModel {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? station;
  final String? imageUrl;
  final bool available;
  final String? categoryName;

  ApiMenuItemModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.station,
    this.imageUrl,
    required this.available,
    this.categoryName,
  });

  factory ApiMenuItemModel.fromJson(Map<String, dynamic> json) {
    return ApiMenuItemModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      station: json['station'] as String?,
      imageUrl: json['image_url'] as String?,
      available: json['available'] as bool? ?? true,
      categoryName: json['category_name'] as String?,
    );
  }
}

class ApiMenuRepository {
  final ApiService apiService;

  ApiMenuRepository(this.apiService);

  Future<List<ApiCategoryModel>> getCategories() async {
    try {
      final response = await apiService.getCategories();
      return response
          .map<ApiCategoryModel>((cat) => ApiCategoryModel.fromJson(cat))
          .toList();
    } catch (e) {
      debugPrint('Failed to get categories: $e');
      return [];
    }
  }

  Future<List<ApiMenuItemModel>> getMenuItems() async {
    try {
      final response = await apiService.getMenuItems();
      return response
          .map<ApiMenuItemModel>((item) => ApiMenuItemModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Failed to get menu items: $e');
      return [];
    }
  }

  Future<ApiCategoryModel> createCategory({
    required String name,
    String? description,
    int displayOrder = 0,
  }) async {
    final response = await apiService.createCategory({
      'name': name,
      'description': description,
      'display_order': displayOrder,
    });
    return ApiCategoryModel.fromJson(response);
  }

  Future<ApiCategoryModel> updateCategory({
    required String id,
    required String name,
    String? description,
    required int displayOrder,
    required bool active,
  }) async {
    final response = await apiService.updateCategory(id, {
      'name': name,
      'description': description,
      'display_order': displayOrder,
      'active': active,
    });
    return ApiCategoryModel.fromJson(response);
  }

  Future<ApiMenuItemModel> createMenuItem({
    String? categoryId,
    required String name,
    String? description,
    required double price,
    String? station,
    String? imageUrl,
  }) async {
    final response = await apiService.createMenuItem({
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'station': station,
      'image_url': imageUrl,
    });
    return ApiMenuItemModel.fromJson(response);
  }

  Future<ApiMenuItemModel> updateMenuItem({
    required String id,
    String? categoryId,
    required String name,
    String? description,
    required double price,
    String? station,
    String? imageUrl,
    required bool available,
  }) async {
    final response = await apiService.updateMenuItem(id, {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'station': station,
      'image_url': imageUrl,
      'available': available,
    });
    return ApiMenuItemModel.fromJson(response);
  }

  Future<void> deleteMenuItem(String id) async {
    await apiService.deleteMenuItem(id);
  }
}

final apiMenuRepositoryProvider = Provider<ApiMenuRepository>((ref) {
  return ApiMenuRepository(ref.watch(apiServiceProvider));
});
