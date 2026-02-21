/// Animated Speed Display - Odometer-style digit roll animation.
///
/// Each digit animates independently when the speed changes.
/// Old digits slide up and fade out, new digits slide in from below.
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// Displays speed with independent per-digit roll animations.
///
/// Digits that don't change remain static. Changed digits roll
/// with a 50ms cascade delay from left to right.
class AnimatedSpeedDisplay extends StatelessWidget {
  final double speed;
  final TextStyle? style;
  final Duration digitDuration;

  const AnimatedSpeedDisplay({
    super.key,
    required this.speed,
    this.style,
    this.digitDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final speedText = speed.toStringAsFixed(0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < speedText.length; i++)
          _AnimatedDigit(
            digit: speedText[i],
            style: style ?? Theme.of(context).textTheme.displayLarge!,
            duration: digitDuration,
            delay: Duration(milliseconds: i * 50),
          ),
      ],
    );
  }
}

/// Single digit with slide + fade animation.
class _AnimatedDigit extends StatefulWidget {
  final String digit;
  final TextStyle style;
  final Duration duration;
  final Duration delay;

  const _AnimatedDigit({
    required this.digit,
    required this.style,
    required this.duration,
    required this.delay,
  });

  @override
  State<_AnimatedDigit> createState() => _AnimatedDigitState();
}

class _AnimatedDigitState extends State<_AnimatedDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideOut;
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeOut;
  late Animation<double> _fadeIn;

  String _currentDigit = '';
  String _previousDigit = '';
  bool _isAnimating = false;
  bool _isFirstBuild = true;
  Timer? _delayTimer;

  // Cached digit dimensions to avoid TextPainter.layout() on every build
  double _cachedDigitWidth = 0;
  double _cachedDigitHeight = 0;
  TextStyle? _cachedStyle;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _slideIn = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _currentDigit = widget.digit;
        });
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _previousDigit = _currentDigit;
      _currentDigit = widget.digit;

      // Skip the very first update — _currentDigit was already set
      // from widget.digit in initState, so no visible change needed.
      if (_isFirstBuild) {
        _isFirstBuild = false;
        return;
      }

      _isAnimating = true;
      _controller.reset();

      // Cancel any pending cascade delay from a previous digit change
      _delayTimer?.cancel();

      // Apply cascade delay
      if (widget.delay > Duration.zero) {
        _delayTimer = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cache digit dimensions — only recalculate when style changes
    if (_cachedStyle != widget.style) {
      _cachedStyle = widget.style;
      final textPainter = TextPainter(
        text: TextSpan(text: '0', style: widget.style),
        textDirection: TextDirection.ltr,
      )..layout();
      _cachedDigitWidth = textPainter.width;
      _cachedDigitHeight = textPainter.height;
      textPainter.dispose();
    }

    final digitWidth = _cachedDigitWidth;
    final digitHeight = _cachedDigitHeight;

    return SizedBox(
      width: digitWidth,
      height: digitHeight,
      child: ClipRect(
        child: Stack(
          children: [
            if (_isAnimating) ...[
              // Old digit sliding out
              SlideTransition(
                position: _slideOut,
                child: FadeTransition(
                  opacity: _fadeOut,
                  child: SizedBox(
                    width: digitWidth,
                    child: Text(
                      _previousDigit,
                      style: widget.style,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // New digit sliding in
              SlideTransition(
                position: _slideIn,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SizedBox(
                    width: digitWidth,
                    child: Text(
                      _currentDigit,
                      style: widget.style,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ] else
              // Static digit
              SizedBox(
                width: digitWidth,
                child: Text(
                  _currentDigit,
                  style: widget.style,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
