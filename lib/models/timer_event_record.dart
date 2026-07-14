enum TimerEventType {
  workCompleted,
  workCancelled,
  breakSkipped,
  breakPostponed,
  blinkReminderAcknowledged,
}

enum FocusMood {
  deepFocus,
  creative,
  tired,
  distracted,
  stressed;

  String get displayName {
    switch (this) {
      case FocusMood.deepFocus: return 'Deep Focus';
      case FocusMood.creative: return 'Creative';
      case FocusMood.tired: return 'Tired';
      case FocusMood.distracted: return 'Distracted';
      case FocusMood.stressed: return 'Stressed';
    }
  }
  
  String get emoji {
    switch (this) {
      case FocusMood.deepFocus: return '🧠';
      case FocusMood.creative: return '✨';
      case FocusMood.tired: return '🥱';
      case FocusMood.distracted: return '🌪️';
      case FocusMood.stressed: return '📈';
    }
  }
}

class TimerEventRecord {
  final String id;
  final DateTime timestamp;
  final TimerEventType type;
  final int durationSeconds;
  final FocusMood? mood;

  const TimerEventRecord({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.durationSeconds,
    this.mood,
  });

  factory TimerEventRecord.fromJson(Map<String, dynamic> json) {
    FocusMood? parsedMood;
    if (json["mood"] != null) {
      parsedMood = FocusMood.values.firstWhere(
        (e) => e.name == json["mood"],
        orElse: () => FocusMood.deepFocus,
      );
    }

    return TimerEventRecord(
      id: json["id"] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json["timestamp"] as int),
      type: TimerEventType.values.firstWhere(
        (e) => e.name == json["type"],
        orElse: () => TimerEventType.workCompleted,
      ),
      durationSeconds: json["durationSeconds"] as int? ?? 0,
      mood: parsedMood,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    "id": id,
    "timestamp": timestamp.millisecondsSinceEpoch,
    "type": type.name,
    "durationSeconds": durationSeconds,
    if (mood != null) "mood": mood!.name,
  };
}
