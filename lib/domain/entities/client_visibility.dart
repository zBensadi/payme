class ClientVisibility {
  final String clientId;
  final String userId;
  final DateTime? syncedAt;

  const ClientVisibility({
    required this.clientId,
    required this.userId,
    this.syncedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientVisibility &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          userId == other.userId;

  @override
  int get hashCode => clientId.hashCode ^ userId.hashCode;
}
