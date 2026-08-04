class PaymentAttachment {
  final String id;
  final String paymentId;
  final String filePath; // relative to app attachments dir
  final String originalFileName;
  final String fileType; // pdf, jpg, png
  final int fileSizeBytes;
  final DateTime createdAt;

  const PaymentAttachment({
    required this.id,
    required this.paymentId,
    required this.filePath,
    required this.originalFileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  PaymentAttachment copyWith({
    String? id,
    String? paymentId,
    String? filePath,
    String? originalFileName,
    String? fileType,
    int? fileSizeBytes,
    DateTime? createdAt,
  }) {
    return PaymentAttachment(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      filePath: filePath ?? this.filePath,
      originalFileName: originalFileName ?? this.originalFileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
