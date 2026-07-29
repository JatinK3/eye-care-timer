enum HealthSyncOperationType { upsertHydration, deleteHydration }

/// A durable health-store change waiting to be flushed while the app is in the
/// foreground. The event ID is also the Health Connect client record ID.
class HealthSyncOutboxOperation {
  final String id;
  final HealthSyncOperationType type;
  final String hydrationEventId;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;

  const HealthSyncOutboxOperation({
    required this.id,
    required this.type,
    required this.hydrationEventId,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  HealthSyncOutboxOperation copyWith({int? attempts, String? lastError}) {
    return HealthSyncOutboxOperation(
      id: id,
      type: type,
      hydrationEventId: hydrationEventId,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  factory HealthSyncOutboxOperation.fromJson(Map<String, dynamic> json) {
    return HealthSyncOutboxOperation(
      id: json['id'] as String,
      type: HealthSyncOperationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => HealthSyncOperationType.upsertHydration,
      ),
      hydrationEventId: json['hydrationEventId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'type': type.name,
    'hydrationEventId': hydrationEventId,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'attempts': attempts,
    if (lastError != null) 'lastError': lastError,
  };
}
