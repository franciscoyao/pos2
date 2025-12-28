import 'package:pos_system/data/database/database.dart';
import 'package:drift/drift.dart';

class SeedService {
  final AppDatabase db;

  SeedService(this.db);

  Future<void> seedIfNeeded() async {
    final userCount = await db.users.count().getSingle();

    if (userCount == 0) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              fullName: const Value('System Admin'),
              username: const Value('admin'),
              pin: const Value('1111'),
              role: 'admin',
              status: const Value('active'),
            ),
          );

      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              fullName: const Value('John Waiter'),
              username: const Value('waiter'),
              pin: const Value('2222'),
              role: 'waiter',
              status: const Value('active'),
            ),
          );
    }
  }
}
