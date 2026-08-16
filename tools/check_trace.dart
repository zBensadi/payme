import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = 'C:/Users/bft/AppData/Roaming/PayMe App/PayMe/PayMe/payme.db';
  if (!File(dbPath).existsSync()) {
    print('DB does not exist at $dbPath');
    return;
  }
  
  final db = await databaseFactory.openDatabase(dbPath);
  
  print('--- accounting_years ---');
  final years = await db.rawQuery('SELECT * FROM accounting_years');
  for (var row in years) print(row);

  print('--- clients ---');
  final clients = await db.rawQuery('SELECT * FROM clients');
  for (var row in clients) print(row);

  print('--- invoices ---');
  final invoices = await db.rawQuery('SELECT * FROM invoices');
  for (var row in invoices) print(row);

  print('--- invoice_sequences ---');
  final seqs = await db.rawQuery('SELECT * FROM invoice_sequences');
  for (var row in seqs) print(row);
  
  await db.close();
}
