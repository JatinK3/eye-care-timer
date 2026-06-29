import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../generated/l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  final NotificationPermissionStatus notificationPermissionStatus;
  final VoidCallback continueToApp;
  final VoidCallback skipNotifications;

  const OnboardingPage({
    super.key,
    required this.notificationPermissionStatus,
    required this.continueToApp,
    required this.skipNotifications,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissionBlocked =
        widget.notificationPermissionStatus == NotificationPermissionStatus.disabled;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BlinkKind',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.onboardingSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Animated Explainer Slideshow
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _startAutoPlay(); // Reset autoplay timer on manual swipe
                },
                children: [
                  _ExplainerSlide(
                    title: "1. Every 20 Minutes",
                    subtitle: "Take a break to rest your focusing muscles.",
                    animation: const _ScreenTimerAnimation(),
                    isDark: isDark,
                  ),
                  _ExplainerSlide(
                    title: "2. Look 20 Feet Away",
                    subtitle: "Focus on a distant object to relax eye tension.",
                    animation: const _DepthTargetAnimation(),
                    isDark: isDark,
                  ),
                  _ExplainerSlide(
                    title: "3. For 20 Seconds",
                    subtitle: "Blink naturally and allow your eyes to refresh.",
                    animation: const _BlinkingEyeAnimation(),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final active = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active ? colorScheme.primary : colorScheme.outlineVariant,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Notifications Info & Permission Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark 
                      ? Colors.white.withOpacity(0.04) 
                      : Colors.black.withOpacity(0.02),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.08) 
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        permissionBlocked
                            ? AppLocalizations.of(context)!.onboardingNotificationsBlocked
                            : AppLocalizations.of(context)!.onboardingNotificationsHelp,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.continueToApp,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(AppLocalizations.of(context)!.onboardingAllowAndStart),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.skipNotifications,
                    child: Text(
                      AppLocalizations.of(context)!.onboardingContinueWithoutReminders,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExplainerSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget animation;
  final bool isDark;

  const _ExplainerSlide({
    required this.title,
    required this.subtitle,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark 
              ? Colors.white.withOpacity(0.03) 
              : Colors.black.withOpacity(0.015),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.03),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: animation,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide 1 Animation: Screen Timer ─────────────────────────────────────────
class _ScreenTimerAnimation extends StatefulWidget {
  const _ScreenTimerAnimation();

  @override
  State<_ScreenTimerAnimation> createState() => _ScreenTimerAnimationState();
}

class _ScreenTimerAnimationState extends State<_ScreenTimerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 140),
          painter: _ScreenTimerPainter(
            progress: _controller.value,
            primaryColor: colorScheme.primary,
            outlineColor: colorScheme.outline,
          ),
        );
      },
    );
  }
}

class _ScreenTimerPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color outlineColor;

  _ScreenTimerPainter({
    required this.progress,
    required this.primaryColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw monitor chassis
    final monitorPaint = Paint()
      ..color = outlineColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.65),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, monitorPaint);

    // Draw stand
    final standPath = Path()
      ..moveTo(w * 0.42, h * 0.75)
      ..lineTo(w * 0.35, h * 0.9)
      ..lineTo(w * 0.65, h * 0.9)
      ..lineTo(w * 0.58, h * 0.75)
      ..close();
    canvas.drawPath(standPath, monitorPaint);

    // Draw a countdown ring inside the screen
    final center = Offset(w / 2, h * 0.425);
    final radius = h * 0.22;

    // Background track
    final trackPaint = Paint()
      ..color = outlineColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Animate a sweeping timer arc
    final sweepAngle = -2 * math.pi * (1.0 - progress);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Mini hourglass inside
    final hourglassPaint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final hgPath = Path()
      ..moveTo(center.dx - 6, center.dy - 10)
      ..lineTo(center.dx + 6, center.dy - 10)
      ..lineTo(center.dx - 1, center.dy)
      ..lineTo(center.dx + 6, center.dy + 10)
      ..lineTo(center.dx - 6, center.dy + 10)
      ..lineTo(center.dx + 1, center.dy)
      ..close();
    canvas.drawPath(hgPath, hourglassPaint);
  }

  @override
  bool shouldRepaint(covariant _ScreenTimerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Slide 2 Animation: Depth / Target Shifting ──────────────────────────────
class _DepthTargetAnimation extends StatefulWidget {
  const _DepthTargetAnimation();

  @override
  State<_DepthTargetAnimation> createState() => _DepthTargetAnimationState();
}

class _DepthTargetAnimationState extends State<_DepthTargetAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 140),
          painter: _DepthTargetPainter(
            animationValue: _controller.value,
            primaryColor: colorScheme.primary,
            outlineColor: colorScheme.outline,
          ),
        );
      },
    );
  }
}

