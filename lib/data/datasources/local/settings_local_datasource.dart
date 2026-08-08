import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../models/business_settings_model.dart';
import '../../../domain/entities/business_settings.dart';

class SettingsLocalDataSource {
  final DatabaseService _dbService;

  SettingsLocalDataSource(this._dbService);

  Future<BusinessSettings> getSettings() async {
    final db = _dbService.db;
    final maps = await db.query('business_settings', where: 'id = 1');
    
    if (maps.isEmpty) {
      // Default initialization if missing
      final defaultSettings = const BusinessSettings();
      await db.insert('business_settings', BusinessSettingsModel.toMap(defaultSettings));
      return defaultSettings;
    }
    
    return BusinessSettingsModel.fromMap(maps.first);
  }

  Future<void> updateSettings(BusinessSettings settings) async {
    final db = _dbService.db;
    final updatedSettings = settings.copyWith(
      isDirty: true,
      updatedAt: DateTime.now().toUtc(),
    );
    await db.update(
      'business_settings',
      BusinessSettingsModel.toMap(updatedSettings),
      where: 'id = 1',
    );
  }

  Future<void> lockCurrency() async {
    final db = _dbService.db;
    
    // Check if already locked
    final maps = await db.query('business_settings', columns: ['currency_locked_at'], where: 'id = 1');
    if (maps.isNotEmpty && maps.first['currency_locked_at'] != null) {
      return; // Already locked
    }
    
    await db.update(
      'business_settings',
      {'currency_locked_at': DateTime.now().toUtc().toIso8601String()},
      where: 'id = 1',
    );
  }

  Future<BusinessSettings?> getDirtySettings() async {
    final db = _dbService.db;
    final maps = await db.query('business_settings', where: 'id = 1 AND is_dirty = 1');
    if (maps.isEmpty) return null;
    return BusinessSettingsModel.fromMap(maps.first);
  }

  Future<void> updateSyncMetadata({
    required int id,
    required String remoteId,
    required DateTime syncedAt,
    required bool isDirty,
  }) async {
    final db = _dbService.db;
    await db.update(
      'business_settings',
      {
        'remote_id': remoteId,
        'synced_at': syncedAt.toUtc().toIso8601String(),
        'is_dirty': isDirty ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Overwrites the local row with pulled data. Sets isDirty = false.
  Future<void> overwriteSettings(BusinessSettings remoteSettings) async {
    final db = _dbService.db;
    final cleanSettings = remoteSettings.copyWith(isDirty: false);
    
    // Ensure we maintain id = 1
    final map = BusinessSettingsModel.toMap(cleanSettings);
    map['id'] = 1;

    // Use INSERT OR REPLACE just in case
    await db.insert('business_settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
