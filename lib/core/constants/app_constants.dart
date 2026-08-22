class AppConstants {
  AppConstants._();

  static const String appName = 'PayMe';
  static const String databaseName = 'payme.db';
  static const int schemaVersion = 17;

  static const String attachmentsDirName = 'attachments';
  static const String logosDirName = 'logos';
  static const String logsDirName = 'logs';
  static const String tempDirName = 'temp';

  static const int maxAttachmentSizeMB = 5;
  static const List<String> allowedAttachmentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
}
