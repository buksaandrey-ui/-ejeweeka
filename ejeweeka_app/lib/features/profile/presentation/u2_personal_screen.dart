// lib/features/profile/presentation/u2_personal_screen.dart
// U-2: Личные данные и цель — зеркало O-2/O-3/O-4
// Спека: screens-map.md §U-2

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class U2PersonalScreen extends ConsumerWidget {
  const U2PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);

    final goalLabel = switch (p.goal) {
      'weight_loss' => 'Снизить вес',
      'muscle_gain' => 'Набрать массу',
      'health_improve' => 'Улучшить здоровье',
      'energy' => 'Больше энергии',
      'gut_health' => 'Наладить ЖКТ',
      'skin_health' => 'Улучшить кожу',
      'longevity' => 'Долголетие',
      'sports' => 'Спорт-питание',
      _ => p.goal ?? '—',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Личные данные и цель'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('ГЛАВНАЯ ЦЕЛЬ', [
            _readonlyField('Цель', goalLabel),
          ]),
          _section('О ТЕБЕ', [
            _readonlyField('Имя', p.name ?? '—'),
            _readonlyField('Пол', p.gender == 'male' ? 'Мужской' : p.gender == 'female' ? 'Женский' : '—'),
            _readonlyField('Возраст', p.age != null ? '${p.age} лет' : '—'),
          ]),
          _section('ПАРАМЕТРЫ ТЕЛА', [
            _readonlyField('Рост', p.height != null ? '${p.height} см' : '—'),
            _readonlyField('Вес', p.weight != null ? '${p.weight!.toStringAsFixed(1)} кг' : '—'),
            _readonlyField('Тип телосложения', p.bodyType ?? '—'),
          ]),
          if (p.targetWeight != null)
            _section('ЦЕЛЬ ПО ВЕСУ', [
              _readonlyField('Желаемый вес', '${p.targetWeight!.toStringAsFixed(1)} кг'),
              _readonlyField('Срок', p.targetTimelineWeeks != null ? '${p.targetTimelineWeeks} нед' : '—'),
            ]),
          _section('АВТО-РАСЧЁТЫ', [
            _readonlyField('ИМТ', p.bmi != null ? p.bmi!.toStringAsFixed(1) : '—'),
            _readonlyField('BMR', p.bmrKcal != null ? '${p.bmrKcal!.toStringAsFixed(0)} ккал' : '—'),
            _readonlyField('TDEE', p.tdeeCalculated != null ? '${p.tdeeCalculated!.toStringAsFixed(0)} ккал' : '—'),
          ]),
          _section('ТРЕНИРОВКИ', [
            _readonlyField('Уровень', p.fitnessLevel ?? '—'),
            _readonlyField('Количество дней', p.trainingDays != null ? '${p.trainingDays} дней/нед' : '—'),
            _readonlyField('Где', p.workoutLocation ?? '—'),
            _readonlyField('Оборудование', (p.equipment).isNotEmpty ? p.equipment.join(', ') : '—'),
            _readonlyField('Ограничения', (p.physicalLimitations ?? []).isNotEmpty ? p.physicalLimitations.join(', ') : 'Нет'),
          ]),
        ]),
      ),
    );
  }

  AppBar _appBar(BuildContext context, String title) => AppBar(
    backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
    leading: IconButton(onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
    title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
    centerTitle: true,
  );

  Widget _section(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );

  Widget _readonlyField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
        color: AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
    ]),
  );
}
