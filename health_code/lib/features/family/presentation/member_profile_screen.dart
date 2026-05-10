// lib/features/family/presentation/member_profile_screen.dart
// F-2: Профиль участника — просмотр данных члена семьи (read-only)
// Спека: screens-map.md §F-2
//   Блок 1 — Информация (имя, возраст, цель, ограничения)
//   Блок 2 — Сегодняшний план
//   Блок 3 — Краткий прогресс (калории план/факт, вес)
//   Доступ: Group Gold (владелец)

import 'package:flutter/material.dart';
import 'package:health_code/core/theme/app_theme.dart';

// Forward-declared member type from F-1 — accepts any object with .name/.status
class MemberProfileScreen extends StatelessWidget {
  final dynamic member;
  const MemberProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final name = member.name as String? ?? 'Участник';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: Text(name,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Информация ───────────────────────────────
          _infoCard(name),
          const SizedBox(height: 20),

          // ── Блок 2: Сегодняшний план ────────────────────────
          _todayPlan(),
          const SizedBox(height: 20),

          // ── Блок 3: Краткий прогресс ────────────────────────
          _progressSummary(),
        ]),
      ),
    );
  }

  Widget _infoCard(String name) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: [
      // Avatar
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.1)]),
          shape: BoxShape.circle),
        child: Center(child: Text(name[0],
          style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700,
            color: AppColors.primary))),
      ),
      const SizedBox(height: 12),
      Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      // Info rows
      _infoRow(Icons.person_outline, 'Возраст', '32 года'),
      _infoRow(Icons.flag_outlined, 'Цель', 'Поддержание веса'),
      _infoRow(Icons.warning_amber_rounded, 'Ограничения', 'Лактоза'),
      _infoRow(Icons.restaurant_outlined, 'Аллергии', 'Нет'),
    ]),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
        color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
        fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _todayPlan() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('ПЛАН НА СЕГОДНЯ', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
      fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    const SizedBox(height: 10),
    // Placeholder meals
    ...[
      _mealRow('🌅', 'Завтрак', 'Овсянка с ягодами', '320 ккал'),
      _mealRow('☀️', 'Обед', 'Куриная грудка с рисом', '450 ккал'),
      _mealRow('🍎', 'Перекус', 'Яблоко + орехи', '180 ккал'),
      _mealRow('🌙', 'Ужин', 'Рыба с овощами', '380 ккал'),
    ],
  ]);

  Widget _mealRow(String emoji, String type, String name, String kcal) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(type, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
          fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
          fontWeight: FontWeight.w600)),
      ])),
      Text(kcal, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
        fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]),
  );

  Widget _progressSummary() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('ПРОГРЕСС (НЕДЕЛЯ)', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
      fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    const SizedBox(height: 10),
    Row(children: [
      _progressCard('Калории', '1680/1800', 'ккал', const Color(0xFF4C1D95)),
      const SizedBox(width: 10),
      _progressCard('Вес', '68.5', 'кг', const Color(0xFF10B981)),
    ]),
  ]);

  Widget _progressCard(String label, String value, String unit, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
          color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 22,
          fontWeight: FontWeight.w800, color: color)),
        Text(unit, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
          color: AppColors.textSecondary)),
      ]),
    ),
  );
}