class _DepthTargetPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color outlineColor;

  _DepthTargetPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw vanishing perspective grids
    final gridPaint = Paint()
      ..color = outlineColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final vanishingPoint = Offset(w / 2, h * 0.35);

    // Draw floor grid lines
    for (double i = -1.0; i <= 2.0; i += 0.5) {
      canvas.drawLine(
        Offset(w * i, h * 0.95),
        vanishingPoint,
        gridPaint,
      );
    }
    // Horizontal depth lines
    for (double depth = 0.05; depth < 1.0; depth += 0.25) {
      final y = h * 0.35 + (h * 0.6) * depth;
      final xStart = w * 0.5 - (w * 1.5) * depth;
      final xEnd = w * 0.5 + (w * 1.5) * depth;
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), gridPaint);
    }

    // Vanishing horizon glow
    canvas.drawCircle(
      vanishingPoint,
      12.0,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withOpacity(0.25),
            primaryColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: vanishingPoint, radius: 12.0)),
    );

    // Focus Target dot shifting from near to far
    // T goes from 0.0 (near) to 1.0 (far)
    final t = animationValue;
    final targetY = h * 0.9 - (h * 0.55) * t;
    final targetX = w / 2;
    final targetOffset = Offset(targetX, targetY);
    
    // Scale size down as it gets further
    final targetRadius = 14.0 * (1.0 - t * 0.78);
    final opacity = 0.95 * (1.0 - t * 0.4);

    // Halo glow
    canvas.drawCircle(
      targetOffset,
      targetRadius * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withOpacity(opacity * 0.35),
            primaryColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: targetOffset, radius: targetRadius * 1.8)),
    );

    // Core target
    canvas.drawCircle(
      targetOffset,
      targetRadius * 0.75,
      Paint()
        ..color = primaryColor.withOpacity(opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      targetOffset,
      targetRadius * 0.3,
      Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DepthTargetPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ── Slide 3 Animation: Blinking Eye mascot ──────────────────────────────────
class _BlinkingEyeAnimation extends StatefulWidget {
  const _BlinkingEyeAnimation();

  @override
  State<_BlinkingEyeAnimation> createState() => _BlinkingEyeAnimationState();
}

class _BlinkingEyeAnimationState extends State<_BlinkingEyeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Replicate natural blink cadence: open for most of the loop,
    // quick shut at 80% to 85% of duration.
    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 4),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 140),
          painter: _BlinkingEyePainter(
            openAmount: _blinkAnim.value,
            primaryColor: colorScheme.primary,
            outlineColor: colorScheme.outline,
          ),
        );
      },
    );
  }
}

class _BlinkingEyePainter extends CustomPainter {
  final double openAmount;
  final Color primaryColor;
  final Color outlineColor;

  _BlinkingEyePainter({
    required this.openAmount,
    required this.primaryColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Draw outer decoration ring
    final decorationPaint = Paint()
      ..color = outlineColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, h * 0.4, decorationPaint);

    // Draw eye boundaries
    final eyeW = w * 0.44;
    final eyeH = h * 0.54;
    final eyeCenter = Offset(w / 2, h / 2);

    final startX = w / 2 - eyeW / 2;
    final endX = w / 2 + eyeW / 2;
    final double verticalScale = 0.05 + (0.42 * openAmount);
    final double topOffset = (h / 2) - (eyeH * verticalScale);
    final double bottomOffset = (h / 2) + (eyeH * verticalScale);

    final outerPath = Path()
      ..moveTo(startX, h / 2)
      ..quadraticBezierTo(w / 2, topOffset, endX, h / 2)
      ..quadraticBezierTo(w / 2, bottomOffset, startX, h / 2)
      ..close();

    // Eyeball background fill
    canvas.save();
    if (openAmount > 0.05) {
      final eyeballPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawPath(outerPath, eyeballPaint);

      canvas.clipPath(outerPath);

      // Iris
      final irisRadius = eyeH * 0.42;
      canvas.drawCircle(
        eyeCenter,
        irisRadius,
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.fill,
      );

      // Pupil
      canvas.drawCircle(
        eyeCenter,
        irisRadius * 0.45,
        Paint()
          ..color = Colors.black.withOpacity(0.9)
          ..style = PaintingStyle.fill,
      );

      // Reflection dot
      canvas.drawCircle(
        eyeCenter + Offset(-irisRadius * 0.25, -irisRadius * 0.25),
        irisRadius * 0.18,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
    canvas.restore();

    // Eyelids
    final lidPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final upperPath = Path()
      ..moveTo(startX, h / 2)
      ..quadraticBezierTo(w / 2, topOffset, endX, h / 2);
    final lowerPath = Path()
      ..moveTo(startX, h / 2)
      ..quadraticBezierTo(w / 2, bottomOffset, endX, h / 2);

    canvas.drawPath(upperPath, lidPaint);
    canvas.drawPath(lowerPath, lidPaint);
  }

  @override
  bool shouldRepaint(covariant _BlinkingEyePainter oldDelegate) =>
      oldDelegate.openAmount != openAmount;
}
