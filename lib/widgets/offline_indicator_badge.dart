// =============================================================================
// lib/widgets/offline_indicator_badge.dart
// Real-time network and sync status banner/indicator
// =============================================================================

import 'package:flutter/material.dart';
import '../services/offline_storage_service.dart';

class OfflineIndicatorBadge extends StatelessWidget {
  final bool showOnlyWhenOffline;

  const OfflineIndicatorBadge({
    super.key,
    this.showOnlyWhenOffline = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineStorageService.isOnlineNotifier,
      builder: (context, isOnline, _) {
        if (isOnline && showOnlyWhenOffline) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF10B981).withAlpha(30)
                : const Color(0xFFEF4444).withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOnline
                  ? const Color(0xFF10B981).withAlpha(80)
                  : const Color(0xFFEF4444).withAlpha(80),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Online (Synced)' : 'Offline Mode (Local Cache)',
                style: TextStyle(
                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Geist',
                ),
              ),
              if (!isOnline && OfflineStorageService.pendingSyncCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${OfflineStorageService.pendingSyncCount} queued',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
