import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashQuotePage extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashQuotePage({super.key, required this.onComplete});

  @override
  State<SplashQuotePage> createState() => _SplashQuotePageState();
}

class _SplashQuotePageState extends State<SplashQuotePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final String _selectedQuote;
  Timer? _autoAdvanceTimer;

  static const List<String> _defaultQuotes = [
    'Blink kind, work smart.',
    'A brief pause brings clearer focus.',
    'Small breaks, giant leaps.',
    'Your eyes work hard. Let them rest for a moment.',
    'Rest your vision to see your goals clearly.',
    'Take a breath. Relax your shoulders. Look far away.',
    'Work with passion, rest with intention.',
    'A healthy habit today is a clearer tomorrow.',
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _selectedQuote = _defaultQuotes[random.nextInt(_defaultQuotes.length)];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // Auto advance after 2.5 seconds (1000ms animation + 1500ms display)
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withAlpha(200),
                      ]
                    : [
                        theme.colorScheme.surface,
                        theme.colorScheme.primaryContainer.withAlpha(50),
                      ],
              ),
            ),
          ),
          // Center quote content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _selectedQuote,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'BlinkKind',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Top skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TextButton(
                onPressed: widget.onComplete,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                child: const Text('Skip'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
