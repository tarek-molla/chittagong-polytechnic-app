// =============================================================================
// lib/widgets/premium_refresh_indicator.dart
// CPI App — Custom pull-to-refresh with minimal 3-bar jumping equalizer
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A minimal pull-to-refresh indicator tailored to the CPI App aesthetic:
/// - Clean, background-less 3-bar equalizer animation matching your CSS style
/// - Subtle, subtle accent tinting without heavy container backgrounds or pill outlines
/// - Native-feeling overscroll tracking with tactile haptic feedback
class PremiumRefreshIndicator extends StatefulWidget {
  /// The scrollable child (must be a ScrollView, e.g., ListView, CustomScrollView)
  final Widget child;

  /// Called when the user pulls down far enough to trigger a refresh
  final Future<void> Function() onRefresh;

  /// Primary accent color (defaults to blue/purple matching CSS design)
  final Color color;

  /// How far the user must pull (in logical pixels) before triggering refresh
  final double triggerDistance;

  const PremiumRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color = const Color(0xFF076FE5),
    this.triggerDistance = 80.0,
  });

  @override
  State<PremiumRefreshIndicator> createState() =>
      _PremiumRefreshIndicatorState();
}

class _PremiumRefreshIndicatorState extends State<PremiumRefreshIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _slideController;

  double _pullOffset = 0.0;
  bool _isRefreshing = false;
  bool _isPulling = false;
  double _lastScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isRefreshing = true;
      _isPulling = false;
    });

    await _slideController.forward();
    _waveController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _waveController.stop();
        _waveController.value = 0;
        await _slideController.reverse();

        setState(() {
          _isRefreshing = false;
          _pullOffset = 0;
        });
        HapticFeedback.lightImpact();
      }
    }
  }

  void _resetPullState() {
    if (_isPulling) {
      setState(() {
        _isPulling = false;
        _pullOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pullOffset / widget.triggerDistance).clamp(0.0, 1.0);
    final triggered = progress >= 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Scrollable content
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_isRefreshing) return false;

            if (notification is OverscrollNotification) {
              if (notification.overscroll < 0) {
                setState(() {
                  _isPulling = true;
                  _pullOffset =
                      (_pullOffset + notification.overscroll.abs() * 0.75)
                          .clamp(0.0, widget.triggerDistance * 1.5);
                });
              }
              return false;
            }

            if (notification is ScrollUpdateNotification) {
              final pixels = notification.metrics.pixels;

              if (pixels <= 0) {
                final delta = _lastScrollPosition - pixels;
                if (delta > 0) {
                  setState(() {
                    _isPulling = true;
                    _pullOffset = (_pullOffset + delta * 0.75).clamp(
                      0.0,
                      widget.triggerDistance * 1.5,
                    );
                  });
                } else if (pixels > 0 && _isPulling && !triggered) {
                  _resetPullState();
                }
              }

              _lastScrollPosition = pixels;
              return false;
            }

            if (notification is ScrollEndNotification) {
              if (_isPulling) {
                if (triggered) {
                  _handleRefresh();
                } else {
                  _resetPullState();
                }
              }
              return false;
            }

            return false;
          },
          child: widget.child,
        ),

        // Floating Minimal Indicator
        if (_isPulling || _isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  final baseOffset = _isRefreshing
                      ? 16.0
                      : (-40.0 + (progress * 55.0));

                  final animatedOffset = _isRefreshing
                      ? baseOffset + (8 * _slideController.value)
                      : baseOffset;

                  return Transform.translate(
                    offset: Offset(0, animatedOffset),
                    child: Opacity(
                      opacity: _isRefreshing
                          ? 1.0
                          : (progress * 1.2).clamp(0.0, 1.0),
                      child: _MinimalEqualizerVisual(
                        accent: widget.color,
                        progress: progress,
                        isRefreshing: _isRefreshing,
                        waveController: _waveController,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _MinimalEqualizerVisual extends StatelessWidget {
  final Color accent;
  final double progress;
  final bool isRefreshing;
  final AnimationController waveController;

  const _MinimalEqualizerVisual({
    required this.accent,
    required this.progress,
    required this.isRefreshing,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: waveController,
        builder: (context, child) {
          return SizedBox(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBar(0, 0.0),
                const SizedBox(width: 5),
                _buildBar(1, 0.16),
                const SizedBox(width: 5),
                _buildBar(2, 0.32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBar(int index, double delay) {
    double barHeight;
    double opacity;
    double translateY = 0.0;

    if (isRefreshing) {
      // Keyframe implementation matching the React CSS logic (0.8s loop)
      final t = (waveController.value - delay) % 1.0;
      final adjustedT = t < 0 ? t + 1.0 : t;

      // Peak height at 40% animation phase
      if (adjustedT >= 0.2 && adjustedT <= 0.6) {
        final peakProgress = 1.0 - ((adjustedT - 0.4).abs() / 0.2);
        barHeight = 22.0 + (10.0 * peakProgress);
        translateY = -4.0 * peakProgress;
        opacity = 0.75 + (0.25 * peakProgress);
      } else {
        barHeight = 22.0;
        translateY = 0.0;
        opacity = 0.75;
      }
    } else {
      // Scaling height tied to pull progress
      final scaledProgress = (progress * (1.0 - index * 0.12)).clamp(0.2, 1.0);
      barHeight = 10.0 + (16.0 * scaledProgress);
      opacity = 0.4 + (0.6 * scaledProgress);
    }

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Container(
        width: 10.0,
        height: barHeight,
        decoration: BoxDecoration(
          color: accent.withOpacity(opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
