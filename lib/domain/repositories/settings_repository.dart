import '../../core/error/result.dart';
import '../entities/business_settings.dart';

abstract class SettingsRepository {
  Future<Result<BusinessSettings>> getSettings();
  
  /// Update basic settings (business info, currency).
  /// Providing a newLogoPath will automatically copy the file and store its relative path.
  Future<Result<BusinessSettings>> updateSettings(
    BusinessSettings settings, {
    String? newLogoSourcePath,
  });

  /// Used by Invoice creation to permanently lock the currency
  Future<Result<void>> lockCurrency();
}
