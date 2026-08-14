import sys
import re

file_path = "lib/presentation/providers/repository_providers.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

import_statements = """import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/local/client_visibility_local_datasource.dart';
import '../../data/datasources/remote/client_visibility_remote_datasource.dart';
import '../../data/repositories_impl/client_visibility_repository_impl.dart';
import '../../domain/repositories/client_visibility_repository.dart';
import '../../data/repositories_impl/secured/secured_client_visibility_repository.dart';
"""

if "import '../../data/datasources/local/client_visibility_local_datasource.dart';" not in content:
    content = content.replace("import '../../data/repositories_impl/client_repository_impl.dart';", import_statements + "import '../../data/repositories_impl/client_repository_impl.dart';")

providers_code = """
// Client Visibility Providers
final clientVisibilityLocalDataSourceProvider = Provider<ClientVisibilityLocalDataSource>((ref) {
  final dbState = ref.watch(databaseProvider);
  return ClientVisibilityLocalDataSource(dbState);
});

final clientVisibilityRemoteDataSourceProvider = Provider<ClientVisibilityRemoteDataSource>((ref) {
  return ClientVisibilityRemoteDataSource(FirebaseFirestore.instance);
});

final internalClientVisibilityRepositoryProvider = Provider<ClientVisibilityRepositoryImpl>((ref) {
  final local = ref.watch(clientVisibilityLocalDataSourceProvider);
  final remote = ref.watch(clientVisibilityRemoteDataSourceProvider);
  return ClientVisibilityRepositoryImpl(local, remote);
});

final clientVisibilityRepositoryProvider = Provider<ClientVisibilityRepository>((ref) {
  final inner = ref.watch(internalClientVisibilityRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredClientVisibilityRepository(inner, permissionService, currentUser);
});

"""

if "clientVisibilityRepositoryProvider" not in content:
    content = content + providers_code

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
