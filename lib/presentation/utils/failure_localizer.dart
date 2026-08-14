import 'package:flutter/widgets.dart';
import 'package:payme/l10n/app_localizations.dart';

extension FailureLocalizer on String {
  String localize(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return this;

    if (contains('Insufficient permissions')) {
      return l10n.errorInsufficientPermissionsRepo;
    }
    if (contains('Settings not found.')) {
      return l10n.errorSettingsNotFound;
    }
    if (contains('Invalid role assigned.')) {
      return l10n.errorInvalidRoleAssigned;
    }
    if (contains('Cannot assign a role with priority equal or higher than your own.')) {
      return l10n.errorCannotAssignHigherRole;
    }
    if (contains('Target user has no valid role.')) {
      return l10n.errorTargetUserNoValidRole;
    }
    if (contains('User not found.')) {
      return l10n.errorUserNotFound;
    }
    if (contains('A role with this name already exists.')) {
      return l10n.errorRoleNameExists;
    }
    if (contains('Cannot create a role with priority equal or higher than your own.')) {
      return l10n.errorCannotCreateHigherRole;
    }
    if (contains('Cannot assign permissions that you do not possess.')) {
      return l10n.errorCannotAssignUnpossessedPermissions;
    }
    if (contains('This role is a system role and its structure cannot be modified.')) {
      return l10n.errorSystemRoleModification;
    }
    if (contains('Cannot elevate role priority to be equal or higher than your own.')) {
      return l10n.errorCannotElevateRolePriority;
    }
    if (contains('Cannot delete this role because users are currently assigned to it.')) {
      return l10n.errorRoleHasUsers;
    }
    if (contains('This role cannot be deleted.')) {
      return l10n.errorRoleCannotBeDeleted;
    }
    if (contains('Role not found.')) {
      return l10n.errorRoleNotFound;
    }
    if (contains('Payment not found.')) {
      return l10n.errorPaymentNotFound;
    }
    if (contains('Invoice not found.')) {
      return l10n.errorInvoiceNotFoundMsg;
    }
    if (contains('Client not found.')) {
      return l10n.errorClientNotFoundMsg;
    }
    if (contains('Database not initialized')) {
      return l10n.errorDatabaseNotInitialized;
    }
    if (contains('No active accounting year.')) {
      return l10n.errorNoActiveAccountingYear;
    }
    if (contains('Business settings not loaded')) {
      return l10n.errorBusinessSettingsNotLoaded;
    }
    if (contains('Source file does not exist')) {
      return l10n.errorSourceFileNotFound;
    }
    if (contains('Pull failed for')) {
      return l10n.errorSyncPullFailed;
    }
    if (contains('Database is closed. It must be reopened first.')) {
      return l10n.errorDatabaseClosed;
    }
    if (contains('Database schema version is newer than the app supports')) {
      return l10n.errorDatabaseSchemaTooNew;
    }

    // Auth failures
    if (contains('invalid_credentials')) {
      return l10n.firebaseAuthInvalidCredentials;
    }
    if (contains('user_not_found')) {
      return l10n.firebaseAuthUserNotFound;
    }

    // Fallback to original string if no match
    return this;
  }
}
