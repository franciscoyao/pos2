import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/services/api_service.dart';

part 'auth_repository.g.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String role;
  final String? pin;
  final String status;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    this.pin,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['email'] as String, // Use email as username
      fullName: json['name'] as String,
      role: json['role'] as String,
      pin: null, // API doesn't have PIN
      status: json['active'] == true ? 'active' : 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': fullName,
      'role': role,
      'active': status == 'active',
    };
  }
}

class AuthRepository {
  final ApiService apiService;

  AuthRepository(this.apiService);

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await apiService.login(email, password);
      debugPrint('User logged in: ${response['user']['id']}');
      return UserModel.fromJson(response['user']);
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await apiService.logout();
  }

  bool get isAuthenticated {
    // Check if token exists
    return true; // Simplified for now
  }

  String? get currentUserId => null; // Will be set after login

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await apiService.getCurrentUser();
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Failed to get current user: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await apiService.getUsers();
      return response
          .map<UserModel>((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      debugPrint('Failed to get users: $e');
      return [];
    }
  }

  Future<UserModel> createUser({
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
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUser({
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
    return UserModel.fromJson(response);
  }

  Future<void> deleteUser(String id) async {
    await apiService.deleteUser(id);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
}
