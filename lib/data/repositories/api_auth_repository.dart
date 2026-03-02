import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/services/api_service.dart';

class ApiUserModel {
  final String id;
  final String email;
  final String name;
  final String role;

  ApiUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    return ApiUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}

class ApiAuthRepository {
  final ApiService apiService;

  ApiAuthRepository(this.apiService);

  Future<ApiUserModel?> login(String email, String password) async {
    try {
      final response = await apiService.login(email, password);
      debugPrint('User logged in: ${response['user']['id']}');
      return ApiUserModel.fromJson(response['user']);
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await apiService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<ApiUserModel?> getCurrentUser() async {
    try {
      final response = await apiService.getCurrentUser();
      return ApiUserModel.fromJson(response);
    } catch (e) {
      debugPrint('Failed to get current user: $e');
      return null;
    }
  }

  Future<List<ApiUserModel>> getAllUsers() async {
    try {
      final response = await apiService.getUsers();
      return response
          .map<ApiUserModel>((user) => ApiUserModel.fromJson(user))
          .toList();
    } catch (e) {
      debugPrint('Failed to get users: $e');
      return [];
    }
  }

  Future<ApiUserModel> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await apiService.createUser({
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });
    return ApiUserModel.fromJson(response);
  }

  Future<ApiUserModel> updateUser({
    required String id,
    required String name,
    required String role,
    required bool active,
    String? password,
  }) async {
    final data = {'name': name, 'role': role, 'active': active};
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    final response = await apiService.updateUser(id, data);
    return ApiUserModel.fromJson(response);
  }

  Future<void> deleteUser(String id) async {
    await apiService.deleteUser(id);
  }
}

final apiAuthRepositoryProvider = Provider<ApiAuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(apiServiceProvider));
});
