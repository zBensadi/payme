import sys

# 5. Instrument ClientFormController.save()
file = "lib/presentation/features/clients/controllers/client_form_controller.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "Future<Result<void>> save() async {",
        "Future<Result<void>> save() async {\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientFormController.save started: visibilityType=${state.value!.visibilityType}, selectedUserIds=${state.value!.selectedUserIds}');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

# 6. Instrument ClientVisibilityLocalDataSource.addVisibility
file = "lib/data/datasources/local/client_visibility_local_datasource.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "Future<void> addVisibility(ClientVisibilityModel visibility) async {",
        "Future<void> addVisibility(ClientVisibilityModel visibility) async {\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientVisibilityLocalDataSource.addVisibility: ${visibility.clientId} -> ${visibility.userId}');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

# 7. Instrument ClientVisibilityRemoteDataSource
file = "lib/data/datasources/remote/client_visibility_remote_datasource.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "Future<void> pushVisibilities(String businessId, List<ClientVisibilityModel> visibilities) async {",
        "Future<void> pushVisibilities(String businessId, List<ClientVisibilityModel> visibilities) async {\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientVisibilityRemoteDataSource.pushVisibilities: ${visibilities.map((e) => e.clientId + \"_\" + e.userId).toList()}');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

# 8. Instrument ClientRemoteDataSource
file = "lib/data/datasources/remote/client_remote_datasource.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "Future<void> pushClients(String businessId, List<ClientModel> clients) async {",
        "Future<void> pushClients(String businessId, List<ClientModel> clients) async {\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientRemoteDataSource.pushClients: ${clients.map((c) => c.id).toList()}');"
    )
    content = content.replace(
        "Future<List<ClientModel>> getModifiedSince(String businessId, DateTime? since) async {",
        "Future<List<ClientModel>> getModifiedSince(String businessId, DateTime? since) async {\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientRemoteDataSource.getModifiedSince($since)');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

