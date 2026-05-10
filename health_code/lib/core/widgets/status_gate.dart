// lib/core/widgets/status_gate.dart
// StatusGate — гейт-виджет для ограничения доступа по статусу (Закрытый клуб).
// Проверяет subscription_status (как ключ БД) из ProfileProvider.
// Используется на: P-1 (дни), P-4 (рецепт), P-5 (витамины), PH-1 (фото), Quick Actions.
// Apple-Reviewer-Safe: не содержит кнопок "купить" или внешних ссылок.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

/// Minimum tier required for access
enum RequiredTier { black, gold, familyGold }

/// Wraps child with status check.
/// If user's tier is insufficient, shows [lockedBuilder] or default lock overlay.
class StatusGate extends ConsumerWidget {
  final RequiredTier requiredTier;
  final Widget child;
  /// Optional custom locked UI. If null, default lock card is shown.
  final Widget Function(BuildContext context, String currentStatus)? lockedBuilder;
  /// If true, shows child but with a lock overlay (for preview mode like P-2 ingredients).
  final bool previewMode;

  const StatusGate({
    super.key,
    required this.requiredTier,
    required this.child,
    this.lockedBuilder,
    this.previewMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final status = profile.subscriptionStatus ?? 'white'; // Key is legacy but UI is safe
    final trialStart = profile.trialStart;

    // Effective tier: Check if trial is active or status is set
    String effectiveTier = status;
    if (trialStart != null && DateTime.now().difference(trialStart).inDays < 3) {
      effectiveTier = 'gold'; // Trial gives gold access
    }

    final hasAccess = _checkAccess(effectiveTier, requiredTier);

    if (hasAccess) return child;

    // Preview mode: show content with overlay
    if (previewMode) {
      return Stack(children: [
        child,
        Positioned.fill(child: _LockOverlay(
          requiredTier: requiredTier,
          currentStatus: status,
        )),
      ]);
    }

    // Custom locked builder
    if (lockedBuilder != null) {
      return lockedBuilder!(context, status);
    }

    // Default lock card
    return _DefaultLockCard(requiredTier: requiredTier, currentStatus: status);
  }

  static bool _checkAccess(String effectiveTier, RequiredTier required) {
    const tierRank = {'white': 0, 'black': 1, 'gold': 2, 'family_gold': 3};
    final userRank = tierRank[effectiveTier] ?? 0;
    final requiredRank = switch (required) {
      RequiredTier.black => 1,
      RequiredTier.gold => 2,
      RequiredTier.familyGold => 3,
    };
    return userRank >= requiredRank;
  }
}

/// Quick check function for imperative use (e.g., in onTap handlers)
bool hasStatusAccess(WidgetRef ref, RequiredTier required) {
  final profile = ref.read(profileProvider);
  final status = profile.subscriptionStatus ?? 'white';
  final trialStart = profile.trialStart;
  
  String effectiveTier = status;
  if (trialStart != null && DateTime.now().difference(trialStart).inDays < 3) {
      effectiveTier = 'gold';
  }

  const tierRank = {'white': 0, 'black': 1, 'gold': 2, 'family_gold': 3};
  final userRank = tierRank[effectiveTier] ?? 0;
  final requiredRank = switch (required) {
    RequiredTier.black => 1,
    RequiredTier.gold => 2,
    RequiredTier.familyGold => 3,
  };
  return userRank >= requiredRank;
}

/// Shows a "locked" snackbar
void showLockedSnackbar(BuildContext context, RequiredTier tier) {
  final tierName = switch (tier) {
    RequiredTier.black => 'Black',
    RequiredTier.gold => 'Gold',
    RequiredTier.familyGold => 'Group Gold',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('🔒 Необходим статус $tierName'),
    backgroundColor: const Color(0xFF374151),
    duration: const Duration(seconds: 3),
  ));
}

// ────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────

class _DefaultLockCard extends StatelessWidget {
  final RequiredTier requiredTier;
  final String currentStatus;

  const _DefaultLockCard({required this.requiredTier, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final tierName = requiredTier == RequiredTier.black ? 'Black' : 'Gold';
    final color = requiredTier == RequiredTier.black
        ? const Color(0xFF374151)
        : const Color(0xFF4C1D95);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, size: 48, color: color),
        const SizedBox(height: 12),
        Text(
          'Требуется статус $tierName',
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 16,
            fontWeight: FontWeight.w700, color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Данный функционал доступен только для участников клуба со статусом $tierName. Обратитесь к куратору программы для изменения твоего статуса.',
          style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13,
            color: AppColors.textSecondary, height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        // Убрали кнопку "Узнать подробнее" (которая вела на экран оплаты/подписки).
      ]),
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final RequiredTier requiredTier;
  final String currentStatus;

  const _LockOverlay({required this.requiredTier, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final tierName = switch (requiredTier) {
      RequiredTier.black => 'Black',
      RequiredTier.gold => 'Gold',
      RequiredTier.familyGold => 'Group Gold',
    };
    return GestureDetector(
      onTap: () => showLockedSnackbar(context, requiredTier),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline_rounded, size: 32, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 8),
            Text('Требуется $tierName',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          ]),
        ),
      ),
    );
  }
}
