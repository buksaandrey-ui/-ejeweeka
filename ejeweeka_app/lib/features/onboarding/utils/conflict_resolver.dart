import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_model.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/features/onboarding/presentation/widgets/conflict_resolver_dialog.dart';

class ConflictResolver {
  /// Проверяет профиль на логические конфликты.
  /// Возвращает `true`, если конфликтов нет или пользователь их разрешил, 
  /// и `false`, если пользователь отменил действие.
  static Future<bool> resolve(BuildContext context, WidgetRef ref, UserProfile p) async {
    // 1. Конфликт: Не готовлю + Ежедневные покупки
    if (p.cookingStyle == 'none' && p.shoppingFrequency == 'daily') {
      final resolved = await ConflictResolverDialog.show(
        context,
        title: 'Небольшой конфликт',
        description: 'В профиле указано: "не готовлю", но выбраны ежедневные покупки продуктов. Как мы поступим?',
        option1Label: 'Я буду готовить',
        option2Label: 'Покупать готовую еду',
        onOption1: () {
          ref.read(profileNotifierProvider.notifier).saveField('cooking_style', 'daily');
        },
        onOption2: () {
          ref.read(profileNotifierProvider.notifier).saveField('shopping_frequency', 'weekly'); // или 'none', если было бы такое значение
        },
      );
      if (resolved == null) return false;
    }

    // 2. Конфликт: Экономный бюджет + Не готовлю
    if (p.budgetLevel == 'economy' && p.cookingStyle == 'none') {
      final resolved = await ConflictResolverDialog.show(
        context,
        title: 'Бюджет и Готовка',
        description: 'Заказ готовой еды обычно выходит за рамки экономного бюджета. Хочешь изменить бюджет или начать готовить?',
        option1Label: 'Буду готовить',
        option2Label: 'Средний бюджет',
        onOption1: () {
          ref.read(profileNotifierProvider.notifier).saveField('cooking_style', 'batch_2_3_days');
        },
        onOption2: () {
          ref.read(profileNotifierProvider.notifier).saveField('budget_level', 'medium');
        },
      );
      if (resolved == null) return false;
    }

    // 3. Конфликт: Спортивная цель + Нет тренировок
    if (p.goal == 'muscle_gain' && p.activityLevel == 'none') {
      final resolved = await ConflictResolverDialog.show(
        context,
        title: 'Цель и Активность',
        description: 'Для набора мышечной массы нужны силовые тренировки. Добавим хотя бы 2 тренировки в неделю?',
        option1Label: 'Да, добавь',
        option2Label: 'Оставить так',
        onOption1: () {
          ref.read(profileNotifierProvider.notifier).saveField('activity_level', 'twice');
          ref.read(profileNotifierProvider.notifier).saveField('activity_types', ['strength']);
        },
        onOption2: () {
          // Ничего не меняем, пользователь настаивает
        },
      );
      if (resolved == null) return false;
    }

    return true; // Все конфликты разрешены или их не было
  }
}
