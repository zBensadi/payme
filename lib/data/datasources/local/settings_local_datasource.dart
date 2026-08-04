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
    await db.update(
      'business_settings',
      BusinessSettingsModel.toMap(settings),
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
}
