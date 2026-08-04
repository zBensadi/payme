import 'package:path/path.dart' as p;

import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/business_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../datasources/file/logo_file_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;
  final LogoFileDataSource _fileDataSource;

  SettingsRepositoryImpl(this._localDataSource, this._fileDataSource);

  @override
  Future<Result<BusinessSettings>> getSettings() async {
    try {
      final settings = await _localDataSource.getSettings();
      return Success(settings);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Result<BusinessSettings>> updateSettings(
    BusinessSettings settings, {
    String? newLogoSourcePath,
  }) async {
    try {
      BusinessSettings updatedSettings = settings;

      if (newLogoSourcePath != null) {
        // Delete old logo if it exists
        if (settings.logoPath != null) {
          await _fileDataSource.deleteLogo(settings.logoPath!);
        }

        // Copy new logo
        final extension = p.extension(newLogoSourcePath).toLowerCase().replaceAll('.', '');
        final type = ['jpg', 'jpeg', 'png'].contains(extension) ? (extension == 'jpeg' ? 'jpg' : extension) : 'png';
        final newFileName = 'logo_${IdGenerator.generateUniqueId()}.$type';
        
        final relativePath = await _fileDataSource.saveLogo(newLogoSourcePath, newFileName);
        updatedSettings = updatedSettings.copyWith(logoPath: relativePath);
      }

      await _localDataSource.updateSettings(updatedSettings);
      return Success(updatedSettings);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update settings: $e'));
    }
  }

  @override
  Future<Result<void>> lockCurrency() async {
    try {
      await _localDataSource.lockCurrency();
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to lock currency: $e'));
    }
  }
}
