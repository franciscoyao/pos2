import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/repositories/auth_repository.dart';

part 'user_repository.g.dart';

// UserRepository now delegates to AuthRepository since they manage the same resource
class UserRepository {
  final AuthRepository authRepository;

  UserRepository(this.authRepository);

  Future<List<UserModel>> getUsers() async {
    return authRepository.getAllUsers();
  }

  Future<UserModel> addUser({
    required String email,
    required String username,
    required String fullName,
    required String role,
    String? pin,
    String password = '12345678',
    String status = 'active',
  }) async {
    return authRepository.createUser(
      email: email,
      password: password,
      name: fullName,
      role: role,
    );
  }

  Future<UserModel> updateUser({
    required String id,
    required String email,
    required String username,
    required String fullName,
    required String role,
    String? pin,
    String? password,
    required String status,
  }) async {
    return authRepository.updateUser(
      id: id,
      name: fullName,
      role: role,
      active: status == 'active',
      password: password,
    );
  }

  Future<void> deleteUser(String id) async {
    await authRepository.deleteUser(id);
  }
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(authRepositoryProvider));
}
