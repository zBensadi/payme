import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  final dbPath = r"C:\Users\bft\AppData\Roaming\PayMe App\PayMe\PayMe\payme.db";
  if (!File(dbPath).existsSync()) {
    print("DB not found");
    return;
  }
  
  var db = await databaseFactoryFfi.openDatabase(dbPath);
  var result = await db.query('clients', limit: 1, orderBy: 'created_at DESC');
  
  if (result.isEmpty) {
    print("No clients found.");
    return;
  }
  
  final client = result.first;
  print("=== TRACE REPORT ===");
  print("2. EXACT CLIENT BEFORE SQLITE SAVE (Reconstructed):");
  print("- id: ${client['id']}");
  print("- isDirty: ${client['is_dirty'] == 1}");
  print("- updatedAt: ${client['updated_at']}");
  print("- isDeleted: ${client['is_deleted'] == 1}");
  
  print("\n3. SQLITE STORED VALUES:");
  print("- is_dirty: ${client['is_dirty']}");
  print("- updated_at: ${client['updated_at']}");
  print("- client id: ${client['id']}");
  print("- synced_at: ${client['synced_at']}");
  
  var bizCtx = await db.query('business_settings', limit: 1);
  String? bizId = bizCtx.isNotEmpty ? bizCtx.first['remote_id'] as String? : null;
  print("\n12. EXACT FIRESTORE PATH:");
  print("businesses/$bizId/clients/${client['id']}");
  
  await db.close();
}
