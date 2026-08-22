// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'PayMe';

  @override
  String get dashboardTitle => 'لوحة القيادة';

  @override
  String get clients => 'العملاء';

  @override
  String get invoices => 'الفواتير';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get clientListEmpty => 'لم يتم العثور على عملاء.';

  @override
  String get addClient => 'إضافة عميل';

  @override
  String get search => 'بحث...';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get businessName => 'اسم الشركة';

  @override
  String get address => 'العنوان';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get currency => 'العملة';

  @override
  String get language => 'اللغة';

  @override
  String get accountingYears => 'السنوات المالية';

  @override
  String get activeYear => 'السنة النشطة';

  @override
  String get reportsOutstanding => 'الفواتير غير المدفوعة';

  @override
  String get reportsPaid => 'الفواتير المدفوعة';

  @override
  String get reportsClientBalances => 'أرصدة العملاء';

  @override
  String get reportsPaymentsByPeriod => 'المدفوعات حسب الفترة';

  @override
  String get reportsInvoicesByPeriod => 'الفواتير حسب الفترة';

  @override
  String get deleteClientDialogTitle => 'حذف العميل';

  @override
  String deleteClientDialogContent(int count) {
    return 'هذا العميل يمتلك $count فواتير.';
  }

  @override
  String get deleteClientDialogTransfer => 'نقل جميع الفواتير إلى عميل آخر';

  @override
  String get deleteClientDialogDelete => 'حذف كل شيء بشكل دائم';

  @override
  String get deleteClientDialogDeleteWarning =>
      'يشمل جميع الفواتير والمدفوعات والمرفقات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get targetClient => 'اختر العميل الوجهة';

  @override
  String get statusPaid => 'مدفوع';

  @override
  String get statusUnpaid => 'غير مدفوع';

  @override
  String get statusPartiallyPaid => 'مدفوع جزئياً';

  @override
  String get statusOverpaid => 'مدفوع بزيادة';

  @override
  String get methodCash => 'نقداً';

  @override
  String get methodCheque => 'شيك';

  @override
  String get methodBankTransfer => 'تحويل بنكي';

  @override
  String get incorrectPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get enterPasswordToContinue => 'أدخل كلمة المرور للمتابعة';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get errorEmptyRecoveryKey => 'الرجاء إدخال مفتاح الاسترداد الخاص بك';

  @override
  String get errorPasswordTooShort =>
      'يجب أن تتكون كلمة المرور الجديدة من 6 أحرف على الأقل';

  @override
  String get errorPasswordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get recoverAccess => 'استعادة الوصول';

  @override
  String get recoverAccessDescription =>
      'أدخل مفتاح الاسترداد (بالصيغة: XXXX-XXXX-XXXX...) واختر كلمة مرور جديدة.';

  @override
  String get recoveryKey => 'مفتاح الاسترداد';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get setupPassword => 'إعداد كلمة المرور';

  @override
  String get welcomeToPayMe => 'مرحباً بك في PayMe';

  @override
  String get createAdminPassword =>
      'قم بإنشاء كلمة مرور مسؤول لتأمين بيانات عملك.';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get createPassword => 'إنشاء كلمة المرور';

  @override
  String get important => 'هام';

  @override
  String get recoveryKeyWarning =>
      'هذا هو مفتاح الاسترداد الوحيد الخاص بك. لن يتم عرضه مرة أخرى.\n\nإذا نسيت كلمة المرور الخاصة بك وفقدت هذا المفتاح، فستفقد بشكل دائم الوصول إلى بيانات عملك. يرجى نسخه وتخزينه في مكان آمن على الفور.';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get copyToClipboard => 'نسخ إلى الحافظة';

  @override
  String get savedRecoveryKey => 'لقد حفظت مفتاح الاسترداد الخاص بي';

  @override
  String get authCorrupted => 'المصادقة تالفة';

  @override
  String get authCorruptedDescription =>
      'اكتشف التطبيق بيانات عمل موجودة، ولكن تعذر العثور على بيانات اعتماد المسؤول أو أنها تالفة.\n\nلحماية بياناتك من الاستيلاء غير المصرح به، تم حظر إنشاء حساب مسؤول جديد.\n\nالرجاء استعادة قاعدة البيانات من نسخة احتياطية صالحة ومعروفة.';

  @override
  String get newAccountingYear => 'سنة مالية جديدة';

  @override
  String get yearNameHint => 'اسم السنة (مثل 2026)';

  @override
  String get create => 'إنشاء';

  @override
  String get noAccountingYearsFound =>
      'لم يتم العثور على سنوات مالية.\nقم بإنشاء واحدة للبدء.';

  @override
  String get createNewYear => 'إنشاء سنة مالية جديدة';

  @override
  String get accountingYearDeleted => 'تم حذف السنة المالية بنجاح';

  @override
  String get renameAccountingYear => 'إعادة تسمية السنة المالية';

  @override
  String get yearName => 'اسم السنة';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get setActive => 'تعيين كنشط';

  @override
  String deleteClientConfirm(String clientName) {
    return 'هل أنت متأكد أنك تريد حذف $clientName؟';
  }

  @override
  String get clientDeleted => 'تم حذف العميل';

  @override
  String get deletedClients => 'العملاء المحذوفون';

  @override
  String get searchClientHint => 'البحث بالاسم أو الهاتف...';

  @override
  String get restoreClient => 'استعادة العميل';

  @override
  String restoreClientConfirm(String clientName) {
    return 'هل أنت متأكد أنك تريد استعادة $clientName؟';
  }

  @override
  String get restore => 'استعادة';

  @override
  String get clientRestored => 'تمت استعادة العميل';

  @override
  String get searchDeletedClientsHint => 'البحث في العملاء المحذوفين...';

  @override
  String get noDeletedClientsSearch => 'لا يوجد عملاء محذوفون يطابقون بحثك.';

  @override
  String get noDeletedClients => 'لا يوجد عملاء محذوفون.';

  @override
  String get loadingDeletedClients => 'جاري تحميل العملاء المحذوفين...';

  @override
  String ledgerTitle(String clientName) {
    return '$clientName - دفتر الأستاذ';
  }

  @override
  String get noInvoicesFound =>
      'لم يتم العثور على فواتير لهذا العميل في السنة النشطة.';

  @override
  String get createInvoice => 'إنشاء فاتورة';

  @override
  String invoiceNumberTitle(String invoiceNumber) {
    return 'فاتورة رقم $invoiceNumber';
  }

  @override
  String get payments => 'المدفوعات';

  @override
  String get exportPdf => 'تصدير كملف PDF';

  @override
  String get deleteInvoiceTitle => 'حذف الفاتورة';

  @override
  String get deleteInvoiceConfirm =>
      'هل أنت متأكد أنك تريد حذف هذه الفاتورة بشكل دائم؟';

  @override
  String get invoiceDeleted => 'تم حذف الفاتورة';

  @override
  String get loadingLedger => 'جاري تحميل دفتر الأستاذ...';

  @override
  String get clientCreated => 'تم إنشاء العميل بنجاح';

  @override
  String get clientUpdated => 'تم تحديث العميل بنجاح';

  @override
  String get duplicateClientTitle => 'عميل مكرر';

  @override
  String get duplicateClientMessage =>
      'يوجد بالفعل عميل بنفس الاسم ورقم الهاتف. هل تريد الحفظ على أي حال؟';

  @override
  String get saveAnyway => 'حفظ على أي حال';

  @override
  String get editClient => 'تعديل العميل';

  @override
  String get newClient => 'عميل جديد';

  @override
  String get clientNameLabel => 'اسم العميل *';

  @override
  String get errorEnterName => 'الرجاء إدخال اسم';

  @override
  String get phoneOptional => 'الهاتف (اختياري)';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get addressOptional => 'العنوان (اختياري)';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get saveClient => 'حفظ العميل';

  @override
  String get totalInvoiced => 'إجمالي الفواتير';

  @override
  String get totalPaid => 'إجمالي المدفوع:';

  @override
  String get invoiceCount => 'عدد الفواتير';

  @override
  String get remainingBalance => 'الرصيد المتبقي';

  @override
  String welcomeToApp(String appName) {
    return 'مرحباً بك في $appName!';
  }

  @override
  String get createFirstYearDescription =>
      'للبدء، يجب عليك إنشاء سنتك المالية الأولى. سيتم تتبع جميع عملائك وفواتيرك ومدفوعاتك ضمن هذه السنة.';

  @override
  String get createFirstYear => 'إنشاء السنة المالية الأولى';

  @override
  String get controlCenter => 'مركز تحكم PayMe';

  @override
  String activeYearPrefix(String yearName) {
    return 'السنة النشطة: $yearName';
  }

  @override
  String get outstanding => 'المستحق';

  @override
  String get loadingDashboard => 'جاري تحميل لوحة التحكم...';

  @override
  String gettingStartedProgress(int completedSteps, int totalSteps) {
    return 'البدء ($completedSteps/$totalSteps)';
  }

  @override
  String get stepCompleteProfile => 'إكمال ملف الشركة';

  @override
  String get stepCreateYear => 'إنشاء السنة المالية الأولى';

  @override
  String get stepCreateClient => 'إنشاء العميل الأول';

  @override
  String get stepCreateInvoice => 'إنشاء الفاتورة الأولى';

  @override
  String get stepRecordPayment => 'تسجيل أول دفعة';

  @override
  String get allInvoices => 'جميع الفواتير';

  @override
  String get filterByStatus => 'تصفية حسب الحالة';

  @override
  String get allStatuses => 'جميع الحالات';

  @override
  String get searchInvoiceHint => 'البحث عن طريق العميل أو رقم الفاتورة...';

  @override
  String get noInvoicesFilter => 'لا توجد فواتير تطابق التصفية الخاصة بك.';

  @override
  String get unknownClient => 'عميل غير معروف';

  @override
  String clientInvoiceNumberTitle(String clientName, String invoiceNumber) {
    return '$clientName - فاتورة رقم $invoiceNumber';
  }

  @override
  String get viewPayments => 'عرض المدفوعات';

  @override
  String get loadingInvoices => 'جاري تحميل الفواتير...';

  @override
  String get errorInvoiceNotFound => 'الفاتورة غير موجودة';

  @override
  String get invoiceSaved => 'تم حفظ الفاتورة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String editInvoiceTitle(String invoiceNumber) {
    return 'تعديل فاتورة رقم $invoiceNumber';
  }

  @override
  String get newInvoiceTitle => 'فاتورة جديدة';

  @override
  String get amountLabel => 'المبلغ *';

  @override
  String get errorRequired => 'مطلوب';

  @override
  String get errorInvalidAmount => 'مبلغ غير صالح';

  @override
  String get dateLabel => 'التاريخ *';

  @override
  String get dueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get notSet => 'لم يتم التعيين';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get notesLabel => 'ملاحظات';

  @override
  String errorGeneratePdf(String error) {
    return 'فشل في إنشاء ملف PDF: $error';
  }

  @override
  String get generatePdf => 'إنشاء ملف PDF';

  @override
  String get errorAttachmentNotFound => 'ملف المرفق غير موجود.';

  @override
  String get errorUnsupportedFormat => 'تنسيق الملف غير مدعوم.';

  @override
  String get recordPaymentTitle => 'تسجيل دفعة';

  @override
  String get editPaymentTitle => 'تعديل دفعة';

  @override
  String get amount => 'المبلغ';

  @override
  String get errorInvalidNumber => 'رقم غير صالح';

  @override
  String get errorGreaterThanZero => 'يجب أن يكون أكبر من 0';

  @override
  String get date => 'التاريخ';

  @override
  String get methodLabel => 'الطريقة';

  @override
  String get referenceLabel => 'المرجع / رقم الشيك (اختياري)';

  @override
  String get notesOptionalLabel => 'ملاحظات (اختياري)';

  @override
  String get attachmentsLabel => 'المرفقات';

  @override
  String get addFile => 'إضافة ملف';

  @override
  String get noAttachmentsAdded => 'لم يتم إضافة مرفقات.';

  @override
  String get savePayment => 'حفظ الدفعة';

  @override
  String get loadingPayment => 'جاري تحميل الدفعة...';

  @override
  String paymentsInvoiceTitle(String invoiceNumber) {
    return 'المدفوعات - فاتورة رقم $invoiceNumber';
  }

  @override
  String get noPaymentsRecorded => 'لا توجد مدفوعات مسجلة لهذه الفاتورة.';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String get deletePaymentTitle => 'حذف الدفعة';

  @override
  String get deletePaymentConfirm =>
      'هل أنت متأكد أنك تريد حذف هذه الدفعة ومرفقاتها نهائياً؟';

  @override
  String get paymentDeleted => 'تم حذف الدفعة';

  @override
  String get attachmentDeleted => 'تم حذف المرفق';

  @override
  String get loadingPayments => 'جاري تحميل المدفوعات...';

  @override
  String refPrefix(String reference) {
    return 'المرجع: $reference';
  }

  @override
  String get openAttachment => 'فتح المرفق';

  @override
  String get deleteAttachmentTitle => 'حذف المرفق';

  @override
  String get deleteAttachmentConfirm => 'هل أنت متأكد أنك تريد حذف هذا المرفق؟';

  @override
  String get reportOutstandingInvoices => 'الفواتير المستحقة';

  @override
  String get reportOutstandingDesc =>
      'عرض جميع الفواتير غير المدفوعة والمدفوعة جزئياً للسنة النشطة.';

  @override
  String get reportPaidInvoices => 'الفواتير المدفوعة';

  @override
  String get reportPaidDesc =>
      'عرض جميع الفواتير المدفوعة بالكامل والمدفوعة بزيادة للسنة النشطة.';

  @override
  String get reportClientBalances => 'أرصدة العملاء';

  @override
  String get reportClientBalancesDesc =>
      'نظرة عامة على إجمالي الفواتير والمدفوعات والأرصدة المستحقة لكل عميل.';

  @override
  String get reportPaymentsByPeriod => 'المدفوعات حسب الفترة';

  @override
  String get reportPaymentsDesc =>
      'قائمة زمنية للمدفوعات المصفاة حسب النطاق الزمني.';

  @override
  String get reportInvoicesByPeriod => 'الفواتير حسب الفترة';

  @override
  String get reportInvoicesByPeriodDesc =>
      'قائمة زمنية للفواتير المصفاة حسب النطاق الزمني والحالة.';

  @override
  String get exportCsv => 'تصدير إلى CSV';

  @override
  String errorExportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get noOutstandingInvoices =>
      'لم يتم العثور على فواتير مستحقة للسنة النشطة.';

  @override
  String get totalOutstanding => 'إجمالي المستحق:';

  @override
  String invoiceNumberLabel(String invoiceNumber) {
    return 'فاتورة رقم $invoiceNumber';
  }

  @override
  String remainingAmount(String amount, String currency) {
    return 'المتبقي: $amount $currency';
  }

  @override
  String get loadingReport => 'جاري تحميل التقرير...';

  @override
  String get noPaidInvoices => 'لم يتم العثور على فواتير مدفوعة للسنة النشطة.';

  @override
  String get totalPaidInvoices => 'إجمالي المدفوع على هذه الفواتير:';

  @override
  String paidAmountLabel(String amount, String currency) {
    return 'المدفوع: $amount $currency';
  }

  @override
  String get noClientBalances => 'لم يتم العثور على أرصدة عملاء للسنة النشطة.';

  @override
  String invoicesAndPaid(String count, String amount, String currency) {
    return 'الفواتير: $count • المدفوع: $amount $currency';
  }

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get filterByClient => 'تصفية حسب العميل';

  @override
  String get allClients => 'جميع العملاء';

  @override
  String get errorLoadingClients => 'خطأ في تحميل العملاء';

  @override
  String get noPaymentsForPeriod => 'لم يتم العثور على مدفوعات للفترة المحددة.';

  @override
  String totalAmountLabel(String amount, String currency) {
    return 'الإجمالي: $amount $currency';
  }

  @override
  String get statusLabel => 'الحالة';

  @override
  String get all => 'الكل';

  @override
  String get noInvoicesForPeriod => 'لم يتم العثور على فواتير للفترة المحددة.';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get backupAndRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get businessInformation => 'معلومات الشركة';

  @override
  String get clientActivity => 'النشاط / القطاع';

  @override
  String get clientNameRequired => 'Client name is required';

  @override
  String get businessNameRequired => 'اسم الشركة مطلوب';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get baseCurrency => 'العملة الأساسية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get loadingSettings => 'جاري تحميل الإعدادات...';

  @override
  String get changePasswordDesc => 'تغيير كلمة مرور التطبيق';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get min8Chars => 'الحد الأدنى 8 أحرف';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get saveBackup => 'حفظ النسخة الاحتياطية';

  @override
  String get backupCreatedSuccess => 'تم إنشاء النسخة الاحتياطية بنجاح';

  @override
  String get restoreSuccessfulTitle => 'نجاح الاستعادة';

  @override
  String get restoreSuccessfulDesc =>
      'تمت استعادة النسخة الاحتياطية بنجاح. يوصى بشدة بإعادة التشغيل لتحديث جميع البيانات النشطة.';

  @override
  String get ok => 'موافق';

  @override
  String get backupDesc =>
      'قم بحماية بياناتك عن طريق إنشاء أرشيف كامل لقاعدة البيانات والمرفقات الخاصة بك.';

  @override
  String get createBackup => 'إنشاء نسخة احتياطية';

  @override
  String get restoreBackup => 'استعادة نسخة احتياطية';

  @override
  String get invalidEmailFormat => 'تنسيق البريد الإلكتروني غير صالح';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get firebaseAuthInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صالحة.';

  @override
  String get firebaseAuthUserNotFound =>
      'لم يتم العثور على حساب لهذا البريد الإلكتروني.';

  @override
  String get passwordResetInstructions =>
      'أدخل عنوان بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور.';

  @override
  String get passwordResetSuccess =>
      'تم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور. يرجى التحقق من صندوق الوارد الخاص بك.';

  @override
  String get passwordResetFailed =>
      'فشل إرسال البريد الإلكتروني لإعادة تعيين كلمة المرور.';

  @override
  String get bootstrapInstructions => 'يرجى إدخال اسم عملك للبدء.';

  @override
  String get completeSetup => 'إكمال الإعداد';

  @override
  String get applicationLanguage => 'لغة التطبيق';

  @override
  String get chooseWhatShouldHappen => 'اختر ما يجب أن يحدث:';

  @override
  String get businessLogo => 'شعار الشركة';

  @override
  String get selectLogo => 'اختيار شعار';

  @override
  String get billTo => 'فاتورة إلى';

  @override
  String generatedBy(String name) {
    return 'تم الإنشاء بواسطة: $name';
  }

  @override
  String get page => 'صفحة';

  @override
  String get ofWord => 'من';

  @override
  String get documentTitle => 'عنوان المستند';

  @override
  String get documentLayout => 'تخطيط المستند';

  @override
  String get layoutStandard => 'قياسي';

  @override
  String get layoutDuplicate => 'نسخة مكررة';

  @override
  String get printing => 'طباعة';

  @override
  String get data => 'البيانات';

  @override
  String get security => 'الأمان';

  @override
  String get business => 'الشركة';

  @override
  String get localization => 'اللغة والمنطقة';

  @override
  String get syncRequired => 'جاري المزامنة...';

  @override
  String fileTooLarge(int maxSize) {
    return 'الملف كبير جدا (الحد الأقصى $maxSize ميغابايت)';
  }

  @override
  String attachmentHint(int maxSize, String extensions) {
    return 'الحد الأقصى $maxSize ميغابايت. المقبولة: $extensions';
  }

  @override
  String get legalInformation => 'المعلومات القانونية';

  @override
  String get rc => 'السجل التجاري / الاعتماد / رقم الحرفي';

  @override
  String get nif => 'رقم التعريف الجبائي (NIF)';

  @override
  String get nis => 'رقم التعريف الإحصائي (NIS)';

  @override
  String get art => 'المادة الضريبية (ART)';

  @override
  String get users => 'المستخدمون';

  @override
  String get roles => 'الأدوار';

  @override
  String get hideInactiveUsers => 'إخفاء المستخدمين غير النشطين';

  @override
  String get showInactiveUsers => 'إظهار المستخدمين غير النشطين';

  @override
  String get searchUsers => 'بحث عن مستخدمين...';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين.';

  @override
  String get unknownRole => 'دور غير معروف';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get administration => 'الإدارة';

  @override
  String get userDetails => 'تفاصيل المستخدم';

  @override
  String get changeRole => 'تغيير الدور';

  @override
  String get activateUser => 'تفعيل المستخدم';

  @override
  String get deactivateUser => 'تعطيل المستخدم';

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String get systemOwnerProtection => 'حماية مالك النظام: إجراء غير مسموح به.';

  @override
  String get userDeletedSuccess => 'تم حذف المستخدم بنجاح';

  @override
  String get userUpdatedSuccess => 'تم تحديث المستخدم بنجاح';

  @override
  String get roleId => 'الدور';

  @override
  String get deactivateWarning =>
      'هل أنت متأكد من تعطيل هذا المستخدم؟ لن يتمكن من تسجيل الدخول.';

  @override
  String get deleteUserWarning => 'هل أنت متأكد من حذف هذا المستخدم نهائيًا؟';

  @override
  String get rolesListTitle => 'إدارة الأدوار';

  @override
  String get editRole => 'تعديل الدور';

  @override
  String get roleName => 'اسم الدور';

  @override
  String get roleDescription => 'الوصف';

  @override
  String get priority => 'الأولوية';

  @override
  String get permissionsGroup => 'الصلاحيات';

  @override
  String get systemRoleWarning => 'هذا دور نظام. بعض الخصائص لا يمكن تعديلها.';

  @override
  String get roleColor => 'لون الدور';

  @override
  String get noRolesFound => 'لم يتم العثور على أدوار.';

  @override
  String get roleUpdatedSuccess => 'تم تحديث الدور بنجاح';

  @override
  String get permissions_clients => 'العملاء';

  @override
  String get permissions_invoices => 'الفواتير';

  @override
  String get permissions_payments => 'المدفوعات';

  @override
  String get permissions_accounting => 'السنوات المالية';

  @override
  String get permissions_reporting => 'التقارير والتصدير';

  @override
  String get permissions_system => 'النظام والإدارة';

  @override
  String get priorityDescription =>
      'الرقم الأعلى يعني أولوية أعلى. لا يمكنك تعيين أولوية تساوي أو تتجاوز أولويتك.';

  @override
  String get createRole => 'إنشاء دور';

  @override
  String get deleteRole => 'حذف الدور';

  @override
  String get deleteRoleConfirmation => 'هل أنت متأكد أنك تريد حذف هذا الدور؟';

  @override
  String get errorInsufficientPermissionsRepo =>
      'صلاحيات غير كافية للوصول إلى هذا السجل.';

  @override
  String get errorSettingsNotFound => 'لم يتم العثور على الإعدادات.';

  @override
  String get errorInvalidRoleAssigned => 'تم تعيين دور غير صالح.';

  @override
  String get errorCannotAssignHigherRole =>
      'لا يمكنك تعيين دور بأولوية تساوي أو تزيد عن أولويتك.';

  @override
  String get errorUserNotFound => 'المستخدم غير موجود.';

  @override
  String get errorTargetUserNoValidRole =>
      'المستخدم المستهدف ليس لديه دور صالح.';

  @override
  String get errorRoleNameExists => 'يوجد دور بهذا الاسم بالفعل.';

  @override
  String get errorCannotCreateHigherRole =>
      'لا يمكنك إنشاء دور بأولوية تساوي أو تزيد عن أولويتك.';

  @override
  String get errorCannotAssignUnpossessedPermissions =>
      'لا يمكنك تعيين صلاحيات لا تملكها.';

  @override
  String get errorRoleNotFound => 'الدور غير موجود.';

  @override
  String get errorSystemRoleModification =>
      'هذا دور نظام ولا يمكن تعديل هيكله.';

  @override
  String get errorCannotElevateRolePriority =>
      'لا يمكن رفع أولوية الدور لتكون مساوية أو أعلى من أولويتك.';

  @override
  String get errorRoleCannotBeDeleted => 'لا يمكن حذف هذا الدور.';

  @override
  String get errorRoleHasUsers =>
      'لا يمكن حذف هذا الدور لأن هناك مستخدمين معينين له حاليا.';

  @override
  String get errorPaymentNotFound => 'الدفع غير موجود.';

  @override
  String get errorInvoiceNotFoundMsg => 'الفاتورة غير موجودة.';

  @override
  String get errorClientNotFoundMsg => 'العميل غير موجود.';

  @override
  String get errorDatabaseNotInitialized => 'قاعدة البيانات غير مهيأة';

  @override
  String get errorNoActiveAccountingYear => 'لا توجد سنة مالية نشطة.';

  @override
  String get errorBusinessSettingsNotLoaded => 'لم يتم تحميل إعدادات العمل';

  @override
  String get errorSourceFileNotFound => 'الملف المصدر غير موجود.';

  @override
  String get errorSyncPullFailed =>
      'فشل السحب. تم إلغاء دورة المزامنة للحفاظ على السلامة المرجعية.';

  @override
  String get errorDatabaseClosed =>
      'قاعدة البيانات مغلقة. يجب إعادة فتحها أولا.';

  @override
  String get errorDatabaseSchemaTooNew =>
      'إصدار مخطط قاعدة البيانات أحدث مما يدعمه التطبيق. يرجى تحديث التطبيق.';

  @override
  String get userCreatedSuccess => 'تم إنشاء المستخدم بنجاح';

  @override
  String get saveProfile => 'حفظ الملف الشخصي';

  @override
  String pageNotFound(String uri) {
    return 'الصفحة غير موجودة: $uri';
  }

  @override
  String get errorTitle => 'خطأ';

  @override
  String get visibilityEveryone => 'الجميع';

  @override
  String get visibilitySpecificUsers => 'مستخدمون محددون';

  @override
  String get selectUsers => 'تحديد المستخدمين';

  @override
  String get deleteAccountingYearConfirm =>
      'هل أنت متأكد من أنك تريد حذف هذه السنة المالية؟';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get createUser => 'إنشاء مستخدم';

  @override
  String get clientVisibility => 'رؤية العميل';

  @override
  String get noUsersSelected => 'لم يتم تحديد مستخدمين.';

  @override
  String get systemOwnerDescription => 'مالك العمل بكامل الصلاحيات';

  @override
  String priorityPrefix(int priority) {
    return 'الأولوية: $priority';
  }

  @override
  String get deleteUserWarningInactive =>
      'سيفقد هذا المستخدم الوصول إلى PayMe. سيظل الحساب وعنوان البريد الإلكتروني محجوزين ولا يمكن استخدامهما لإنشاء حساب جديد. يمكن إعادة تنشيط المستخدم لاحقًا بواسطة مسؤول مفوض.';

  @override
  String get reactivateUser => 'إعادة تنشيط المستخدم';

  @override
  String get displayNameRequired => 'اسم العرض مطلوب';

  @override
  String get initialPassword => 'كلمة المرور الأولية';

  @override
  String get passwordTooShort => 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get roleRequired => 'الدور مطلوب';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get loggedInAs => 'تم تسجيل الدخول باسم:';

  @override
  String get refresh => 'تحديث';
}
