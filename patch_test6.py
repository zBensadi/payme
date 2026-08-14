import sys

file_path = "test/presentation/features/clients/controllers/client_form_controller_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """class MockClientRepository implements ClientRepository {
  @override
  SyncDomain get syncDomain => SyncDomain.clients;
  @override
  SyncPriority get syncPriority => SyncPriority.normal;
  @override
  Future<SyncResult> pullChanges(String b, DateTime? d) async => const SyncResult(downloaded: 0);
  @override
  Future<SyncResult> pushChanges(String b) async => const SyncResult(uploaded: 0);

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async => const Success(false);
  
  @override
  Future<Result<Client>> create(Client c) async => Success(c);
  
  @override
  Future<Result<Client>> update(Client c) async => Success(c);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  
  @override
  Future<Result<void>> softDelete(String id, {Object? txn}) async => const Success(null);
  
  @override
  Future<Result<void>> restore(String id) async => const Success(null);

  @override
  Future<Result<Client?>> getClient(String id) async => const Success(null);
  
  @override
  Future<Result<Client>> getById(String id) async => throw UnimplementedError();

  @override
  Future<Result<List<Client>>> getClients() async => const Success([]);
  
  @override
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery}) async => const Success([]);
  
  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery, ClientVisibilityContext? visibilityContext}) async => const Success([]);

  @override
  Stream<void> get onDidChange => const Stream.empty();
}

class MockClientVisibilityRepository implements ClientVisibilityRepository {
  List<ClientVisibility> mockVisibility = [];
  List<String> removedUsers = [];
  List<String> addedUsers = [];
  int getVisibilityCalls = 0;

  @override
  SyncDomain get syncDomain => SyncDomain.clientVisibility;
  @override
  SyncPriority get syncPriority => SyncPriority.normal;
"""

import re
content = re.sub(r'class MockClientRepository implements ClientRepository \{.*?\@override\n  SyncPriority get syncPriority => SyncPriority.medium;\n', replacement, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
