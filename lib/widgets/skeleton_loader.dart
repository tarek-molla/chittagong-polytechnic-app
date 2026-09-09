// =============================================================================
// lib/widgets/skeleton_loader.dart
// Premium Shimmer & Skeleton Loaders for Asynchronous Lists and Cards
// =============================================================================

import 'package:flutter/material.dart';
import '../core/theme_provider.dart';

class SkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    final r = widget.borderRadius ?? BorderRadius.circular(18);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withAlpha((_animation.value * 20).toInt()),
                      Colors.white.withAlpha((_animation.value * 10).toInt()),
                    ]
                  : [
                      Colors.grey.shade200.withAlpha((_animation.value * 255).toInt()),
                      Colors.grey.shade100.withAlpha((_animation.value * 255).toInt()),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(8),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isDark
                                ? Colors.white.withAlpha(25)
                                : Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 90,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isDark
                                ? Colors.white.withAlpha(15)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDark
                      ? Colors.white.withAlpha(12)
                      : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({
    super.key,
    int? itemCount,
    int count = 4,
    this.itemHeight = 110,
  }) : count = itemCount ?? count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: count,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}
