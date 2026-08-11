// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PayMe';

  @override
  String get dashboardTitle => 'Tableau de Bord';

  @override
  String get clients => 'Clients';

  @override
  String get invoices => 'Factures';

  @override
  String get reports => 'Rapports';

  @override
  String get settings => 'Paramètres';

  @override
  String get quickActions => 'Actions Rapides';

  @override
  String get clientListEmpty => 'Aucun client trouvé.';

  @override
  String get addClient => 'Ajouter Client';

  @override
  String get search => 'Rechercher...';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get businessName => 'Nom de l\'entreprise';

  @override
  String get address => 'Adresse';

  @override
  String get phone => 'Téléphone';

  @override
  String get email => 'E-mail';

  @override
  String get currency => 'Devise';

  @override
  String get language => 'Langue';

  @override
  String get accountingYears => 'Années Comptables';

  @override
  String get activeYear => 'Année Active';

  @override
  String get reportsOutstanding => 'Factures Impayées';

  @override
  String get reportsPaid => 'Factures Payées';

  @override
  String get reportsClientBalances => 'Soldes Clients';

  @override
  String get reportsPaymentsByPeriod => 'Paiements par Période';

  @override
  String get reportsInvoicesByPeriod => 'Factures par Période';

  @override
  String get deleteClientDialogTitle => 'Supprimer le Client';

  @override
  String deleteClientDialogContent(int count) {
    return 'Ce client possède $count factures.';
  }

  @override
  String get deleteClientDialogTransfer =>
      'Transférer toutes les factures à un autre client';

  @override
  String get deleteClientDialogDelete => 'Tout supprimer définitivement';

  @override
  String get deleteClientDialogDeleteWarning =>
      'Comprend toutes les factures, paiements et pièces jointes. Cette action est irréversible.';

  @override
  String get targetClient => 'Sélectionner le client cible';

  @override
  String get statusPaid => 'Payé';

  @override
  String get statusUnpaid => 'Non payé';

  @override
  String get statusPartiallyPaid => 'Partiellement payé';

  @override
  String get statusOverpaid => 'Trop-perçu';

  @override
  String get methodCash => 'Espèces';

  @override
  String get methodCheque => 'Chèque';

  @override
  String get methodBankTransfer => 'Virement bancaire';

  @override
  String get incorrectPassword => 'Mot de passe incorrect.';

  @override
  String get enterPasswordToContinue =>
      'Entrez votre mot de passe pour continuer';

  @override
  String get password => 'Mot de passe';

  @override
  String get login => 'Connexion';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get errorEmptyRecoveryKey =>
      'Veuillez entrer votre clé de récupération';

  @override
  String get errorPasswordTooShort =>
      'Le nouveau mot de passe doit comporter au moins 6 caractères';

  @override
  String get errorPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get recoverAccess => 'Récupérer l\'accès';

  @override
  String get recoverAccessDescription =>
      'Entrez votre clé de récupération (format : XXXX-XXXX-XXXX...) et choisissez un nouveau mot de passe.';

  @override
  String get recoveryKey => 'Clé de récupération';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get setupPassword => 'Créer un mot de passe';

  @override
  String get welcomeToPayMe => 'Bienvenue sur PayMe';

  @override
  String get createAdminPassword =>
      'Créez un mot de passe administrateur pour sécuriser vos données professionnelles.';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get createPassword => 'Créer le mot de passe';

  @override
  String get important => 'IMPORTANT';

  @override
  String get recoveryKeyWarning =>
      'Ceci est votre UNIQUE clé de récupération. Elle ne sera plus jamais affichée.\n\nSi vous oubliez votre mot de passe et perdez cette clé, vous perdrez définitivement l\'accès aux données de votre entreprise. Veuillez la copier et la conserver en lieu sûr immédiatement.';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get copyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get savedRecoveryKey => 'J\'ai sauvegardé ma clé de récupération';

  @override
  String get authCorrupted => 'Authentification corrompue';

  @override
  String get authCorruptedDescription =>
      'L\'application a détecté des données d\'entreprise existantes, mais les informations d\'identification de l\'administrateur sont introuvables ou corrompues.\n\nPour protéger vos données d\'une prise de contrôle non autorisée, la création d\'un nouveau compte administrateur est bloquée.\n\nVeuillez restaurer la base de données à partir d\'une sauvegarde valide.';

  @override
  String get newAccountingYear => 'Nouvel exercice comptable';

  @override
  String get yearNameHint => 'Nom de l\'année (ex: 2026)';

  @override
  String get create => 'Créer';

  @override
  String get noAccountingYearsFound =>
      'Aucun exercice comptable trouvé.\nCréez-en un pour commencer.';

  @override
  String get createNewYear => 'Créer un nouvel exercice';

  @override
  String get accountingYearDeleted => 'Exercice comptable supprimé avec succès';

  @override
  String get renameAccountingYear => 'Renommer l\'exercice comptable';

  @override
  String get yearName => 'Nom de l\'année';

  @override
  String get rename => 'Renommer';

  @override
  String get setActive => 'Définir comme actif';

  @override
  String deleteClientConfirm(String clientName) {
    return 'Êtes-vous sûr de vouloir supprimer $clientName ?';
  }

  @override
  String get clientDeleted => 'Client supprimé';

  @override
  String get deletedClients => 'Clients supprimés';

  @override
  String get searchClientHint => 'Rechercher par nom ou téléphone...';

  @override
  String get restoreClient => 'Restaurer le client';

  @override
  String restoreClientConfirm(String clientName) {
    return 'Êtes-vous sûr de vouloir restaurer $clientName ?';
  }

  @override
  String get restore => 'Restaurer';

  @override
  String get clientRestored => 'Client restauré';

  @override
  String get searchDeletedClientsHint => 'Rechercher des clients supprimés...';

  @override
  String get noDeletedClientsSearch =>
      'Aucun client supprimé ne correspond à votre recherche.';

  @override
  String get noDeletedClients => 'Aucun client supprimé.';

  @override
  String get loadingDeletedClients => 'Chargement des clients supprimés...';

  @override
  String ledgerTitle(String clientName) {
    return '$clientName - Grand livre';
  }

  @override
  String get noInvoicesFound =>
      'Aucune facture trouvée pour ce client dans l\'exercice actif.';

  @override
  String get createInvoice => 'Créer une facture';

  @override
  String invoiceNumberTitle(String invoiceNumber) {
    return 'Facture n°$invoiceNumber';
  }

  @override
  String get payments => 'Paiements';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get deleteInvoiceTitle => 'Supprimer la facture';

  @override
  String get deleteInvoiceConfirm =>
      'Êtes-vous sûr de vouloir supprimer définitivement cette facture ?';

  @override
  String get invoiceDeleted => 'Facture supprimée';

  @override
  String get loadingLedger => 'Chargement du grand livre...';

  @override
  String get clientCreated => 'Client créé avec succès';

  @override
  String get clientUpdated => 'Client mis à jour avec succès';

  @override
  String get duplicateClientTitle => 'Client en double';

  @override
  String get duplicateClientMessage =>
      'Un client avec le même nom et numéro de téléphone existe déjà. Voulez-vous enregistrer quand même ?';

  @override
  String get saveAnyway => 'Enregistrer quand même';

  @override
  String get editClient => 'Modifier le client';

  @override
  String get newClient => 'Nouveau client';

  @override
  String get clientNameLabel => 'Nom du client *';

  @override
  String get errorEnterName => 'Veuillez entrer un nom';

  @override
  String get phoneOptional => 'Téléphone (Optionnel)';

  @override
  String get emailOptional => 'E-mail (Optionnel)';

  @override
  String get addressOptional => 'Adresse (Optionnelle)';

  @override
  String get notesOptional => 'Notes (Optionnelles)';

  @override
  String get saveClient => 'Enregistrer le client';

  @override
  String get totalInvoiced => 'Total facturé';

  @override
  String get totalPaid => 'Total payé :';

  @override
  String get invoiceCount => 'Nombre de factures';

  @override
  String get remainingBalance => 'Solde restant';

  @override
  String welcomeToApp(String appName) {
    return 'Bienvenue sur $appName !';
  }

  @override
  String get createFirstYearDescription =>
      'Pour commencer, vous devez créer votre premier exercice comptable. Tous vos clients, factures et paiements seront suivis sous cet exercice.';

  @override
  String get createFirstYear => 'Créer le premier exercice comptable';

  @override
  String get controlCenter => 'Centre de contrôle PayMe';

  @override
  String activeYearPrefix(String yearName) {
    return 'Exercice actif : $yearName';
  }

  @override
  String get outstanding => 'En attente';

  @override
  String get loadingDashboard => 'Chargement du tableau de bord...';

  @override
  String gettingStartedProgress(int completedSteps, int totalSteps) {
    return 'Pour commencer ($completedSteps/$totalSteps)';
  }

  @override
  String get stepCompleteProfile => 'Compléter le profil de l\'entreprise';

  @override
  String get stepCreateYear => 'Créer le premier exercice comptable';

  @override
  String get stepCreateClient => 'Créer le premier client';

  @override
  String get stepCreateInvoice => 'Créer la première facture';

  @override
  String get stepRecordPayment => 'Enregistrer le premier paiement';

  @override
  String get allInvoices => 'Toutes les factures';

  @override
  String get filterByStatus => 'Filtrer par statut';

  @override
  String get allStatuses => 'Tous les statuts';

  @override
  String get searchInvoiceHint =>
      'Rechercher par client ou numéro de facture...';

  @override
  String get noInvoicesFilter => 'Aucune facture ne correspond à vos filtres.';

  @override
  String get unknownClient => 'Client inconnu';

  @override
  String clientInvoiceNumberTitle(String clientName, String invoiceNumber) {
    return '$clientName - Facture n°$invoiceNumber';
  }

  @override
  String get viewPayments => 'Voir les paiements';

  @override
  String get loadingInvoices => 'Chargement des factures...';

  @override
  String get errorInvoiceNotFound => 'Facture non trouvée';

  @override
  String get invoiceSaved => 'Facture enregistrée';

  @override
  String get loading => 'Chargement...';

  @override
  String editInvoiceTitle(String invoiceNumber) {
    return 'Modifier la facture n°$invoiceNumber';
  }

  @override
  String get newInvoiceTitle => 'Nouvelle facture';

  @override
  String get amountLabel => 'Montant *';

  @override
  String get errorRequired => 'Requis';

  @override
  String get errorInvalidAmount => 'Montant invalide';

  @override
  String get dateLabel => 'Date *';

  @override
  String get dueDateLabel => 'Date d\'échéance';

  @override
  String get notSet => 'Non définie';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get notesLabel => 'Notes';

  @override
  String errorGeneratePdf(String error) {
    return 'Échec de la génération du PDF : $error';
  }

  @override
  String get generatePdf => 'Générer le PDF';

  @override
  String get errorAttachmentNotFound => 'Fichier joint introuvable.';

  @override
  String get errorUnsupportedFormat => 'Format de fichier non pris en charge.';

  @override
  String get recordPaymentTitle => 'Enregistrer un paiement';

  @override
  String get editPaymentTitle => 'Modifier le paiement';

  @override
  String get amount => 'Montant';

  @override
  String get errorInvalidNumber => 'Nombre invalide';

  @override
  String get errorGreaterThanZero => 'Doit être supérieur à 0';

  @override
  String get date => 'Date';

  @override
  String get methodLabel => 'Méthode';

  @override
  String get referenceLabel => 'Référence / Numéro de chèque (Optionnel)';

  @override
  String get notesOptionalLabel => 'Notes (Optionnel)';

  @override
  String get attachmentsLabel => 'Pièces jointes';

  @override
  String get addFile => 'Ajouter un fichier';

  @override
  String get noAttachmentsAdded => 'Aucune pièce jointe.';

  @override
  String get savePayment => 'Enregistrer le paiement';

  @override
  String get loadingPayment => 'Chargement du paiement...';

  @override
  String paymentsInvoiceTitle(String invoiceNumber) {
    return 'Paiements - Facture n°$invoiceNumber';
  }

  @override
  String get noPaymentsRecorded =>
      'Aucun paiement enregistré pour cette facture.';

  @override
  String get recordPayment => 'Enregistrer un paiement';

  @override
  String get deletePaymentTitle => 'Supprimer le paiement';

  @override
  String get deletePaymentConfirm =>
      'Êtes-vous sûr de vouloir supprimer définitivement ce paiement et ses pièces jointes ?';

  @override
  String get paymentDeleted => 'Paiement supprimé';

  @override
  String get attachmentDeleted => 'Pièce jointe supprimée';

  @override
  String get loadingPayments => 'Chargement des paiements...';

  @override
  String refPrefix(String reference) {
    return 'Réf: $reference';
  }

  @override
  String get openAttachment => 'Ouvrir la pièce jointe';

  @override
  String get deleteAttachmentTitle => 'Supprimer la pièce jointe';

  @override
  String get deleteAttachmentConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette pièce jointe ?';

  @override
  String get reportOutstandingInvoices => 'Factures en attente';

  @override
  String get reportOutstandingDesc =>
      'Afficher toutes les factures impayées et partiellement payées pour l\'exercice actif.';

  @override
  String get reportPaidInvoices => 'Factures payées';

  @override
  String get reportPaidDesc =>
      'Afficher toutes les factures entièrement payées et trop-perçues pour l\'exercice actif.';

  @override
  String get reportClientBalances => 'Soldes des clients';

  @override
  String get reportClientBalancesDesc =>
      'Aperçu des montants facturés, payés et en attente par client.';

  @override
  String get reportPaymentsByPeriod => 'Paiements par période';

  @override
  String get reportPaymentsDesc =>
      'Liste chronologique des paiements filtrés par plage de dates.';

  @override
  String get reportInvoicesByPeriod => 'Factures par période';

  @override
  String get reportInvoicesByPeriodDesc =>
      'Liste chronologique des factures filtrées par plage de dates et statut.';

  @override
  String get exportCsv => 'Exporter en CSV';

  @override
  String errorExportFailed(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String get noOutstandingInvoices =>
      'Aucune facture en attente trouvée pour l\'exercice actif.';

  @override
  String get totalOutstanding => 'Total en attente :';

  @override
  String invoiceNumberLabel(String invoiceNumber) {
    return 'Facture n°$invoiceNumber';
  }

  @override
  String remainingAmount(String amount, String currency) {
    return 'Reste : $amount $currency';
  }

  @override
  String get loadingReport => 'Chargement du rapport...';

  @override
  String get noPaidInvoices =>
      'Aucune facture payée trouvée pour l\'exercice actif.';

  @override
  String get totalPaidInvoices => 'Total payé sur ces factures :';

  @override
  String paidAmountLabel(String amount, String currency) {
    return 'Payé : $amount $currency';
  }

  @override
  String get noClientBalances =>
      'Aucun solde client trouvé pour l\'exercice actif.';

  @override
  String invoicesAndPaid(String count, String amount, String currency) {
    return 'Factures : $count • Payé : $amount $currency';
  }

  @override
  String get startDate => 'Date de début';

  @override
  String get endDate => 'Date de fin';

  @override
  String get filterByClient => 'Filtrer par client';

  @override
  String get allClients => 'Tous les clients';

  @override
  String get errorLoadingClients => 'Erreur lors du chargement des clients';

  @override
  String get noPaymentsForPeriod =>
      'Aucun paiement trouvé pour la période sélectionnée.';

  @override
  String totalAmountLabel(String amount, String currency) {
    return 'Total : $amount $currency';
  }

  @override
  String get statusLabel => 'Statut';

  @override
  String get all => 'Tous';

  @override
  String get noInvoicesForPeriod =>
      'Aucune facture trouvée pour la période sélectionnée.';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get backupAndRestore => 'Sauvegarde et restauration';

  @override
  String get changePasswordTitle => 'Changer le mot de passe';

  @override
  String get businessInformation => 'Informations sur l\'entreprise';

  @override
  String get businessNameRequired => 'Le nom de l\'entreprise est requis';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get preferences => 'Préférences';

  @override
  String get baseCurrency => 'Devise de base';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get loadingSettings => 'Chargement des paramètres...';

  @override
  String get changePasswordDesc =>
      'Modifier le mot de passe de votre application';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get min8Chars => 'Minimum 8 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get saveBackup => 'Enregistrer la sauvegarde';

  @override
  String get backupCreatedSuccess => 'Sauvegarde créée avec succès';

  @override
  String get restoreSuccessfulTitle => 'Restauration réussie';

  @override
  String get restoreSuccessfulDesc =>
      'La sauvegarde a été restaurée avec succès. Un redémarrage est fortement recommandé pour actualiser toutes les données actives.';

  @override
  String get ok => 'OK';

  @override
  String get backupDesc =>
      'Protégez vos données en créant une archive complète de votre base de données et de vos pièces jointes.';

  @override
  String get createBackup => 'Créer une sauvegarde';

  @override
  String get restoreBackup => 'Restaurer une sauvegarde';

  @override
  String get invalidEmailFormat => 'Format d\'e-mail invalide';

  @override
  String get emailRequired => 'L\'e-mail est requis';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get firebaseAuthInvalidCredentials =>
      'E-mail ou mot de passe invalide.';

  @override
  String get firebaseAuthUserNotFound => 'Aucun compte trouvé pour cet e-mail.';

  @override
  String get passwordResetInstructions =>
      'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.';

  @override
  String get passwordResetSuccess =>
      'E-mail de réinitialisation envoyé. Veuillez vérifier votre boîte de réception.';

  @override
  String get passwordResetFailed =>
      'Échec de l\'envoi de l\'e-mail de réinitialisation.';

  @override
  String get bootstrapInstructions =>
      'Veuillez entrer le nom de votre entreprise pour commencer.';

  @override
  String get completeSetup => 'Terminer la configuration';

  @override
  String get applicationLanguage => 'Langue de l\'Application';

  @override
  String get chooseWhatShouldHappen => 'Choisissez ce qui doit se passer :';

  @override
  String get businessLogo => 'Logo de l\'entreprise';

  @override
  String get selectLogo => 'Sélectionner un logo';

  @override
  String get billTo => 'FACTURER À';

  @override
  String get generatedBy => 'Généré par PayMe';

  @override
  String get page => 'Page';

  @override
  String get ofWord => 'sur';

  @override
  String get documentTitle => 'Titre du document';

  @override
  String get documentLayout => 'Mise en page du document';

  @override
  String get layoutStandard => 'Standard';

  @override
  String get layoutDuplicate => 'Duplicata';

  @override
  String get printing => 'Impression';

  @override
  String get data => 'Données';

  @override
  String get security => 'Sécurité';

  @override
  String get business => 'Entreprise';

  @override
  String get localization => 'Localisation';

  @override
  String get syncRequired => 'Synchronisation en cours...';

  @override
  String fileTooLarge(int maxSize) {
    return 'Le fichier est trop volumineux (Max $maxSize Mo)';
  }

  @override
  String attachmentHint(int maxSize, String extensions) {
    return 'Max $maxSize Mo. Accepté: $extensions';
  }

  @override
  String get legalInformation => 'Informations Légales';

  @override
  String get rc => 'RC';

  @override
  String get nif => 'NIF';

  @override
  String get nis => 'NIS';

  @override
  String get art => 'ART';
}
