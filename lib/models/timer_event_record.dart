enum TimerEventType {
  workCompleted,
  workCancelled,
  breakSkipped,
  breakPostponed,
}

class TimerEventRecord {
  final String id;
  final DateTime timestamp;
  final TimerEventType type;
  final int durationSeconds;

  const TimerEventRecord({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.durationSeconds,
  });

  factory TimerEventRecord.fromJson(Map<String, dynamic> json) {
    return TimerEventRecord(
      id: json["id"] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json["timestamp"] as int),
      type: TimerEventType.values.firstWhere(
        (e) => e.name == json["type"],
        orElse: () => TimerEventType.workCompleted,
      ),
      durationSeconds: json["durationSeconds"] as int? ?? 0,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    "id": id,
    "timestamp": timestamp.millisecondsSinceEpoch,
    "type": type.name,
    "durationSeconds": durationSeconds,
  };
}
