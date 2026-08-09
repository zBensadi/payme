import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase(r'C:\Users\bft\AppData\Roaming\PayMe App\PayMe\PayMe\payme.db');
  var res = await db.rawQuery('PRAGMA table_info(invoices)');
  for (var r in res) print(r);
  await db.close();
}
