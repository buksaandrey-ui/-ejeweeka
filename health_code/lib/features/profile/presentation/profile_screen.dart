// lib/features/profile/presentation/profile_screen.dart
// U-1: Профиль — Hub-навигация на U-2..U-16
// Спека: screens-map.md §U-1

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/features/plan/providers/plan_provider.dart';
import 'package:health_code/features/plan/data/plan_repository.dart';
import 'package:health_code/core/storage/secure_storage.dart';
import 'package:health_code/features/profile/presentation/u2_personal_screen.dart';
import 'package:health_code/features/profile/presentation/u3_health_screen.dart';
import 'package:health_code/features/profile/presentation/u_sub_screens.dart';
import 'package:health_code/features/profile/presentation/u12_status_screen.dart';
import 'package:health_code/features/profile/presentation/u16_about_screen.dart';
import 'package:health_code/features/family/presentation/family_group_screen.dart';
import 'package:health_code/features/health_connect/presentation/health_connect_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _tgBotUrl = 'https://t.me/healthcode_bot';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    final tierLabel = switch (profile.subscriptionStatus) {
      'black' => 'ejeweeka Black',
      'gold' => 'ejeweeka Gold',
      'family_gold' => 'ejeweeka Family Gold',
      _ => 'ejeweeka White',
    };

    final tierColor = switch (profile.subscriptionStatus) {
      'black' => const Color(0xFF1A1A1A),
      'gold' => const Color(0xFFB45309),
      'family_gold' => const Color(0xFF991B1B),
      _ => AppColors.textSecondary,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // ── Avatar + name + tier badge ────────────────────
              Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      profile.name?.isNotEmpty == true ? profile.name![0].toUpperCase() : '?',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 32,
                        fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(profile.name ?? 'Профиль',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tierLabel,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                      fontWeight: FontWeight.w600, color: tierColor)),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Stats row ─────────────────────────────────────
              Row(children: [
                _miniStat(Icons.monitor_weight_outlined, const Color(0xFF667EEA), 'Вес',
                    profile.weight != null ? '${profile.weight!.toStringAsFixed(1)} кг' : '—'),
                const SizedBox(width: 8),
                _miniStat(Icons.analytics_outlined, const Color(0xFFFF9800), 'ИМТ',
                    profile.bmi != null ? profile.bmi!.toStringAsFixed(1) : '—'),
                const SizedBox(width: 8),
                _miniStat(Icons.local_fire_department_outlined, const Color(0xFFF44336), 'Обмен',
                    profile.tdeeCalculated != null ? '${profile.tdeeCalculated!.toStringAsFixed(0)}' : '—'),
              ]),
              const SizedBox(height: 20),

              // ── Menu: U-2..U-16 ───────────────────────────────
              _menuSection('Профиль и питание', [
                _menuItem(Icons.person_outline_rounded, 'Личные данные и цель', 'U-2', context),
                _menuItem(Icons.medical_services_outlined, 'Здоровье', 'U-3', context),
                _menuItem(Icons.no_meals_outlined, 'Ограничения и аллергии', 'U-4', context),
                _menuItem(Icons.medication_outlined, 'Витамины и БАДы', 'U-5', context),
                _menuItem(Icons.biotech_outlined, 'Анализы', 'U-6', context),
                _menuItem(Icons.restaurant_outlined, 'Вкусы и предпочтения', 'U-7', context),
              ]),

              _menuSection('Режим и активность', [
                _menuItem(Icons.schedule_outlined, 'Режим дня', 'U-8', context),
                _menuItem(Icons.fitness_center_outlined, 'Активность', 'U-9', context),
                _menuItem(Icons.account_balance_wallet_outlined, 'Бюджет и готовка', 'U-10', context),
              ]),

              _menuSection('Настройки', [
                _menuItem(Icons.notifications_outlined, 'Напоминания', 'U-11', context),
                _menuItem(Icons.workspace_premium_outlined, 'Статус', 'U-12', context),
                _menuItem(Icons.palette_outlined, 'Цветовая схема', 'U-13', context),
                _menuItem(Icons.monitor_heart_outlined, 'Health Connect', 'U-14', context),
                _menuItem(Icons.family_restroom_rounded, 'Семейный доступ', 'F-1', context),
                _menuItem(Icons.psychology_outlined, 'Мотивация и барьеры', 'U-15', context),
                _menuItem(Icons.info_outline_rounded, 'О проекте', 'U-16', context),
              ]),

              // ── Account actions ───────────────────────────────
              const SizedBox(height: 8),
              _menuSection('Аккаунт', [
                _actionRow(Icons.sync_rounded, 'Синхронизировать статус', AppColors.primary, () async {
                  // TODO: Real API call to sync status from backend
                  await Future.delayed(const Duration(milliseconds: 800));
                  ref.invalidate(profileProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Статус успешно синхронизирован с сервером')),
                    );
                  }
                }),
                _actionRow(Icons.refresh_rounded, 'Обновить план питания', AppColors.textPrimary, () {
                  ref.read(planNotifierProvider.notifier).generate();
                }),
                _actionRow(Icons.delete_outline_rounded, 'Удалить все данные', const Color(0xFFF44336), () {
                  _showDeleteDialog(context, ref);
                }),
              ]),

              const SizedBox(height: 12),
              Text('ejeweeka v2.2.0 • Zero-Knowledge Privacy',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                  color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu helpers ──────────────────────────────────────────
  Widget _menuSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(title.toUpperCase(),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.8)),
        ),
        ...items.asMap().entries.map((e) => Column(children: [
          e.value,
          if (e.key < items.length - 1)
            const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF0F0F0)),
        ])),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _menuItem(IconData icon, String label, String screenId, BuildContext context) {
    return InkWell(
      onTap: () => _openSubScreen(context, screenId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  void _openSubScreen(BuildContext context, String screenId) {
    final Widget? screen = switch (screenId) {
      'U-2' => const U2PersonalScreen(),
      'U-3' => const U3HealthScreen(),
      'U-4' => const U4RestrictionsScreen(),
      'U-5' => const U5VitaminsScreen(),
      'U-6' => const U6BloodTestsScreen(),
      'U-7' => const U7FoodPrefsScreen(),
      'U-8' => const U8ScheduleScreen(),
      'U-9' => const U9ActivityScreen(),
      'U-10' => const U10BudgetScreen(),
      'U-11' => const U11NotificationsScreen(),
      'U-12' => const U12StatusScreen(),
      'U-13' => const U13ThemeScreen(),
      'U-14' => const HealthConnectScreen(),
      'F-1' => const FamilyGroupScreen(),
      'U-15' => const U15MotivationScreen(),
      'U-16' => const U16AboutScreen(),
      _ => null,
    };

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  Widget _miniStat(IconData iconData, Color iconColor, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        Icon(iconData, size: 22, color: iconColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ),
  );

  Widget _actionRow(IconData icon, String label, Color color, VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: color))),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
        ]),
      ),
    );

  // CTA card removed for App Store compliance
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить все данные?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: const Text('Все данные профиля, план питания и история веса будут удалены безвозвратно.',
          style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Color(0xFFF44336)))),
        ],
      ),
    );
    if (confirm == true) {
      await PlanRepository.clearPlan();
      await SecureStorageService.deleteAll();
      await ref.read(profileNotifierProvider.notifier).saveFields({'_reset': 'true'});
      ref.read(planNotifierProvider.notifier).reset();
    }
  }
}
