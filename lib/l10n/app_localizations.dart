import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PayMe'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @clientListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clients found.'**
  String get clientListEmpty;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @accountingYears.
  ///
  /// In en, this message translates to:
  /// **'Accounting Years'**
  String get accountingYears;

  /// No description provided for @activeYear.
  ///
  /// In en, this message translates to:
  /// **'Active Year'**
  String get activeYear;

  /// No description provided for @reportsOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Invoices'**
  String get reportsOutstanding;

  /// No description provided for @reportsPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid Invoices'**
  String get reportsPaid;

  /// No description provided for @reportsClientBalances.
  ///
  /// In en, this message translates to:
  /// **'Client Balances'**
  String get reportsClientBalances;

  /// No description provided for @reportsPaymentsByPeriod.
  ///
  /// In en, this message translates to:
  /// **'Payments by Period'**
  String get reportsPaymentsByPeriod;

  /// No description provided for @reportsInvoicesByPeriod.
  ///
  /// In en, this message translates to:
  /// **'Invoices by Period'**
  String get reportsInvoicesByPeriod;

  /// No description provided for @deleteClientDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Client'**
  String get deleteClientDialogTitle;

  /// No description provided for @deleteClientDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This client owns {count} invoices.'**
  String deleteClientDialogContent(int count);

  /// No description provided for @deleteClientDialogTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer all invoices to another client'**
  String get deleteClientDialogTransfer;

  /// No description provided for @deleteClientDialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete everything permanently'**
  String get deleteClientDialogDelete;

  /// No description provided for @deleteClientDialogDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Includes all invoices, payments, and attachments. This cannot be undone.'**
  String get deleteClientDialogDeleteWarning;

  /// No description provided for @targetClient.
  ///
  /// In en, this message translates to:
  /// **'Select target client'**
  String get targetClient;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusUnpaid;

  /// No description provided for @statusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get statusPartiallyPaid;

  /// No description provided for @statusOverpaid.
  ///
  /// In en, this message translates to:
  /// **'Overpaid'**
  String get statusOverpaid;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get methodCheque;

  /// No description provided for @methodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get methodBankTransfer;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get incorrectPassword;

  /// No description provided for @enterPasswordToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue'**
  String get enterPasswordToContinue;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @errorEmptyRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Recovery Key'**
  String get errorEmptyRecoveryKey;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get errorPasswordTooShort;

  /// No description provided for @errorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordsDoNotMatch;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @recoverAccess.
  ///
  /// In en, this message translates to:
  /// **'Recover Access'**
  String get recoverAccess;

  /// No description provided for @recoverAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your Recovery Key (format: XXXX-XXXX-XXXX...) and choose a new password.'**
  String get recoverAccessDescription;

  /// No description provided for @recoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Recovery Key'**
  String get recoveryKey;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @setupPassword.
  ///
  /// In en, this message translates to:
  /// **'Setup Password'**
  String get setupPassword;

  /// No description provided for @welcomeToPayMe.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PayMe'**
  String get welcomeToPayMe;

  /// No description provided for @createAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Create an administrator password to secure your business data.'**
  String get createAdminPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT'**
  String get important;

  /// No description provided for @recoveryKeyWarning.
  ///
  /// In en, this message translates to:
  /// **'This is your ONLY Recovery Key. It will never be shown again.\n\nIf you forget your password and lose this key, you will permanently lose access to your business data. Please copy it and store it in a safe place immediately.'**
  String get recoveryKeyWarning;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @savedRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'I have saved my Recovery Key'**
  String get savedRecoveryKey;

  /// No description provided for @authCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Authentication Corrupted'**
  String get authCorrupted;

  /// No description provided for @authCorruptedDescription.
  ///
  /// In en, this message translates to:
  /// **'The application has detected existing business data, but the administrator credentials could not be found or are corrupted.\n\nTo protect your data from unauthorized takeover, creating a new administrator account is blocked.\n\nPlease restore the database from a known good backup.'**
  String get authCorruptedDescription;

  /// No description provided for @newAccountingYear.
  ///
  /// In en, this message translates to:
  /// **'New Accounting Year'**
  String get newAccountingYear;

  /// No description provided for @yearNameHint.
  ///
  /// In en, this message translates to:
  /// **'Year Name (e.g., 2026)'**
  String get yearNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @noAccountingYearsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounting years found.\nCreate one to get started.'**
  String get noAccountingYearsFound;

  /// No description provided for @createNewYear.
  ///
  /// In en, this message translates to:
  /// **'Create New Year'**
  String get createNewYear;

  /// No description provided for @accountingYearDeleted.
  ///
  /// In en, this message translates to:
  /// **'Accounting year deleted successfully'**
  String get accountingYearDeleted;

  /// No description provided for @renameAccountingYear.
  ///
  /// In en, this message translates to:
  /// **'Rename Accounting Year'**
  String get renameAccountingYear;

  /// No description provided for @yearName.
  ///
  /// In en, this message translates to:
  /// **'Year Name'**
  String get yearName;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @setActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get setActive;

  /// No description provided for @deleteClientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {clientName}?'**
  String deleteClientConfirm(String clientName);

  /// No description provided for @clientDeleted.
  ///
  /// In en, this message translates to:
  /// **'Client deleted'**
  String get clientDeleted;

  /// No description provided for @deletedClients.
  ///
  /// In en, this message translates to:
  /// **'Deleted Clients'**
  String get deletedClients;

  /// No description provided for @searchClientHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get searchClientHint;

  /// No description provided for @restoreClient.
  ///
  /// In en, this message translates to:
  /// **'Restore Client'**
  String get restoreClient;

  /// No description provided for @restoreClientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore {clientName}?'**
  String restoreClientConfirm(String clientName);

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @clientRestored.
  ///
  /// In en, this message translates to:
  /// **'Client restored'**
  String get clientRestored;

  /// No description provided for @searchDeletedClientsHint.
  ///
  /// In en, this message translates to:
  /// **'Search deleted clients...'**
  String get searchDeletedClientsHint;

  /// No description provided for @noDeletedClientsSearch.
  ///
  /// In en, this message translates to:
  /// **'No deleted clients match your search.'**
  String get noDeletedClientsSearch;

  /// No description provided for @noDeletedClients.
  ///
  /// In en, this message translates to:
  /// **'No deleted clients.'**
  String get noDeletedClients;

  /// No description provided for @loadingDeletedClients.
  ///
  /// In en, this message translates to:
  /// **'Loading deleted clients...'**
  String get loadingDeletedClients;

  /// No description provided for @ledgerTitle.
  ///
  /// In en, this message translates to:
  /// **'{clientName} - Ledger'**
  String ledgerTitle(String clientName);

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found for this client in the active year.'**
  String get noInvoicesFound;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @invoiceNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice #{invoiceNumber}'**
  String invoiceNumberTitle(String invoiceNumber);

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @deleteInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get deleteInvoiceTitle;

  /// No description provided for @deleteInvoiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this invoice?'**
  String get deleteInvoiceConfirm;

  /// No description provided for @invoiceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Invoice deleted'**
  String get invoiceDeleted;

  /// No description provided for @loadingLedger.
  ///
  /// In en, this message translates to:
  /// **'Loading ledger...'**
  String get loadingLedger;

  /// No description provided for @clientCreated.
  ///
  /// In en, this message translates to:
  /// **'Client created successfully'**
  String get clientCreated;

  /// No description provided for @clientUpdated.
  ///
  /// In en, this message translates to:
  /// **'Client updated successfully'**
  String get clientUpdated;

  /// No description provided for @duplicateClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Client'**
  String get duplicateClientTitle;

  /// No description provided for @duplicateClientMessage.
  ///
  /// In en, this message translates to:
  /// **'A client with the same name and phone number already exists. Do you want to save anyway?'**
  String get duplicateClientMessage;

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save Anyway'**
  String get saveAnyway;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClient;

  /// No description provided for @clientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Client Name *'**
  String get clientNameLabel;

  /// No description provided for @errorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get errorEnterName;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get phoneOptional;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addressOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @saveClient.
  ///
  /// In en, this message translates to:
  /// **'Save Client'**
  String get saveClient;

  /// No description provided for @totalInvoiced.
  ///
  /// In en, this message translates to:
  /// **'Total Invoiced'**
  String get totalInvoiced;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid:'**
  String get totalPaid;

  /// No description provided for @invoiceCount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Count'**
  String get invoiceCount;

  /// No description provided for @remainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get remainingBalance;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}!'**
  String welcomeToApp(String appName);

  /// No description provided for @createFirstYearDescription.
  ///
  /// In en, this message translates to:
  /// **'To get started, you must create your first accounting year. All your clients, invoices, and payments will be tracked under this year.'**
  String get createFirstYearDescription;

  /// No description provided for @createFirstYear.
  ///
  /// In en, this message translates to:
  /// **'Create First Accounting Year'**
  String get createFirstYear;

  /// No description provided for @controlCenter.
  ///
  /// In en, this message translates to:
  /// **'PayMe Control Center'**
  String get controlCenter;

  /// No description provided for @activeYearPrefix.
  ///
  /// In en, this message translates to:
  /// **'Active Year: {yearName}'**
  String activeYearPrefix(String yearName);

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get loadingDashboard;

  /// No description provided for @gettingStartedProgress.
  ///
  /// In en, this message translates to:
  /// **'Getting Started ({completedSteps}/{totalSteps})'**
  String gettingStartedProgress(int completedSteps, int totalSteps);

  /// No description provided for @stepCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Business Profile'**
  String get stepCompleteProfile;

  /// No description provided for @stepCreateYear.
  ///
  /// In en, this message translates to:
  /// **'Create First Accounting Year'**
  String get stepCreateYear;

  /// No description provided for @stepCreateClient.
  ///
  /// In en, this message translates to:
  /// **'Create First Client'**
  String get stepCreateClient;

  /// No description provided for @stepCreateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create First Invoice'**
  String get stepCreateInvoice;

  /// No description provided for @stepRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record First Payment'**
  String get stepRecordPayment;

  /// No description provided for @allInvoices.
  ///
  /// In en, this message translates to:
  /// **'All Invoices'**
  String get allInvoices;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @searchInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Search by client or invoice number...'**
  String get searchInvoiceHint;

  /// No description provided for @noInvoicesFilter.
  ///
  /// In en, this message translates to:
  /// **'No invoices match your filters.'**
  String get noInvoicesFilter;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Client'**
  String get unknownClient;

  /// No description provided for @clientInvoiceNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'{clientName} - Invoice #{invoiceNumber}'**
  String clientInvoiceNumberTitle(String clientName, String invoiceNumber);

  /// No description provided for @viewPayments.
  ///
  /// In en, this message translates to:
  /// **'View Payments'**
  String get viewPayments;

  /// No description provided for @loadingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Loading invoices...'**
  String get loadingInvoices;

  /// No description provided for @errorInvoiceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found'**
  String get errorInvoiceNotFound;

  /// No description provided for @invoiceSaved.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved'**
  String get invoiceSaved;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @editInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice #{invoiceNumber}'**
  String editInvoiceTitle(String invoiceNumber);

  /// No description provided for @newInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get newInvoiceTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get amountLabel;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get errorRequired;

  /// No description provided for @errorInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get errorInvalidAmount;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date *'**
  String get dateLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateLabel;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @errorGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF: {error}'**
  String errorGeneratePdf(String error);

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdf;

  /// No description provided for @errorAttachmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Attachment file not found.'**
  String get errorAttachmentNotFound;

  /// No description provided for @errorUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format.'**
  String get errorUnsupportedFormat;

  /// No description provided for @recordPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPaymentTitle;

  /// No description provided for @editPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment'**
  String get editPaymentTitle;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @errorInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get errorInvalidNumber;

  /// No description provided for @errorGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get errorGreaterThanZero;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @methodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodLabel;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference / Cheque Number (Optional)'**
  String get referenceLabel;

  /// No description provided for @notesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptionalLabel;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsLabel;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get addFile;

  /// No description provided for @noAttachmentsAdded.
  ///
  /// In en, this message translates to:
  /// **'No attachments added.'**
  String get noAttachmentsAdded;

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get savePayment;

  /// No description provided for @loadingPayment.
  ///
  /// In en, this message translates to:
  /// **'Loading payment...'**
  String get loadingPayment;

  /// No description provided for @paymentsInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments - Invoice #{invoiceNumber}'**
  String paymentsInvoiceTitle(String invoiceNumber);

  /// No description provided for @noPaymentsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded for this invoice.'**
  String get noPaymentsRecorded;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @deletePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get deletePaymentTitle;

  /// No description provided for @deletePaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this payment and its attachments?'**
  String get deletePaymentConfirm;

  /// No description provided for @paymentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Payment deleted'**
  String get paymentDeleted;

  /// No description provided for @attachmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Attachment deleted'**
  String get attachmentDeleted;

  /// No description provided for @loadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Loading payments...'**
  String get loadingPayments;

  /// No description provided for @refPrefix.
  ///
  /// In en, this message translates to:
  /// **'Ref: {reference}'**
  String refPrefix(String reference);

  /// No description provided for @openAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open Attachment'**
  String get openAttachment;

  /// No description provided for @deleteAttachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Attachment'**
  String get deleteAttachmentTitle;

  /// No description provided for @deleteAttachmentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this attachment?'**
  String get deleteAttachmentConfirm;

  /// No description provided for @reportOutstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Invoices'**
  String get reportOutstandingInvoices;

  /// No description provided for @reportOutstandingDesc.
  ///
  /// In en, this message translates to:
  /// **'View all unpaid and partially paid invoices for the active year.'**
  String get reportOutstandingDesc;

  /// No description provided for @reportPaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Paid Invoices'**
  String get reportPaidInvoices;

  /// No description provided for @reportPaidDesc.
  ///
  /// In en, this message translates to:
  /// **'View all fully paid and overpaid invoices for the active year.'**
  String get reportPaidDesc;

  /// No description provided for @reportClientBalances.
  ///
  /// In en, this message translates to:
  /// **'Client Balances'**
  String get reportClientBalances;

  /// No description provided for @reportClientBalancesDesc.
  ///
  /// In en, this message translates to:
  /// **'Overview of total invoiced, paid, and outstanding balances per client.'**
  String get reportClientBalancesDesc;

  /// No description provided for @reportPaymentsByPeriod.
  ///
  /// In en, this message translates to:
  /// **'Payments by Period'**
  String get reportPaymentsByPeriod;

  /// No description provided for @reportPaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Chronological list of payments filtered by date range.'**
  String get reportPaymentsDesc;

  /// No description provided for @reportInvoicesByPeriod.
  ///
  /// In en, this message translates to:
  /// **'Invoices by Period'**
  String get reportInvoicesByPeriod;

  /// No description provided for @reportInvoicesByPeriodDesc.
  ///
  /// In en, this message translates to:
  /// **'Chronological list of invoices filtered by date range and status.'**
  String get reportInvoicesByPeriodDesc;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @errorExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String errorExportFailed(String error);

  /// No description provided for @noOutstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'No outstanding invoices found for the active year.'**
  String get noOutstandingInvoices;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding:'**
  String get totalOutstanding;

  /// No description provided for @invoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice #{invoiceNumber}'**
  String invoiceNumberLabel(String invoiceNumber);

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount} {currency}'**
  String remainingAmount(String amount, String currency);

  /// No description provided for @loadingReport.
  ///
  /// In en, this message translates to:
  /// **'Loading report...'**
  String get loadingReport;

  /// No description provided for @noPaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'No paid invoices found for the active year.'**
  String get noPaidInvoices;

  /// No description provided for @totalPaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Total Paid on these Invoices:'**
  String get totalPaidInvoices;

  /// No description provided for @paidAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid: {amount} {currency}'**
  String paidAmountLabel(String amount, String currency);

  /// No description provided for @noClientBalances.
  ///
  /// In en, this message translates to:
  /// **'No client balances found for the active year.'**
  String get noClientBalances;

  /// No description provided for @invoicesAndPaid.
  ///
  /// In en, this message translates to:
  /// **'Invoices: {count} â€¢ Paid: {amount} {currency}'**
  String invoicesAndPaid(String count, String amount, String currency);

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @filterByClient.
  ///
  /// In en, this message translates to:
  /// **'Filter by Client'**
  String get filterByClient;

  /// No description provided for @allClients.
  ///
  /// In en, this message translates to:
  /// **'All Clients'**
  String get allClients;

  /// No description provided for @errorLoadingClients.
  ///
  /// In en, this message translates to:
  /// **'Error loading clients'**
  String get errorLoadingClients;

  /// No description provided for @noPaymentsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No payments found for the selected period.'**
  String get noPaymentsForPeriod;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount} {currency}'**
  String totalAmountLabel(String amount, String currency);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noInvoicesForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No invoices found for the selected period.'**
  String get noInvoicesForPeriod;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business Name is required'**
  String get businessNameRequired;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get baseCurrency;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'FranÃ§ais'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©'**
  String get arabic;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @loadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get loadingSettings;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Change your application password'**
  String get changePasswordDesc;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get min8Chars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save Backup'**
  String get saveBackup;

  /// No description provided for @backupCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreatedSuccess;

  /// No description provided for @restoreSuccessfulTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Successful'**
  String get restoreSuccessfulTitle;

  /// No description provided for @restoreSuccessfulDesc.
  ///
  /// In en, this message translates to:
  /// **'The backup was restored successfully. A restart is highly recommended to refresh all active data.'**
  String get restoreSuccessfulDesc;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @backupDesc.
  ///
  /// In en, this message translates to:
  /// **'Safeguard your data by creating a complete archive of your database and attachments.'**
  String get backupDesc;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @firebaseAuthInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get firebaseAuthInvalidCredentials;

  /// No description provided for @firebaseAuthUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get firebaseAuthUserNotFound;

  /// No description provided for @passwordResetInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to receive a password reset link.'**
  String get passwordResetInstructions;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email.'**
  String get passwordResetFailed;

  /// No description provided for @bootstrapInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please enter your business name to get started.'**
  String get bootstrapInstructions;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @applicationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get applicationLanguage;

  /// No description provided for @chooseWhatShouldHappen.
  ///
  /// In en, this message translates to:
  /// **'Choose what should happen:'**
  String get chooseWhatShouldHappen;

  /// No description provided for @businessLogo.
  ///
  /// In en, this message translates to:
  /// **'Business Logo'**
  String get businessLogo;

  /// No description provided for @selectLogo.
  ///
  /// In en, this message translates to:
  /// **'Select Logo'**
  String get selectLogo;

  /// No description provided for @billTo.
  ///
  /// In en, this message translates to:
  /// **'BILL TO'**
  String get billTo;

  /// No description provided for @generatedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by PayMe'**
  String get generatedBy;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @ofWord.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofWord;

  /// No description provided for @documentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get documentTitle;

  /// No description provided for @documentLayout.
  ///
  /// In en, this message translates to:
  /// **'Document Layout'**
  String get documentLayout;

  /// No description provided for @layoutStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get layoutStandard;

  /// No description provided for @layoutDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get layoutDuplicate;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get printing;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @localization.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get localization;

  /// No description provided for @syncRequired.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing...'**
  String get syncRequired;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large (Max {maxSize}MB)'**
  String fileTooLarge(int maxSize);

  /// No description provided for @attachmentHint.
  ///
  /// In en, this message translates to:
  /// **'Max {maxSize}MB. Accepted: {extensions}'**
  String attachmentHint(int maxSize, String extensions);

  /// No description provided for @legalInformation.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// No description provided for @rc.
  ///
  /// In en, this message translates to:
  /// **'RC'**
  String get rc;

  /// No description provided for @nif.
  ///
  /// In en, this message translates to:
  /// **'NIF'**
  String get nif;

  /// No description provided for @nis.
  ///
  /// In en, this message translates to:
  /// **'NIS'**
  String get nis;

  /// No description provided for @art.
  ///
  /// In en, this message translates to:
  /// **'ART'**
  String get art;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @hideInactiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Hide Inactive Users'**
  String get hideInactiveUsers;

  /// No description provided for @showInactiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive Users'**
  String get showInactiveUsers;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search Users...'**
  String get searchUsers;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound;

  /// No description provided for @unknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown Role'**
  String get unknownRole;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get userDetails;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @activateUser.
  ///
  /// In en, this message translates to:
  /// **'Activate User'**
  String get activateUser;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User'**
  String get deactivateUser;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @systemOwnerProtection.
  ///
  /// In en, this message translates to:
  /// **'System Owner protection: Action not allowed.'**
  String get systemOwnerProtection;

  /// No description provided for @userDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeletedSuccess;

  /// No description provided for @userUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userUpdatedSuccess;

  /// No description provided for @roleId.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleId;

  /// No description provided for @deactivateWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this user? They will not be able to log in.'**
  String get deactivateWarning;

  /// No description provided for @deleteUserWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this user?'**
  String get deleteUserWarning;

  /// No description provided for @rolesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Management'**
  String get rolesListTitle;

  /// No description provided for @editRole.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleName;

  /// No description provided for @roleDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get roleDescription;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @permissionsGroup.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsGroup;

  /// No description provided for @systemRoleWarning.
  ///
  /// In en, this message translates to:
  /// **'This is a System Role. Some properties cannot be modified.'**
  String get systemRoleWarning;

  /// No description provided for @roleColor.
  ///
  /// In en, this message translates to:
  /// **'Role Color'**
  String get roleColor;

  /// No description provided for @noRolesFound.
  ///
  /// In en, this message translates to:
  /// **'No roles found.'**
  String get noRolesFound;

  /// No description provided for @roleUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get roleUpdatedSuccess;

  /// No description provided for @permissions_clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get permissions_clients;

  /// No description provided for @permissions_invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get permissions_invoices;

  /// No description provided for @permissions_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get permissions_payments;

  /// No description provided for @permissions_accounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting Years'**
  String get permissions_accounting;

  /// No description provided for @permissions_reporting.
  ///
  /// In en, this message translates to:
  /// **'Reporting & Exports'**
  String get permissions_reporting;

  /// No description provided for @permissions_system.
  ///
  /// In en, this message translates to:
  /// **'System & Administration'**
  String get permissions_system;

  /// No description provided for @priorityDescription.
  ///
  /// In en, this message translates to:
  /// **'Higher number means higher authority. You cannot assign a priority equal to or higher than your own.'**
  String get priorityDescription;

  /// No description provided for @createRole.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get createRole;

  /// No description provided for @deleteRole.
  ///
  /// In en, this message translates to:
  /// **'Delete Role'**
  String get deleteRole;

  /// No description provided for @deleteRoleConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this role?'**
  String get deleteRoleConfirmation;

  /// No description provided for @errorInsufficientPermissionsRepo.
  ///
  /// In en, this message translates to:
  /// **'Insufficient permissions to access this repository.'**
  String get errorInsufficientPermissionsRepo;

  /// No description provided for @errorSettingsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Settings not found.'**
  String get errorSettingsNotFound;

  /// No description provided for @errorInvalidRoleAssigned.
  ///
  /// In en, this message translates to:
  /// **'Invalid role assigned.'**
  String get errorInvalidRoleAssigned;

  /// No description provided for @errorCannotAssignHigherRole.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign a role with priority equal or higher than your own.'**
  String get errorCannotAssignHigherRole;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get errorUserNotFound;

  /// No description provided for @errorTargetUserNoValidRole.
  ///
  /// In en, this message translates to:
  /// **'Target user has no valid role.'**
  String get errorTargetUserNoValidRole;

  /// No description provided for @errorRoleNameExists.
  ///
  /// In en, this message translates to:
  /// **'A role with this name already exists.'**
  String get errorRoleNameExists;

  /// No description provided for @errorCannotCreateHigherRole.
  ///
  /// In en, this message translates to:
  /// **'Cannot create a role with priority equal or higher than your own.'**
  String get errorCannotCreateHigherRole;

  /// No description provided for @errorCannotAssignUnpossessedPermissions.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign permissions that you do not possess.'**
  String get errorCannotAssignUnpossessedPermissions;

  /// No description provided for @errorRoleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Role not found.'**
  String get errorRoleNotFound;

  /// No description provided for @errorSystemRoleModification.
  ///
  /// In en, this message translates to:
  /// **'This role is a system role and its structure cannot be modified.'**
  String get errorSystemRoleModification;

  /// No description provided for @errorCannotElevateRolePriority.
  ///
  /// In en, this message translates to:
  /// **'Cannot elevate role priority to be equal or higher than your own.'**
  String get errorCannotElevateRolePriority;

  /// No description provided for @errorRoleCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This role cannot be deleted.'**
  String get errorRoleCannotBeDeleted;

  /// No description provided for @errorRoleHasUsers.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete this role because users are currently assigned to it.'**
  String get errorRoleHasUsers;

  /// No description provided for @errorPaymentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Payment not found.'**
  String get errorPaymentNotFound;

  /// No description provided for @errorInvoiceNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found.'**
  String get errorInvoiceNotFoundMsg;

  /// No description provided for @errorClientNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Client not found.'**
  String get errorClientNotFoundMsg;

  /// No description provided for @errorDatabaseNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Database not initialized'**
  String get errorDatabaseNotInitialized;

  /// No description provided for @errorNoActiveAccountingYear.
  ///
  /// In en, this message translates to:
  /// **'No active accounting year.'**
  String get errorNoActiveAccountingYear;

  /// No description provided for @errorBusinessSettingsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Business settings not loaded'**
  String get errorBusinessSettingsNotLoaded;

  /// No description provided for @errorSourceFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Source file does not exist.'**
  String get errorSourceFileNotFound;

  /// No description provided for @errorSyncPullFailed.
  ///
  /// In en, this message translates to:
  /// **'Pull failed. Aborting sync cycle to preserve referential integrity.'**
  String get errorSyncPullFailed;

  /// No description provided for @errorDatabaseClosed.
  ///
  /// In en, this message translates to:
  /// **'Database is closed. It must be reopened first.'**
  String get errorDatabaseClosed;

  /// No description provided for @errorDatabaseSchemaTooNew.
  ///
  /// In en, this message translates to:
  /// **'Database schema version is newer than the app supports. Please update the app.'**
  String get errorDatabaseSchemaTooNew;

  /// No description provided for @userCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreatedSuccess;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {uri}'**
  String pageNotFound(String uri);

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @visibilityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get visibilityEveryone;

  /// No description provided for @visibilitySpecificUsers.
  ///
  /// In en, this message translates to:
  /// **'Specific Users'**
  String get visibilitySpecificUsers;

  /// No description provided for @selectUsers.
  ///
  /// In en, this message translates to:
  /// **'Select Users'**
  String get selectUsers;

  /// No description provided for @deleteAccountingYearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this accounting year?'**
  String get deleteAccountingYearConfirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @clientVisibility.
  ///
  /// In en, this message translates to:
  /// **'Client Visibility'**
  String get clientVisibility;

  /// No description provided for @noUsersSelected.
  ///
  /// In en, this message translates to:
  /// **'No users selected.'**
  String get noUsersSelected;

  /// No description provided for @systemOwnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Business owner with full permissions'**
  String get systemOwnerDescription;

  /// No description provided for @priorityPrefix.
  ///
  /// In en, this message translates to:
  /// **'Priority: {priority}'**
  String priorityPrefix(int priority);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
