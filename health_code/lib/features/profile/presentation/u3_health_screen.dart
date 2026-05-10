// lib/features/profile/presentation/u3_health_screen.dart
// U-3: Здоровье — симптомы, хронические, лекарства, женское здоровье
// Спека: screens-map.md §U-3, зеркало O-6/O-7

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class U3HealthScreen extends ConsumerWidget {
  const U3HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Здоровье'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _card('СИМПТОМЫ', p.symptoms?.isNotEmpty == true
            ? p.symptoms!.join(', ') : 'Нет жалоб'),
          _card('ХРОНИЧЕСКИЕ СОСТОЯНИЯ', p.diseases?.isNotEmpty == true
            ? p.diseases!.join(', ') : 'Не указаны'),
          _card('ЛЕКАРСТВА', p.takesMedications == 'yes'
            ? (p.medications ?? 'Указано: принимает') : 'Не принимает'),
          if (p.gender == 'female')
            _card('ЖЕНСКОЕ ЗДОРОВЬЕ', p.womensHealth?.isNotEmpty == true
              ? p.womensHealth!.join(', ') : 'Не указано'),
        ]),
      ),
    );
  }

  AppBar _appBar(BuildContext ctx, String t) => AppBar(
    backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
    leading: IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
    title: Text(t, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)), centerTitle: true);

  Widget _card(String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 12), width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5)),
    ]),
  );
}
