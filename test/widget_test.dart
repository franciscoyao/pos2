import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/database/database_provider.dart';
import 'package:pos_system/data/services/sync_provider.dart';
import 'package:pos_system/data/services/sync_service.dart';
import 'package:pos_system/main.dart';

class MockSyncService extends Fake implements SyncService {
  @override
  Future<void> syncAll() async {}

  @override
  void initRealtimeUpdates() {}

  @override
  Future<void> createOrder(int localOrderId) async {}
}

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
          syncServiceProvider.overrideWith((ref) => MockSyncService()),
        ],
        child: const MyApp(),
      ),
    );

    // The app starts with a CircularProgressIndicator while initializing
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the initialization to complete (database seeding, etc.)
    await tester.pumpAndSettle();

    // Verify that we are on the RoleSelectionScreen by checking for role labels
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Waiter'), findsOneWidget);
  });
}
