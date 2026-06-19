class WorkSessionRecord {
  final String id;
  final DateTime completedAt;
  final int durationSeconds;

  const WorkSessionRecord({
    required this.id,
    required this.completedAt,
    required this.durationSeconds,
  });

  factory WorkSessionRecord.completed({
    required DateTime completedAt,
    required int durationSeconds,
  }) {
    return WorkSessionRecord(
      id: completedAt.millisecondsSinceEpoch.toString(),
      completedAt: completedAt,
      durationSeconds: durationSeconds,
    );
  }

  factory WorkSessionRecord.fromJson(Map<String, dynamic> json) {
    return WorkSessionRecord(
      id: json["id"] as String,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        json["completedAt"] as int,
      ),
      durationSeconds: json["durationSeconds"] as int,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    "id": id,
    "completedAt": completedAt.millisecondsSinceEpoch,
    "durationSeconds": durationSeconds,
  };
}
