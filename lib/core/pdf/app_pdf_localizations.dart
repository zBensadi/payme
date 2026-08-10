import '../../l10n/app_localizations.dart';
import 'pdf_localizations.dart';

class AppPdfLocalizations implements PdfLocalizations {
  final AppLocalizations _appLoc;

  AppPdfLocalizations(this._appLoc);

  @override String get billTo => _appLoc.billTo;
  @override String get description => _appLoc.descriptionLabel;
  @override String get notes => _appLoc.notesLabel;
  @override String get generatedBy => _appLoc.generatedBy;
  @override String get page => _appLoc.page;
  @override String get of => _appLoc.ofWord; // 'of' is a reserved keyword or we can just map to something
  @override String get totalInvoiced => _appLoc.totalInvoiced;
  @override String get totalPaid => _appLoc.totalPaid;
  @override String get remainingBalance => _appLoc.remainingBalance;
  @override String get amount => _appLoc.amount;
  @override String get date => _appLoc.date;
  @override String get dueDate => _appLoc.dueDateLabel;
}
