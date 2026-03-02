import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/services/api_service.dart';

part 'menu_repository.g.dart';

// Models adapted for API backend
class CategoryModel {
  final String id;
  final String name;
  final String menuType;
  final int sortOrder;
  final String station;
  final String status;

  CategoryModel({
    required this.id,
    required this.name,
    required this.menuType,
    required this.sortOrder,
    required this.station,
    required this.status,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      menuType: 'food', // Default value, API doesn't have this
      sortOrder: json['display_order'] as int? ?? 0,
      station: 'kitchen', // Default value, API doesn't have this
      status: json['active'] == true ? 'active' : 'inactive',
    );
  }

  Map<String, dynamic> toApiJson() {
    return {'name': name, 'description': null, 'display_order': sortOrder};
  }
}

class MenuItemModel {
  final String id;
  final String code;
  final String name;
  final double price;
  final String categoryId;
  final String station;
  final String type;
  final String status;
  final bool allowPriceEdit;

  MenuItemModel({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.station,
    required this.type,
    required this.status,
    required this.allowPriceEdit,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      code: json['id'] as String, // Use ID as code
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      categoryId: json['category_id'] as String? ?? '',
      station: json['station'] as String? ?? 'kitchen',
      type: 'food', // Default value
      status: json['available'] == true ? 'active' : 'inactive',
      allowPriceEdit: false, // Default value
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'category_id': categoryId.isEmpty ? null : categoryId,
      'name': name,
      'description': null,
      'price': price,
      'station': station,
      'image_url': null,
    };
  }
}

class MenuRepository {
  final ApiService apiService;

  MenuRepository(this.apiService);

  Future<List<CategoryModel>> getCategories({String? menuType}) async {
    try {
      final response = await apiService.getCategories();
      final categories = response
          .map<CategoryModel>((cat) => CategoryModel.fromJson(cat))
          .toList();

      // Filter by menuType if provided
      if (menuType != null) {
        return categories.where((c) => c.menuType == menuType).toList();
      }

      return categories;
    } catch (e) {
      debugPrint('Failed to get categories: $e');
      return [];
    }
  }

  Future<List<MenuItemModel>> getItemsByCategory(
    String categoryId, {
    String? type,
  }) async {
    try {
      final response = await apiService.getMenuItems();
      final items = response
          .map<MenuItemModel>((item) => MenuItemModel.fromJson(item))
          .toList();

      // Filter by category and type
      return items.where((item) {
        bool matchesCategory = item.categoryId == categoryId;
        bool matchesType = type == null || item.type == type;
        return matchesCategory && matchesType && item.status == 'active';
      }).toList();
    } catch (e) {
      debugPrint('Failed to get items by category: $e');
      return [];
    }
  }

  Future<List<MenuItemModel>> getAllItems() async {
    try {
      final response = await apiService.getMenuItems();
      return response
          .map<MenuItemModel>((item) => MenuItemModel.fromJson(item))
          .where((item) => item.status == 'active')
          .toList();
    } catch (e) {
      debugPrint('Failed to get all items: $e');
      return [];
    }
  }

  Future<CategoryModel> addCategory({
    required String name,
    required String menuType,
    required int sortOrder,
    required String station,
    String status = 'active',
  }) async {
    final response = await apiService.createCategory({
      'name': name,
      'description': null,
      'display_order': sortOrder,
    });
    return CategoryModel.fromJson(response);
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final response = await apiService.updateCategory(category.id, {
      'name': category.name,
      'description': null,
      'display_order': category.sortOrder,
      'active': category.status == 'active',
    });
    return CategoryModel.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    // API doesn't have delete, so we'll mark as inactive
    await apiService.updateCategory(id, {'active': false});
  }

  Future<MenuItemModel> addItem({
    required String code,
    required String name,
    required double price,
    required String categoryId,
    required String station,
    required String type,
    bool allowPriceEdit = false,
    String status = 'active',
  }) async {
    final response = await apiService.createMenuItem({
      'category_id': categoryId.isEmpty ? null : categoryId,
      'name': name,
      'description': null,
      'price': price,
      'station': station,
      'image_url': null,
    });
    return MenuItemModel.fromJson(response);
  }

  Future<MenuItemModel> updateItem(MenuItemModel item) async {
    final response = await apiService.updateMenuItem(item.id, {
      'category_id': item.categoryId.isEmpty ? null : item.categoryId,
      'name': item.name,
      'description': null,
      'price': item.price,
      'station': item.station,
      'image_url': null,
      'available': item.status == 'active',
    });
    return MenuItemModel.fromJson(response);
  }

  Future<void> deleteItem(String id) async {
    await apiService.deleteMenuItem(id);
  }
}

@Riverpod(keepAlive: true)
MenuRepository menuRepository(Ref ref) {
  return MenuRepository(ref.watch(apiServiceProvider));
}
