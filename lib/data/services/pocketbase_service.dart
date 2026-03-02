import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pos_system/core/services/config_service.dart';

final pocketBaseProvider = Provider<PocketBase>((ref) {
  final baseUrl = ConfigService.baseUrl;
  return PocketBase(baseUrl);
});

final pocketBaseServiceProvider = Provider<PocketBaseService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return PocketBaseService(pb);
});

class PocketBaseService {
  final PocketBase pb;

  PocketBaseService(this.pb);

  // Auth
  Future<RecordModel> login(String email, String password) async {
    final authData = await pb
        .collection('users')
        .authWithPassword(email, password);
    return authData.record;
  }

  Future<void> logout() async {
    pb.authStore.clear();
  }

  bool get isAuthenticated => pb.authStore.isValid;
  String? get userId => pb.authStore.record?.id;

  // Connection check
  Future<bool> checkConnection() async {
    try {
      await pb.health.check();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Generic CRUD wrappers
  Future<List<RecordModel>> getFullList(
    String collection, {
    String? expand,
    String? filter,
    String? sort,
  }) async {
    return await pb
        .collection(collection)
        .getFullList(expand: expand, filter: filter, sort: sort);
  }

  Future<RecordModel> create(
    String collection,
    Map<String, dynamic> body, {
    String? expand,
  }) async {
    return await pb.collection(collection).create(body: body, expand: expand);
  }

  Future<RecordModel> update(
    String collection,
    String id,
    Map<String, dynamic> body, {
    String? expand,
  }) async {
    return await pb
        .collection(collection)
        .update(id, body: body, expand: expand);
  }

  Future<RecordModel> getOne(
    String collection,
    String id, {
    String? expand,
  }) async {
    return await pb.collection(collection).getOne(id, expand: expand);
  }

  Future<void> delete(String collection, String id) async {
    await pb.collection(collection).delete(id);
  }

  // Realtime
  Future<void> subscribe(
    String collection,
    Function(RecordSubscriptionEvent) callback,
  ) async {
    await pb.collection(collection).subscribe('*', callback);
  }

  Future<void> unsubscribe(String collection) async {
    await pb.collection(collection).unsubscribe('*');
  }
}
