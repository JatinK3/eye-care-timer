/// One user-recorded drink of water.
///
/// BlinkKind used to retain only a daily glass total. Health providers require
/// exact timestamps, so only events created after this model was introduced are
/// eligible for sync. Existing daily totals are deliberately not converted.
class HydrationIntakeEvent {
  final String id;
  final DateTime recordedAt;
  final int volumeMl;
  final int version;
  final bool isDeleted;

  const HydrationIntakeEvent({
    required this.id,
    required this.recordedAt,
    required this.volumeMl,
    this.version = 0,
    this.isDeleted = false,
  });

  HydrationIntakeEvent copyWith({int? version, bool? isDeleted}) {
    return HydrationIntakeEvent(
      id: id,
      recordedAt: recordedAt,
      volumeMl: volumeMl,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory HydrationIntakeEvent.fromJson(Map<String, dynamic> json) {
    return HydrationIntakeEvent(
      id: json['id'] as String,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        json['recordedAt'] as int,
      ),
      volumeMl: json['volumeMl'] as int,
      version: json['version'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'recordedAt': recordedAt.millisecondsSinceEpoch,
    'volumeMl': volumeMl,
    'version': version,
    'isDeleted': isDeleted,
  };
}
