import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = r"C:\Users\bft\AppData\Roaming\PayMe App\PayMe\PayMe\payme.db";
  
  if (!File(dbPath).existsSync()) {
    print("DB not found");
    return;
  }
  
  var db = await databaseFactory.openDatabase(dbPath);
  
  var settings = await db.query('business_settings');
  print('Settings:');
  for (var row in settings) {
    print(row);
  }
  
  await db.close();
}
