// ignore_for_file: avoid_print

import 'package:pocketbase/pocketbase.dart';

const String pbUrl = 'http://127.0.0.1:8090';
const String adminEmail = 'admin@pos.local';
const String adminPass = '1234567890'; // Superuser password

final List<Map<String, dynamic>> usersToCreate = [
  {
    'email': 'admin@pos.local',
    'password': '12345678',
    'passwordConfirm': '12345678',
    'username': 'admin',
    'role': 'admin',
    'name': 'System Admin',
    'pin': '1111',
  },
  {
    'email': 'waiter@pos.local',
    'password': '12345678',
    'passwordConfirm': '12345678',
    'username': 'waiter',
    'role': 'waiter',
    'name': 'John Waiter',
    'pin': '2222',
  },
  {
    'email': 'kitchen@pos.local',
    'password': '12345678',
    'passwordConfirm': '12345678',
    'username': 'kitchen',
    'role': 'kitchen',
    'name': 'Kitchen Staff',
    'pin': '3333',
  },
  {
    'email': 'bar@pos.local',
    'password': '12345678',
    'passwordConfirm': '12345678',
    'username': 'bar',
    'role': 'bar',
    'name': 'Bar Staff',
    'pin': '4444',
  },
  {
    'email': 'kiosk@pos.local',
    'password': '12345678',
    'passwordConfirm': '12345678',
    'username': 'kiosk',
    'role': 'kiosk',
    'name': 'Kiosk',
    'pin': '5555',
  },
];

void main() async {
  print('--- Setting up PocketBase Users ---');

  final pb = PocketBase(pbUrl);

  // 1. Authenticate as superuser
  try {
    await pb.collection('_superusers').authWithPassword(adminEmail, adminPass);
    print('Authenticated as Superuser.');
  } catch (e) {
    print(
      'Superuser auth failed. Make sure PocketBase is running and creds are correct. Error: $e',
    );
    return;
  }

  // 2. Create Users
  for (final user in usersToCreate) {
    try {
      // Check if exists first
      final records = await pb
          .collection('users')
          .getList(filter: 'email="${user['email']}"');

      if (records.items.isNotEmpty) {
        print('User ${user['email']} already exists. Updating details...');

        final existing = records.items.first;
        final updates = <String, dynamic>{};

        if (existing.data['role'] != user['role']) {
          updates['role'] = user['role'];
        }
        if (existing.data['name'] != user['name']) {
          updates['name'] = user['name'];
        }
        if (existing.data['pin'] != user['pin']) {
          updates['pin'] = user['pin'];
        }

        if (updates.isNotEmpty) {
          await pb.collection('users').update(existing.id, body: updates);
          print('✓ Updated ${user['email']}');
        } else {
          print('No updates needed for ${user['email']}');
        }
        continue;
      }

      print('Creating user ${user['email']}...');
      await pb.collection('users').create(body: user);
      print('✓ Created ${user['email']}');
    } catch (e) {
      print('Error processing ${user['email']}: $e');
    }
  }

  print('\nDone. You can now login with these users.');
  print('Default Password: 12345678');
}
