import '../../../domain/entities/payment_attachment.dart';

class PaymentAttachmentModel {
  static PaymentAttachment fromMap(Map<String, dynamic> map) {
    return PaymentAttachment(
      id: map['id'] as String,
      paymentId: map['payment_id'] as String,
      filePath: map['file_path'] as String,
      originalFileName: map['original_file_name'] as String,
      fileType: map['file_type'] as String,
      fileSizeBytes: map['file_size_bytes'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(PaymentAttachment attachment) {
    return {
      'id': attachment.id,
      'payment_id': attachment.paymentId,
      'file_path': attachment.filePath,
      'original_file_name': attachment.originalFileName,
      'file_type': attachment.fileType,
      'file_size_bytes': attachment.fileSizeBytes,
      'created_at': attachment.createdAt.toIso8601String(),
    };
  }
}
