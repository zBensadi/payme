// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PayMe';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get clients => 'Clients';

  @override
  String get invoices => 'Invoices';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get clientListEmpty => 'No clients found.';

  @override
  String get addClient => 'Add Client';

  @override
  String get search => 'Search...';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get businessName => 'Business Name';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get currency => 'Currency';

  @override
  String get language => 'Language';

  @override
  String get accountingYears => 'Accounting Years';

  @override
  String get activeYear => 'Active Year';

  @override
  String get reportsOutstanding => 'Outstanding Invoices';

  @override
  String get reportsPaid => 'Paid Invoices';

  @override
  String get reportsClientBalances => 'Client Balances';

  @override
  String get reportsPaymentsByPeriod => 'Payments by Period';

  @override
  String get reportsInvoicesByPeriod => 'Invoices by Period';

  @override
  String get deleteClientDialogTitle => 'Delete Client';

  @override
  String deleteClientDialogContent(int count) {
    return 'This client owns $count invoices.';
  }

  @override
  String get deleteClientDialogTransfer =>
      'Transfer all invoices to another client';

  @override
  String get deleteClientDialogDelete => 'Delete everything permanently';

  @override
  String get deleteClientDialogDeleteWarning =>
      'Includes all invoices, payments, and attachments. This cannot be undone.';

  @override
  String get targetClient => 'Select target client';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get statusPartiallyPaid => 'Partially Paid';

  @override
  String get statusOverpaid => 'Overpaid';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodCheque => 'Cheque';

  @override
  String get methodBankTransfer => 'Bank Transfer';

  @override
  String get incorrectPassword => 'Incorrect password.';

  @override
  String get enterPasswordToContinue => 'Enter your password to continue';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get errorEmptyRecoveryKey => 'Please enter your Recovery Key';

  @override
  String get errorPasswordTooShort =>
      'New password must be at least 6 characters';

  @override
  String get errorPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get recoverAccess => 'Recover Access';

  @override
  String get recoverAccessDescription =>
      'Enter your Recovery Key (format: XXXX-XXXX-XXXX...) and choose a new password.';

  @override
  String get recoveryKey => 'Recovery Key';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get setupPassword => 'Setup Password';

  @override
  String get welcomeToPayMe => 'Welcome to PayMe';

  @override
  String get createAdminPassword =>
      'Create an administrator password to secure your business data.';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get createPassword => 'Create Password';

  @override
  String get important => 'IMPORTANT';

  @override
  String get recoveryKeyWarning =>
      'This is your ONLY Recovery Key. It will never be shown again.\n\nIf you forget your password and lose this key, you will permanently lose access to your business data. Please copy it and store it in a safe place immediately.';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get savedRecoveryKey => 'I have saved my Recovery Key';

  @override
  String get authCorrupted => 'Authentication Corrupted';

  @override
  String get authCorruptedDescription =>
      'The application has detected existing business data, but the administrator credentials could not be found or are corrupted.\n\nTo protect your data from unauthorized takeover, creating a new administrator account is blocked.\n\nPlease restore the database from a known good backup.';

  @override
  String get newAccountingYear => 'New Accounting Year';

  @override
  String get yearNameHint => 'Year Name (e.g., 2026)';

  @override
  String get create => 'Create';

  @override
  String get noAccountingYearsFound =>
      'No accounting years found.\nCreate one to get started.';

  @override
  String get createNewYear => 'Create New Year';

  @override
  String get accountingYearDeleted => 'Accounting year deleted successfully';

  @override
  String get renameAccountingYear => 'Rename Accounting Year';

  @override
  String get yearName => 'Year Name';

  @override
  String get rename => 'Rename';

  @override
  String get setActive => 'Set Active';

  @override
  String deleteClientConfirm(String clientName) {
    return 'Are you sure you want to delete $clientName?';
  }

  @override
  String get clientDeleted => 'Client deleted';

  @override
  String get deletedClients => 'Deleted Clients';

  @override
  String get searchClientHint => 'Search by name or phone...';

  @override
  String get restoreClient => 'Restore Client';

  @override
  String restoreClientConfirm(String clientName) {
    return 'Are you sure you want to restore $clientName?';
  }

  @override
  String get restore => 'Restore';

  @override
  String get clientRestored => 'Client restored';

  @override
  String get searchDeletedClientsHint => 'Search deleted clients...';

  @override
  String get noDeletedClientsSearch => 'No deleted clients match your search.';

  @override
  String get noDeletedClients => 'No deleted clients.';

  @override
  String get loadingDeletedClients => 'Loading deleted clients...';

  @override
  String ledgerTitle(String clientName) {
    return '$clientName - Ledger';
  }

  @override
  String get noInvoicesFound =>
      'No invoices found for this client in the active year.';

  @override
  String get createInvoice => 'Create Invoice';

  @override
  String invoiceNumberTitle(String invoiceNumber) {
    return 'Invoice #$invoiceNumber';
  }

  @override
  String get payments => 'Payments';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get deleteInvoiceTitle => 'Delete Invoice';

  @override
  String get deleteInvoiceConfirm =>
      'Are you sure you want to permanently delete this invoice?';

  @override
  String get invoiceDeleted => 'Invoice deleted';

  @override
  String get loadingLedger => 'Loading ledger...';

  @override
  String get clientCreated => 'Client created successfully';

  @override
  String get clientUpdated => 'Client updated successfully';

  @override
  String get duplicateClientTitle => 'Duplicate Client';

  @override
  String get duplicateClientMessage =>
      'A client with the same name and phone number already exists. Do you want to save anyway?';

  @override
  String get saveAnyway => 'Save Anyway';

  @override
  String get editClient => 'Edit Client';

  @override
  String get newClient => 'New Client';

  @override
  String get clientNameLabel => 'Client Name *';

  @override
  String get errorEnterName => 'Please enter a name';

  @override
  String get phoneOptional => 'Phone (Optional)';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get addressOptional => 'Address (Optional)';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get saveClient => 'Save Client';

  @override
  String get totalInvoiced => 'Total Invoiced';

  @override
  String get totalPaid => 'Total Paid:';

  @override
  String get invoiceCount => 'Invoice Count';

  @override
  String get remainingBalance => 'Remaining Balance';

  @override
  String welcomeToApp(String appName) {
    return 'Welcome to $appName!';
  }

  @override
  String get createFirstYearDescription =>
      'To get started, you must create your first accounting year. All your clients, invoices, and payments will be tracked under this year.';

  @override
  String get createFirstYear => 'Create First Accounting Year';

  @override
  String get controlCenter => 'PayMe Control Center';

  @override
  String activeYearPrefix(String yearName) {
    return 'Active Year: $yearName';
  }

  @override
  String get outstanding => 'Outstanding';

  @override
  String get loadingDashboard => 'Loading dashboard...';

  @override
  String gettingStartedProgress(int completedSteps, int totalSteps) {
    return 'Getting Started ($completedSteps/$totalSteps)';
  }

  @override
  String get stepCompleteProfile => 'Complete Business Profile';

  @override
  String get stepCreateYear => 'Create First Accounting Year';

  @override
  String get stepCreateClient => 'Create First Client';

  @override
  String get stepCreateInvoice => 'Create First Invoice';

  @override
  String get stepRecordPayment => 'Record First Payment';

  @override
  String get allInvoices => 'All Invoices';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get searchInvoiceHint => 'Search by client or invoice number...';

  @override
  String get noInvoicesFilter => 'No invoices match your filters.';

  @override
  String get unknownClient => 'Unknown Client';

  @override
  String clientInvoiceNumberTitle(String clientName, String invoiceNumber) {
    return '$clientName - Invoice #$invoiceNumber';
  }

  @override
  String get viewPayments => 'View Payments';

  @override
  String get loadingInvoices => 'Loading invoices...';

  @override
  String get errorInvoiceNotFound => 'Invoice not found';

  @override
  String get invoiceSaved => 'Invoice saved';

  @override
  String get loading => 'Loading...';

  @override
  String editInvoiceTitle(String invoiceNumber) {
    return 'Edit Invoice #$invoiceNumber';
  }

  @override
  String get newInvoiceTitle => 'New Invoice';

  @override
  String get amountLabel => 'Amount *';

  @override
  String get errorRequired => 'Required';

  @override
  String get errorInvalidAmount => 'Invalid amount';

  @override
  String get dateLabel => 'Date *';

  @override
  String get dueDateLabel => 'Due Date';

  @override
  String get notSet => 'Not set';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get notesLabel => 'Notes';

  @override
  String errorGeneratePdf(String error) {
    return 'Failed to generate PDF: $error';
  }

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get errorAttachmentNotFound => 'Attachment file not found.';

  @override
  String get errorUnsupportedFormat => 'Unsupported file format.';

  @override
  String get recordPaymentTitle => 'Record Payment';

  @override
  String get editPaymentTitle => 'Edit Payment';

  @override
  String get amount => 'Amount';

  @override
  String get errorInvalidNumber => 'Invalid number';

  @override
  String get errorGreaterThanZero => 'Must be greater than 0';

  @override
  String get date => 'Date';

  @override
  String get methodLabel => 'Method';

  @override
  String get referenceLabel => 'Reference / Cheque Number (Optional)';

  @override
  String get notesOptionalLabel => 'Notes (Optional)';

  @override
  String get attachmentsLabel => 'Attachments';

  @override
  String get addFile => 'Add File';

  @override
  String get noAttachmentsAdded => 'No attachments added.';

  @override
  String get savePayment => 'Save Payment';

  @override
  String get loadingPayment => 'Loading payment...';

  @override
  String paymentsInvoiceTitle(String invoiceNumber) {
    return 'Payments - Invoice #$invoiceNumber';
  }

  @override
  String get noPaymentsRecorded => 'No payments recorded for this invoice.';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get deletePaymentTitle => 'Delete Payment';

  @override
  String get deletePaymentConfirm =>
      'Are you sure you want to permanently delete this payment and its attachments?';

  @override
  String get paymentDeleted => 'Payment deleted';

  @override
  String get attachmentDeleted => 'Attachment deleted';

  @override
  String get loadingPayments => 'Loading payments...';

  @override
  String refPrefix(String reference) {
    return 'Ref: $reference';
  }

  @override
  String get openAttachment => 'Open Attachment';

  @override
  String get deleteAttachmentTitle => 'Delete Attachment';

  @override
  String get deleteAttachmentConfirm =>
      'Are you sure you want to delete this attachment?';

  @override
  String get reportOutstandingInvoices => 'Outstanding Invoices';

  @override
  String get reportOutstandingDesc =>
      'View all unpaid and partially paid invoices for the active year.';

  @override
  String get reportPaidInvoices => 'Paid Invoices';

  @override
  String get reportPaidDesc =>
      'View all fully paid and overpaid invoices for the active year.';

  @override
  String get reportClientBalances => 'Client Balances';

  @override
  String get reportClientBalancesDesc =>
      'Overview of total invoiced, paid, and outstanding balances per client.';

  @override
  String get reportPaymentsByPeriod => 'Payments by Period';

  @override
  String get reportPaymentsDesc =>
      'Chronological list of payments filtered by date range.';

  @override
  String get reportInvoicesByPeriod => 'Invoices by Period';

  @override
  String get reportInvoicesByPeriodDesc =>
      'Chronological list of invoices filtered by date range and status.';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String errorExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get noOutstandingInvoices =>
      'No outstanding invoices found for the active year.';

  @override
  String get totalOutstanding => 'Total Outstanding:';

  @override
  String invoiceNumberLabel(String invoiceNumber) {
    return 'Invoice #$invoiceNumber';
  }

  @override
  String remainingAmount(String amount, String currency) {
    return 'Remaining: $amount $currency';
  }

  @override
  String get loadingReport => 'Loading report...';

  @override
  String get noPaidInvoices => 'No paid invoices found for the active year.';

  @override
  String get totalPaidInvoices => 'Total Paid on these Invoices:';

  @override
  String paidAmountLabel(String amount, String currency) {
    return 'Paid: $amount $currency';
  }

  @override
  String get noClientBalances =>
      'No client balances found for the active year.';

  @override
  String invoicesAndPaid(String count, String amount, String currency) {
    return 'Invoices: $count â€¢ Paid: $amount $currency';
  }

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get filterByClient => 'Filter by Client';

  @override
  String get allClients => 'All Clients';

  @override
  String get errorLoadingClients => 'Error loading clients';

  @override
  String get noPaymentsForPeriod =>
      'No payments found for the selected period.';

  @override
  String totalAmountLabel(String amount, String currency) {
    return 'Total: $amount $currency';
  }

  @override
  String get statusLabel => 'Status';

  @override
  String get all => 'All';

  @override
  String get noInvoicesForPeriod =>
      'No invoices found for the selected period.';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get clientActivity => 'Activity / Sector';

  @override
  String get clientNameRequired => 'Client name is required';

  @override
  String get businessNameRequired => 'Business Name is required';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get preferences => 'Preferences';

  @override
  String get baseCurrency => 'Base Currency';

  @override
  String get english => 'English';

  @override
  String get french => 'FranÃ§ais';

  @override
  String get arabic => 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get loadingSettings => 'Loading settings...';

  @override
  String get changePasswordDesc => 'Change your application password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get min8Chars => 'Minimum 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get saveBackup => 'Save Backup';

  @override
  String get backupCreatedSuccess => 'Backup created successfully';

  @override
  String get restoreSuccessfulTitle => 'Restore Successful';

  @override
  String get restoreSuccessfulDesc =>
      'The backup was restored successfully. A restart is highly recommended to refresh all active data.';

  @override
  String get ok => 'OK';

  @override
  String get backupDesc =>
      'Safeguard your data by creating a complete archive of your database and attachments.';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get firebaseAuthInvalidCredentials => 'Invalid email or password.';

  @override
  String get firebaseAuthUserNotFound => 'No account found for this email.';

  @override
  String get passwordResetInstructions =>
      'Enter your email address to receive a password reset link.';

  @override
  String get passwordResetSuccess =>
      'Password reset email sent. Please check your inbox.';

  @override
  String get passwordResetFailed => 'Failed to send password reset email.';

  @override
  String get bootstrapInstructions =>
      'Please enter your business name to get started.';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get applicationLanguage => 'Application Language';

  @override
  String get chooseWhatShouldHappen => 'Choose what should happen:';

  @override
  String get businessLogo => 'Business Logo';

  @override
  String get selectLogo => 'Select Logo';

  @override
  String get billTo => 'BILL TO';

  @override
  String generatedBy(String name) {
    return 'Generated by: $name';
  }

  @override
  String get page => 'Page';

  @override
  String get ofWord => 'of';

  @override
  String get documentTitle => 'Document Title';

  @override
  String get documentLayout => 'Document Layout';

  @override
  String get layoutStandard => 'Standard';

  @override
  String get layoutDuplicate => 'Duplicate';

  @override
  String get printing => 'Printing';

  @override
  String get data => 'Data';

  @override
  String get security => 'Security';

  @override
  String get business => 'Business';

  @override
  String get localization => 'Localization';

  @override
  String get syncRequired => 'Synchronizing...';

  @override
  String fileTooLarge(int maxSize) {
    return 'File is too large (Max ${maxSize}MB)';
  }

  @override
  String attachmentHint(int maxSize, String extensions) {
    return 'Max ${maxSize}MB. Accepted: $extensions';
  }

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get rc => 'RC/Agreement/Artisan No.';

  @override
  String get nif => 'NIF';

  @override
  String get nis => 'NIS';

  @override
  String get art => 'ART';

  @override
  String get users => 'Users';

  @override
  String get roles => 'Roles';

  @override
  String get hideInactiveUsers => 'Hide Inactive Users';

  @override
  String get showInactiveUsers => 'Show Inactive Users';

  @override
  String get searchUsers => 'Search Users...';

  @override
  String get noUsersFound => 'No users found.';

  @override
  String get unknownRole => 'Unknown Role';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get administration => 'Administration';

  @override
  String get userDetails => 'User Details';

  @override
  String get changeRole => 'Change Role';

  @override
  String get activateUser => 'Activate User';

  @override
  String get deactivateUser => 'Deactivate User';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get systemOwnerProtection =>
      'System Owner protection: Action not allowed.';

  @override
  String get userDeletedSuccess => 'User deleted successfully';

  @override
  String get userUpdatedSuccess => 'User updated successfully';

  @override
  String get roleId => 'Role';

  @override
  String get deactivateWarning =>
      'Are you sure you want to deactivate this user? They will not be able to log in.';

  @override
  String get deleteUserWarning =>
      'Are you sure you want to permanently delete this user?';

  @override
  String get rolesListTitle => 'Role Management';

  @override
  String get editRole => 'Edit Role';

  @override
  String get roleName => 'Role Name';

  @override
  String get roleDescription => 'Description';

  @override
  String get priority => 'Priority';

  @override
  String get permissionsGroup => 'Permissions';

  @override
  String get systemRoleWarning =>
      'This is a System Role. Some properties cannot be modified.';

  @override
  String get roleColor => 'Role Color';

  @override
  String get noRolesFound => 'No roles found.';

  @override
  String get roleUpdatedSuccess => 'Role updated successfully';

  @override
  String get permissions_clients => 'Clients';

  @override
  String get permissions_invoices => 'Invoices';

  @override
  String get permissions_payments => 'Payments';

  @override
  String get permissions_accounting => 'Accounting Years';

  @override
  String get permissions_reporting => 'Reporting & Exports';

  @override
  String get permissions_system => 'System & Administration';

  @override
  String get priorityDescription =>
      'Higher number means higher authority. You cannot assign a priority equal to or higher than your own.';

  @override
  String get createRole => 'Create Role';

  @override
  String get deleteRole => 'Delete Role';

  @override
  String get deleteRoleConfirmation =>
      'Are you sure you want to delete this role?';

  @override
  String get errorInsufficientPermissionsRepo =>
      'Insufficient permissions to access this repository.';

  @override
  String get errorSettingsNotFound => 'Settings not found.';

  @override
  String get errorInvalidRoleAssigned => 'Invalid role assigned.';

  @override
  String get errorCannotAssignHigherRole =>
      'Cannot assign a role with priority equal or higher than your own.';

  @override
  String get errorUserNotFound => 'User not found.';

  @override
  String get errorTargetUserNoValidRole => 'Target user has no valid role.';

  @override
  String get errorRoleNameExists => 'A role with this name already exists.';

  @override
  String get errorCannotCreateHigherRole =>
      'Cannot create a role with priority equal or higher than your own.';

  @override
  String get errorCannotAssignUnpossessedPermissions =>
      'Cannot assign permissions that you do not possess.';

  @override
  String get errorRoleNotFound => 'Role not found.';

  @override
  String get errorSystemRoleModification =>
      'This role is a system role and its structure cannot be modified.';

  @override
  String get errorCannotElevateRolePriority =>
      'Cannot elevate role priority to be equal or higher than your own.';

  @override
  String get errorRoleCannotBeDeleted => 'This role cannot be deleted.';

  @override
  String get errorRoleHasUsers =>
      'Cannot delete this role because users are currently assigned to it.';

  @override
  String get errorPaymentNotFound => 'Payment not found.';

  @override
  String get errorInvoiceNotFoundMsg => 'Invoice not found.';

  @override
  String get errorClientNotFoundMsg => 'Client not found.';

  @override
  String get errorDatabaseNotInitialized => 'Database not initialized';

  @override
  String get errorNoActiveAccountingYear => 'No active accounting year.';

  @override
  String get errorBusinessSettingsNotLoaded => 'Business settings not loaded';

  @override
  String get errorSourceFileNotFound => 'Source file does not exist.';

  @override
  String get errorSyncPullFailed =>
      'Pull failed. Aborting sync cycle to preserve referential integrity.';

  @override
  String get errorDatabaseClosed =>
      'Database is closed. It must be reopened first.';

  @override
  String get errorDatabaseSchemaTooNew =>
      'Database schema version is newer than the app supports. Please update the app.';

  @override
  String get userCreatedSuccess => 'User created successfully';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }

  @override
  String get errorTitle => 'Error';

  @override
  String get visibilityEveryone => 'Everyone';

  @override
  String get visibilitySpecificUsers => 'Specific Users';

  @override
  String get selectUsers => 'Select Users';

  @override
  String get deleteAccountingYearConfirm =>
      'Are you sure you want to delete this accounting year?';

  @override
  String get retry => 'Retry';

  @override
  String get logout => 'Logout';

  @override
  String get createUser => 'Create User';

  @override
  String get clientVisibility => 'Client Visibility';

  @override
  String get noUsersSelected => 'No users selected.';

  @override
  String get systemOwnerDescription => 'Business owner with full permissions';

  @override
  String priorityPrefix(int priority) {
    return 'Priority: $priority';
  }

  @override
  String get deleteUserWarningInactive =>
      'This user will lose access to PayMe. The account and email address will remain reserved and cannot be used to create a new account. The user can be reactivated later by an authorized administrator.';

  @override
  String get reactivateUser => 'Reactivate User';

  @override
  String get displayNameRequired => 'Display Name is required';

  @override
  String get initialPassword => 'Initial Password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get roleRequired => 'Role is required';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get loggedInAs => 'Logged in as:';

  @override
  String get refresh => 'Refresh';
}
