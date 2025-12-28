import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';

part 'user_repository.g.dart';

class UserRepository {
  final AppDatabase db;

  UserRepository(this.db);

  Future<List<User>> getAllUsers() {
    return (db.select(
      db.users,
    )..orderBy([(t) => OrderingTerm(expression: t.fullName)])).get();
  }

  Stream<List<User>> watchAllUsers() {
    return (db.select(
      db.users,
    )..orderBy([(t) => OrderingTerm(expression: t.fullName)])).watch();
  }

  Future<int> addUser(UsersCompanion user) {
    return db.into(db.users).insert(user);
  }

  Future<bool> updateUser(UsersCompanion user) {
    return db.update(db.users).replace(user);
  }

  Future<int> deleteUser(int id) {
    return (db.delete(db.users)..where((t) => t.id.equals(id))).go();
  }
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(databaseProvider));
}
