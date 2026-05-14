// lib/features/profile/presentation/u12_status_screen.dart
// U-12: Статус профиля — IAP paywall, email sync, account management
// Спека: screens-map.md §U-12


import 'package:flutter/material.dart';
import 'package:ejeweeka_app/shared/widgets/hc_gradient_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class U12StatusScreen extends ConsumerWidget {
  const U12StatusScreen({super.key});

  // удалили _webBillingUrl


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final currentStatus = profile.subscriptionStatus ?? 'white';

    // F5: Calculate trial remaining days
    int? trialDays;
    final trialStart = profile.trialStart;
    if (trialStart != null) {
      final start = DateTime.tryParse(trialStart.toString());
      if (start != null) {
        final remaining = 3 - DateTime.now().difference(start).inDays;
        if (remaining > 0) trialDays = remaining;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Статус профиля',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1 — Текущий план ─────────────────────────────
          _currentPlanCard(currentStatus, trialDays),
          const SizedBox(height: 20),

          // ── Блок 2 — Сравнение статусов ───────────────────────
          const Text('СРАВНЕНИЕ СТАТУСОВ',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 10),

          _statusCard(
            name: 'White',
            price: 'Базовый',
            features: ['Базовый план питания', 'Трекер веса', '2 цветовые темы'],
            color: const Color(0xFF9CA3AF),
            isActive: currentStatus == 'white',
          ),
          const SizedBox(height: 8),
          _statusCard(
            name: 'Black',
            price: 'Расширенный',
            features: ['Полные рецепты', 'Витамины и БАДы', 'Умный отчёты', '5 цветовых тем', 'Health Connect'],
            color: const Color(0xFF1A1A1A),
            isActive: currentStatus == 'black',
          ),
          const SizedBox(height: 8),
          _statusCard(
            name: 'Gold',
            price: 'Максимальный',
            features: ['Всё из Black', 'Фото-анализ (5/день)', 'План тренировок', '7 тем', 'HC-чат (RAG)'],
            color: const Color(0xFFB45309),
            isActive: currentStatus == 'gold',
          ),
          const SizedBox(height: 24),

          // ── Блок IAP — Apple StoreKit ──────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: HcGradientButton(
              onPressed: () {
                // TODO: StoreKit IAP purchase flow
              },
              text: 'Улучшить статус',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: StoreKit restore purchases
              },
              child: const Text('Восстановить покупки Apple',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                  color: AppColors.textSecondary)),
            ),
          ),

          const SizedBox(height: 24),
          // ── Блок 3 — Существующий профиль ──────────────────────
          const Text('СИНХРОНИЗАЦИЯ',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Email magic code login flow
              },
              child: const Text('У меня уже есть профиль',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppColors.primary,
                  decoration: TextDecoration.underline)),
            ),
          ),

          const SizedBox(height: 24),
          // ── Блок 4 — Удаление аккаунта ────────────────────────
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Account deletion flow
              },
              child: const Text('Удалить аккаунт',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                  color: Color(0xFFEF4444))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _currentPlanCard(String status, int? trialDays) {
    final label = switch (status) {
      'black' => 'ejeweeka black',
      'gold' => 'ejeweeka gold',
      _ => 'ejeweeka white',
    };

    final color = switch (status) {
      'black' => const Color(0xFF1A1A1A),
      'gold' => const Color(0xFFB45309),
      _ => AppColors.textSecondary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 18,
            fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        if (trialDays != null && trialDays > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Триал: осталось $trialDays дней',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
        const SizedBox(height: 8),
        Text('Текущий активный статус',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _statusCard({
    required String name,
    required String price,
    required List<String> features,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : const Color(0xFFE5E7EB),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(name,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.w700, color: color)),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Активен',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                  fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
            ),
          ],
          const Spacer(),
          Text(price, style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 10),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.check_circle_outline_rounded, size: 15,
              color: isActive ? const Color(0xFF4CAF50) : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(f, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.3)),
          ]),
        )),
      ]),
    );
  }
}
