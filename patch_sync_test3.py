import sys

file_path = "test/domain/repositories/role_deletion_sync_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import 'package:payme/domain/entities/user_role.dart';", "import 'package:payme/domain/entities/user_role.dart';\nimport 'package:payme/data/models/user_role_model.dart';\nimport 'dart:async';")

old_fake_ds = """// A fake remote data source to simulate the cloud
class FakeRoleRemoteDataSource implements RoleRemoteDataSource {
  final Map<String, UserRole> _remoteDb = {};

  @override
  Future<void> pushRoles(String businessId, List<UserRole> roles) async {
    for (var role in roles) {
      _remoteDb[role.id] = role; // LWW is usually handled before pushing or on server, but here we just store
    }
  }

  @override
  Future<List<UserRole>> pullRoles(String businessId, DateTime? lastSyncTime) async {
    // Just return everything for simplicity
    return _remoteDb.values.toList();
  }
}"""

new_fake_ds = """// A fake remote data source to simulate the cloud
class FakeRoleRemoteDataSource implements RoleRemoteDataSource {
  final Map<String, UserRole> _remoteDb = {};

  @override
  Future<void> pushRoles(String businessId, List<UserRole> roles) async {
    for (var role in roles) {
      _remoteDb[role.id] = role;
    }
  }

  @override
  Future<List<UserRoleModel>> pullRoles(String businessId, DateTime? lastSyncTime) async {
    return _remoteDb.values.map((r) => UserRoleModel.fromEntity(r)).toList();
  }
}"""

content = content.replace(old_fake_ds, new_fake_ds)

old_fake_trigger = """class FakeSyncTrigger implements SyncTrigger {
  @override
  void requestSync(dynamic domain) {}
}"""

new_fake_trigger = """class FakeSyncTrigger implements SyncTrigger {
  final _controller = StreamController<dynamic>.broadcast();
  
  @override
  void requestSync(dynamic domain) {}
  
  @override
  void requestFullSync() {}
  
  @override
  Stream<dynamic> get syncRequested => _controller.stream;
  
  @override
  void dispose() {
    _controller.close();
  }
}"""

content = content.replace(old_fake_trigger, new_fake_trigger)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
