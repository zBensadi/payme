import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = r"C:\Users\bft\AppData\Roaming\PayMe App\PayMe\PayMe\payme.db";
  
  if (!File(dbPath).existsSync()) {
    print("DB not found at $dbPath");
    return;
  }
  
  var db = await databaseFactory.openDatabase(dbPath);
  var result = await db.query('business_settings');
  print('Settings table content:');
  for (var row in result) {
    print(row);
  }
  await db.close();
}
