import '../../domain/entities/client_visibility.dart';

class ClientVisibilityModel extends ClientVisibility {
  const ClientVisibilityModel({
    required super.clientId,
    required super.userId,
    super.syncedAt,
  });

  factory ClientVisibilityModel.fromMap(Map<String, dynamic> map) {
    return ClientVisibilityModel(
      clientId: map['client_id'] as String,
      userId: map['user_id'] as String,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String).toLocal() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'user_id': userId,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
    };
  }

  factory ClientVisibilityModel.fromEntity(ClientVisibility entity) {
    return ClientVisibilityModel(
      clientId: entity.clientId,
      userId: entity.userId,
      syncedAt: entity.syncedAt,
    );
  }
}
