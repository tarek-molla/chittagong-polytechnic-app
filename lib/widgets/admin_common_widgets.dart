// =============================================================================
// lib/widgets/admin_common_widgets.dart
// Reusable Glassmorphism Widgets for CPI Admin Panel
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme_provider.dart';

/// AdminGlassCard - Reusable glass card with backdrop filter
class AdminGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;

  const AdminGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.showBorder = true,
    this.borderColor,
    this.boxShadow,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color:
                    borderColor ??
                    (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05)),
              )
            : null,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color:
                backgroundColor ??
                (isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.85)),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// AdminSearchBar - Glass search with clear button
class AdminSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final String? initialValue;
  final bool showClearButton;
  final VoidCallback? onClear;

  const AdminSearchBar({
    super.key,
    required this.onChanged,
    required this.hintText,
    this.initialValue,
    this.showClearButton = true,
    this.onClear,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
    widget.onChanged(_controller.text);
  }

  void _clearText() {
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
    if (widget.onClear != null) widget.onClear!();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF6B7280),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (value) => _onTextChanged(),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Geist',
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black54,
                      fontFamily: 'Geist',
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (widget.showClearButton && _hasText)
                TextButton(
                  onPressed: _clearText,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AdminFilterChips - Semester/status filter chips
class AdminFilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final bool isDark;

  const AdminFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF59E0B).withOpacity(0.3)
                      : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : (isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.1)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.white : Colors.black54),
                    fontSize: 12,
                    fontFamily: 'Geist',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// AdminLoadingShimmer - Loading placeholder with built-in animation
class AdminLoadingShimmer extends StatefulWidget {
  final double? height;
  final double? width;

  const AdminLoadingShimmer({super.key, this.height, this.width});

  @override
  State<AdminLoadingShimmer> createState() => _AdminLoadingShimmerState();
}

class _AdminLoadingShimmerState extends State<AdminLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.7),
          child: Container(
            height: widget.height ?? 200,
            width: widget.width ?? double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

/// AdminEmptyState - Empty list with icon
class AdminEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  const AdminEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

/// AdminErrorState - Error with retry
class AdminErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const AdminErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: isDark
                ? Colors.red.withOpacity(0.6)
                : Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AdminStatusBadge - Status badge with color
class AdminStatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final bool isDark;

  const AdminStatusBadge({
    super.key,
    required this.status,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Geist',
        ),
      ),
    );
  }
}
