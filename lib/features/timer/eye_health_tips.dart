class EyeHealthTip {
  final String title;
  final String action;
  final String detail;

  const EyeHealthTip({
    required this.title,
    required this.action,
    required this.detail,
  });
}

class EyeHealthTips {
  static const List<EyeHealthTip> all = [
    EyeHealthTip(
      title: '20-20-20 reset',
      action: 'Look 20 feet away for 20 seconds.',
      detail: 'Distance focus relaxes the focusing muscle that stays engaged during close screen work.',
    ),
    EyeHealthTip(
      title: 'Blink moisture',
      action: 'Blink slowly 10 times.',
      detail: 'Complete blinks spread the tear film and help reduce dry, scratchy eyes.',
    ),
    EyeHealthTip(
      title: 'Shoulder release',
      action: 'Drop your shoulders and unclench your jaw.',
      detail: 'Screen focus often brings hidden neck, jaw, and shoulder tension along with eye strain.',
    ),
    EyeHealthTip(
      title: 'Near-far focus',
      action: 'Shift focus from your thumb to a distant object.',
      detail: 'Alternating near and far focus gently exercises accommodation without staring at the screen.',
    ),
    EyeHealthTip(
      title: 'Soft gaze',
      action: 'Relax your gaze and notice the edges of the room.',
      detail: 'A wider field of view can break the tunnel vision that builds during intense tasks.',
    ),
    EyeHealthTip(
      title: 'Screen distance',
      action: 'Check that your screen is about an arm away.',
      detail: 'Comfortable distance and slightly lower eye level reduce strain during long sessions.',
    ),
  ];

  static EyeHealthTip at(int index) {
    return all[index % all.length];
  }

  static EyeHealthTip breakTipForRemaining({
    required int remainingSeconds,
    required int totalDurationSeconds,
    int offset = 0,
  }) {
    final total = totalDurationSeconds <= 0 ? 1 : totalDurationSeconds;
    final elapsed = (total - remainingSeconds).clamp(0, total);
    final bucket = elapsed ~/ 8;
    return at(bucket + offset);
  }
}
