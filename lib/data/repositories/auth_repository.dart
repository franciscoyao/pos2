import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final AppDatabase db;

  AuthRepository(this.db);

  Future<User?> login(String username, String pin) async {
    final query = db.select(db.users)
      ..where((u) => u.username.equals(username) & u.pin.equals(pin));
    return query.getSingleOrNull();
  }

  Future<User?> loginWithPin(String pin, String role) async {
    // For roles that might only use PIN if implemented that way,
    // but doc says Admin/Waiter use Username+PIN.
    // Kitchen/Bar/Kiosk might not have users in DB for "quick access" or might use a shared user.
    // Let's assume for now we just validate against a user with that role.
    // Or if quick access, we might not even hit the DB if it's just a mode switch.
    // But better to have a user logged in.
    return null;
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(databaseProvider));
}
