import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/entities/business_settings.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';

class SecuredSettingsRepository implements SettingsRepository {
  final SettingsRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredSettingsRepository(this._inner, this._permissionService, this._currentUser);

  AppFailure _unauthorized() {
    return const AuthFailure('Unauthorized access to settings.');
  }

  @override
  Future<Result<BusinessSettings>> getSettings() async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.settingsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getSettings();
  }
  
  @override
  Future<Result<BusinessSettings>> updateSettings(
    BusinessSettings settings, {
    String? newLogoSourcePath,
  }) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.settingsEdit)) {
      return Failure(_unauthorized());
    }

    // Example of owner protection on settings: if some settings can only be edited by owner,
    // we would check _permissionService.canManageOwner(_currentUser) here.
    // For now, we rely on the settings.edit permission.
    
    final existingResult = await _inner.getSettings();
    if (existingResult is! Success || (existingResult as Success).value == null) {
      return Failure(const DatabaseFailure('Settings not found.'));
    }
    final existing = (existingResult as Success).value!;

    final securedSettings = settings.copyWith(
      createdBy: existing.createdBy,
      updatedBy: _currentUser!.user.uid,
    );

    return await _inner.updateSettings(securedSettings, newLogoSourcePath: newLogoSourcePath);
  }

  @override
  Future<Result<void>> lockCurrency() async {
    // This is often triggered implicitly by invoice creation. 
    // We can allow it if the user can create invoices, or we can just enforce settingsEdit.
    // Let's enforce settingsEdit, or since it's a side-effect, we might just allow it if they can create invoices.
    // To be safe, we'll check if they have invoice create OR settings edit.
    if (!_permissionService.hasPermission(_currentUser, Permissions.settingsEdit) &&
        !_permissionService.hasPermission(_currentUser, Permissions.invoicesCreate)) {
      return Failure(_unauthorized());
    }
    return await _inner.lockCurrency();
  }
}
