import sys

file_path = "test/domain/repositories/role_deletion_sync_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import 'package:payme/core/database/database_helper.dart';", "import 'package:payme/core/sync/sync_domain.dart';")
content = content.replace("void requestSync(dynamic domain) {}", "void requestSync(SyncDomain domain) {}")
content = content.replace("final _controller = StreamController<dynamic>.broadcast();", "final _controller = StreamController<SyncDomain>.broadcast();")
content = content.replace("Stream<dynamic> get syncRequested => _controller.stream;", "Stream<SyncDomain> get syncRequested => _controller.stream;")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
