// O-16: Сводка профиля — полный аудит всех ключей + русские лейблы
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/features/onboarding/utils/conflict_resolver.dart';

class O16SummaryScreen extends ConsumerStatefulWidget {
  const O16SummaryScreen({super.key});
  @override
  ConsumerState<O16SummaryScreen> createState() => _O16State();
}

class _O16State extends ConsumerState<O16SummaryScreen> {
  bool _nMeals=true,_nVit=true,_nMeds=true,_nWork=true,_nWater=true,_nReport=true;
  bool _hcSleep=true,_hcSteps=true,_hcWork=true,_hcWeight=true;

  /// Static field: which section to scroll to after returning from edit.
  /// Set by _edit(), cleared after scroll.
  static String? _scrollToSection;

  // GlobalKeys for each section
  final Map<String, GlobalKey> _sectionKeys = {
    'goal': GlobalKey(), 'region': GlobalKey(), 'profile': GlobalKey(),
    'weight_loss': GlobalKey(), 'nutrition': GlobalKey(), 'health': GlobalKey(),
    'womens_health': GlobalKey(), 'meal_pattern': GlobalKey(), 'sleep': GlobalKey(),
    'activity': GlobalKey(), 'budget': GlobalKey(), 'blood_tests': GlobalKey(),
    'supplements': GlobalKey(), 'motivation': GlobalKey(), 'food_prefs': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _nMeals=p.notifMeals; _nVit=p.notifVitamins; _nMeds=p.notifMedications;
    _nWork=p.notifWorkouts; _nWater=p.notifWater; _nReport=p.notifWeeklyReport;
    _hcSleep=p.hcSleep; _hcSteps=p.hcSteps; _hcWork=p.hcWorkouts; _hcWeight=p.hcWeight;

    // Schedule anchor scroll if returning from edit
    if (_scrollToSection != null) {
      final targetSection = _scrollToSection!;
      _scrollToSection = null; // consume it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _sectionKeys[targetSection];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        }
      });
    }
  }

  /// Maps route → section key for anchor scroll
  static const _routeToSection = {
    '/onboarding/goal': 'goal',
    '/onboarding/country': 'region',
    '/onboarding/profile': 'profile',
    '/onboarding/weight-loss': 'weight_loss',
    '/onboarding/restrictions': 'nutrition',
    '/onboarding/health': 'health',
    '/onboarding/womens-health': 'womens_health',
    '/onboarding/meal-pattern': 'meal_pattern',
    '/onboarding/sleep': 'sleep',
    '/onboarding/activity': 'activity',
    '/onboarding/budget': 'budget',
    '/onboarding/blood-tests': 'blood_tests',
    '/onboarding/supplements': 'supplements',
    '/onboarding/motivation': 'motivation',
    '/onboarding/food-preferences': 'food_prefs',
  };

  void _edit(String route) {
    // Remember which section the user tapped "Изменить" on
    _scrollToSection = _routeToSection[route];
    context.go('$route?fromSummary=true');
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(20,16,20,0),
          child: Row(children: [
            Text('ejeweeka', style: TextStyle(fontFamily:'Inter',fontSize:15,fontWeight:FontWeight.w800,color:AppColors.primary)),
          ])),
        const SizedBox(height:16),
        const Padding(padding: EdgeInsets.symmetric(horizontal:20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Твой профиль', style: TextStyle(fontFamily:'Inter',fontSize:26,fontWeight:FontWeight.w800,height:1.2)),
            SizedBox(height:4),
            Text('Проверь данные и создай план', style: TextStyle(fontFamily:'Inter',fontSize:14,color:AppColors.textSecondary)),
          ])),
        const SizedBox(height:16),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20,0,20,16),
          child: Column(children: [
            // ═══ O-2: Цель ═══
            _sec('goal', 'Цель', [
              _r('Основная цель', _goal(p.goal)),
            ], () => _edit(Routes.o2Goal)),

            // ═══ O-1: Регион ═══
            _sec('region', 'Регион', [
              _r('Страна', p.country ?? '—'),
              if (p.city != null && p.city!.isNotEmpty) _r('Город', p.city!),
            ], () => _edit(Routes.o1Country)),

            // ═══ O-3: Профиль ═══
            _sec('profile', 'Профиль', [
              _r('Имя', p.name ?? '—'),
              _r('Пол', _gender(p.gender)),
              _r('Возраст', p.age != null ? '${p.age} лет' : '—'),
              _r('Рост', p.height != null ? '${p.height!.toStringAsFixed(0)} см' : '—'),
              _r('Вес', p.weight != null ? '${p.weight!.toStringAsFixed(1)} кг' : '—'),
              _r('ИМТ', p.bmi != null ? '${p.bmi!.toStringAsFixed(1)} (${_bmiClass(p.bmiClass)})' : '—'),
              if (p.bodyType != null) _r('Телосложение', _bodyType(p.bodyType)),
              _r('Характер наставника', _aiPersonality(p.aiPersonality)),
            ], () => _edit(Routes.o3Profile)),

            // ═══ O-4: Похудение (только если цель weight_loss или чекбокс «хочу снизить вес») ═══
            if (p.goal == 'weight_loss' || p.wantsToLoseWeight)
              _sec('weight_loss', 'Похудение', [
                _r('Целевой вес', p.targetWeight != null ? '${p.targetWeight!.toStringAsFixed(1)} кг' : '—'),
                if (p.targetTimelineWeeks != null) _r('Срок', '${p.targetTimelineWeeks} нед.'),
                if (p.speedPriority != null) _r('Приоритет', _speed(p.speedPriority)),
                if (p.paceClassification != null) _r('Темп', _pace(p.paceClassification)),
                if (p.targetDate != null) _r('Целевая дата', p.targetDate!),
              ], () => _edit(Routes.o4WeightLoss)),

            // ═══ O-5: Питание ═══
            _sec('nutrition', 'Питание и ограничения', [
              _r('Диеты', p.diets.isNotEmpty ? p.diets.map(_diet).join(', ') : 'Нет'),
              _r('Аллергии', p.allergies.isNotEmpty ? p.allergies.map(_allergy).join(', ') : (p.hasAllergies ? 'Да' : 'Нет')),
            ], () => _edit(Routes.o5Restrictions)),

            // ═══ O-6: Здоровье ═══
            _sec('health', 'Здоровье', [
              _r('Симптомы', p.symptoms.isNotEmpty ? p.symptoms.map(_symptom).join(', ') : 'Нет жалоб'),
              _r('Хрон. состояния', p.diseases.isNotEmpty ? p.diseases.map(_disease).join(', ') : 'Нет'),
              _r('Лекарства', p.takesMedications == 'yes' ? (p.medications ?? 'Да') : 'Нет'),
            ], () => _edit(Routes.o6Health)),

            // ═══ O-7: Женское здоровье (для всех женщин) ═══
            if (p.gender == 'female')
              _sec('womens_health', 'Женское здоровье', [
                _r('Статусы', p.womensHealth.isNotEmpty
                    ? p.womensHealth.map(_wh).join(', ')
                    : 'Ничего из перечисленного'),
                if (p.takesContraceptives != null)
                  _r('Контрацептивы', p.takesContraceptives == 'yes' ? 'Да' : 'Нет'),
              ], () => _edit(Routes.o7WomensHealth)),

            // ═══ O-8: Режим питания ═══
            _sec('meal_pattern', 'Режим питания', [
              if (p.fastingType == 'daily') ...[
                _r('Режим', 'Ежедневное интервальное голодание, ${p.dailyFormat?.replaceAll('_', ':') ?? '16:8'}'),
                _r('Приёмы пищи', '${p.dailyMeals ?? 2} приёма пищи'),
              ] else if (p.fastingType == 'periodic') ...[
                _r('Приёмы пищи', _meal(p.mealPattern)),
                _r('Голодание', 'Периодическое голодание (${p.periodicFormat == '24h' ? '24 часа' : p.periodicFormat == '36h' ? '36 часов' : '5:2'})'),
                if (p.periodicDays.isNotEmpty)
                  _r('Начало', p.periodicDays.map((d) => ['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'][d]).join(', ')),
                if (p.periodicFreq != null)
                  _r('Частота', p.periodicFreq == 'weekly' ? 'Раз в неделю' : 'Раз в 2 недели'),
              ] else ...[
                _r('Приёмы пищи', _meal(p.mealPattern)),
                _r('Голодание', 'Нет'),
              ],
            ], () => _edit(Routes.o8MealPattern)),

            // ═══ O-9: Сон ═══
            _sec('sleep', 'Сон', [
              _r('Отбой', _timeVal(p.bedtime)),
              _r('Подъём', _timeVal(p.wakeupTime)),
              if (p.sleepDurationHours != null) _r('Длительность', '${p.sleepDurationHours!.toStringAsFixed(1)} ч'),
              if (p.sleepPattern != null) _r('Режим', _sleepPat(p.sleepPattern)),
              if (p.sleepDurationHours != null) _r('Качество', _sleepQuality(p.sleepDurationHours)),
            ], () => _edit(Routes.o9Sleep)),

            // ═══ O-10: Активность ═══
            _sec('activity', 'Активность', [
              _r('Частота', _actFreq(p.activityLevel)),
              if (p.activityDuration != null) _r('Длительность', _actDur(p.activityDuration)),
              if (p.activityTypes.isNotEmpty) _r('Типы', p.activityTypes.map(_actType).join(', ')),
            ], () => _edit(Routes.o10Activity)),

            // ═══ O-11: Бюджет ═══
            _sec('budget', 'Бюджет и готовка', [
              _r('Бюджет', _budget(p.budgetLevel)),
              if (p.shoppingFrequency != null) _r('Покупки', _shopFreq(p.shoppingFrequency)),
              if (p.cookingStyle != null) _r('Как готовит', _cookStyle(p.cookingStyle)),
              if (p.cookingTime != null) _r('Время на готовку', _cookTime(p.cookingTime)),
            ], () => _edit(Routes.o11Budget)),

            // ═══ O-12: Анализы ═══
            _sec('blood_tests', 'Анализы', [
              _r('Наличие', p.hasBloodTests ? 'Да' : 'Нет свежих'),
              if (p.bloodTests != null && p.bloodTests!.isNotEmpty) _r('Данные', _formatTests(p.bloodTests!)),
            ], () => _edit(Routes.o12BloodTests)),

            // ═══ O-13: БАДы ═══
            _sec('supplements', 'Витамины и БАДы', [
              _r('Принимает', p.currentlyTakesSupplements ? (p.supplements ?? 'Да') : 'Нет'),
              _r('Готовность', _suppOpen(p.supplementOpenness)),
            ], () => _edit(Routes.o13Supplements)),

            // ═══ O-14: Мотивация ═══
            _sec('motivation', 'Мотивация', [
              _r('Барьеры', p.motivationBarriers.isNotEmpty ? p.motivationBarriers.map(_barrier).join(', ') : 'Не указаны'),
            ], () => _edit(Routes.o14Motivation)),

            // ═══ O-15: Предпочтения ═══
            _sec('food_prefs', 'Предпочтения в еде', [
              _r('Исключено', p.excludedMealTypes.isNotEmpty ? p.excludedMealTypes.map(_mealType).join(', ') : 'Ем всё'),
              if (p.likedFoods.isNotEmpty) _r('Люблю', p.likedFoods.join(', ')),
              if (p.dislikedFoods.isNotEmpty) _r('Не люблю', p.dislikedFoods.join(', ')),
            ], () => _edit(Routes.o15FoodPrefs)),

            // ═══ Расчёты ═══
            const SizedBox(height:8),
            _metricsCard(p),

            // ═══ Напоминания ═══
            const SizedBox(height:16), _notifBlock(),
            // ═══ Health Connect ═══
            const SizedBox(height:16), _hcBlock(),
            // ═══ Мотив.текст ═══
            const SizedBox(height:16),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A))),
              child: const Text('💡 Круто! Ответы получены — хороший нутрициолог собирает эту базу 40–60 минут первичного приёма. Теперь ты в одной кнопке от персонального плана — составленного именно для тебя.',
                style: TextStyle(fontFamily:'Inter',fontSize:12,color:Color(0xFF92400E),height:1.5))),
            const SizedBox(height:12),
            GestureDetector(onTap: () => context.go(Routes.o25AiPersonality),
              child: const Text('← Вернуться и исправить', style: TextStyle(fontFamily:'Inter',fontSize:13,color:AppColors.textSecondary,decoration:TextDecoration.underline))),
            const SizedBox(height:24),
          ]),
        )),

        // CTA
        Padding(padding: const EdgeInsets.fromLTRB(20,8,20,4),
          child: SafeArea(top:false, child: Material(color:Colors.transparent,
            child: InkWell(onTap: _submit, borderRadius: BorderRadius.circular(16),
              child: Container(height:52, decoration: BoxDecoration(gradient:AppColors.ctaGradient, borderRadius:BorderRadius.circular(16)),
                alignment:Alignment.center, child: const Text('Всё верно → Составить план →',
                  style: TextStyle(fontFamily:'Inter',fontSize:15,fontWeight:FontWeight.w700,color:Colors.white))))))),
      ])),
    );
  }

  Future<void> _submit() async {
    final p = ref.read(profileProvider);

    // Валидация несовместимостей (Conflict Resolver)
    final bool isResolved = await ConflictResolver.resolve(context, ref, p);
    if (!isResolved) return; // user dismissed the dialog

    await ref.read(profileNotifierProvider.notifier).saveFields({
      'notif_meals':_nMeals,'notif_vitamins':_nVit,'notif_medications':_nMeds,
      'notif_workouts':_nWork,'notif_water':_nWater,'notif_weekly_report':_nReport,
      'hc_sleep':_hcSleep,'hc_steps':_hcSteps,'hc_workouts':_hcWork,'hc_weight':_hcWeight,
    });
    if (mounted) context.go(Routes.o165PlanBreakdown);
  }

  // ═══ Секция ═══
  Widget _sec(String sectionId, String t, List<Widget> rows, VoidCallback onEdit) => Container(
    key: _sectionKeys[sectionId],
    margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(t, style: const TextStyle(fontFamily:'Inter',fontSize:14,fontWeight:FontWeight.w700))),
        GestureDetector(onTap: onEdit, child: const Text('Изменить', style: TextStyle(fontFamily:'Inter',fontSize:13,fontWeight:FontWeight.w600,color:AppColors.primary))),
      ]),
      const SizedBox(height:10), ...rows,
    ]),
  );

  Widget _r(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical:3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width:120, child: Text('$l:', style: const TextStyle(fontFamily:'Inter',fontSize:13,color:AppColors.textSecondary))),
      Expanded(child: Text(v, style: const TextStyle(fontFamily:'Inter',fontSize:13,fontWeight:FontWeight.w600,color:AppColors.textPrimary))),
    ]));

  // ═══ Лейблы ═══
  String _goal(String? g) => {'weight_loss':'Снижение веса','maintenance':'Поддержание веса','muscle_gain':'Набор мышечной массы',
    'improve_energy':'Энергия и самочувствие','skin_hair_nails':'Кожа, волосы, ногти','gut_health':'Здоровье ЖКТ',
    'longevity':'Долголетие','sport_performance':'Спортивные результаты',
    'health_restrictions':'Питание при ограничениях по здоровью',
    'reduce_cravings':'Снизить тягу к сладкому',
    'recovery':'Восстановление',
    'age_adapted':'Адаптировать к возрасту',
    'age_adaptation':'Адаптировать к возрасту'}[g] ?? g ?? '—';
  String _gender(String? g) => g == 'male' ? 'Мужчина' : g == 'female' ? 'Женщина' : '—';
  String _bmiClass(String? c) => {'underweight':'Дефицит','normal':'Норма','overweight':'Избыток','obese':'Ожирение'}[c] ?? c ?? '';
  String _bodyType(String? b) => {'slim':'Худощавое','medium':'Среднее','athletic':'Спортивное','full':'Полное','large':'Крупное'}[b] ?? b ?? '—';
  String _speed(String? s) => {'faster':'Быстрее','steady':'Стабильно','no_rush':'Без спешки'}[s] ?? s ?? '—';
  String _pace(String? p) => {'safe':'Безопасный','accelerated':'Ускоренный','aggressive':'Агрессивный','impossible':'Нереалистичный'}[p] ?? p ?? '—';

  String _diet(String d) => {'vegetarian':'Вегетарианство','vegan':'Веганство','no_red_meat':'Без красного мяса',
    'pescatarian':'Пескетарианство','no_dairy':'Без молочных','gluten_free':'Без глютена','no_sugar':'Без сахара',
    'halal':'Халяль','kosher':'Кошерное'}[d] ?? d;
  String _allergy(String a) => {'nuts':'Орехи','peanuts':'Арахис','dairy':'Молоко/лактоза','eggs':'Яйца',
    'fish':'Рыба','shellfish':'Морепродукты','soy':'Соя','citrus':'Цитрусовые','honey':'Мёд'}[a] ?? a;

  String _symptom(String s) => {'bloating':'Вздутие','heartburn':'Изжога','heaviness':'Тяжесть после еды',
    'constipation':'Запоры','sugar_cravings':'Тяга к сладкому','edema':'Отёки',
    'fatigue':'Хроническая усталость','chronic_fatigue':'Хроническая усталость','none':'Нет жалоб','no_symptoms':'Нет жалоб',
    'unstable_stool':'Нестабильный стул','nausea':'Тошнота','abdominal_pain':'Боли в животе',
    'overeating':'Сильный голод / переедание'}[s] ?? s;
  String _disease(String d) => {'diabetes_1':'Углеводный обмен (1 тип)','diabetes_2':'Углеводный обмен (2 тип)','prediabetes':'Преддиабет',
    'insulin_resistance':'Инсулинорезистентность','high_cholesterol':'Повышенный холестерин',
    'hypertension':'Гипертония','hypotension':'Гипотония','thyroid':'Особенности щитовидной железы',
    'gi_disease':'Особенности ЖКТ','kidney':'Особенности работы почек','kidney_disease':'Особенности работы почек',
    'gout':'Подагра','none':'Нет','no_disease':'Нет','other_disease':'Другое'}[d] ?? d;
  String _wh(String w) => {'pregnancy':'Беременность','breastfeeding':'Кормление грудью',
    'menopause':'Менопауза','irregular_cycle':'Нерегулярный цикл','pcos':'СПКЯ','none':'Ничего'}[w] ?? w;

  String _meal(String? m) => {'2_meals':'2 приёма','3_meals':'3 приёма (Классика)','4_plus':'4+ приёма (Дробно)','flexible':'Гибко'}[m] ?? m ?? '—';
  String _fasting(String? f) => f == null || f == 'none' ? 'Нет' : {'daily':'Ежедневное (интервальное)','periodic':'Периодическое'}[f] ?? f;
  String _timeVal(String? t) => t == 'varies' ? 'По-разному' : t ?? '—';
  String _sleepPat(String? s) => {'similar':'Примерно одинаковый','shift':'Работаю посменно','shift_work':'Работаю посменно', 'irregular':'Нерегулярно', 'regular':'Примерно одинаковый'}[s] ?? s ?? '—';

  String _sleepQuality(double? hours) {
    if (hours == null) return '—';
    if (hours < 7) return 'Слишком мало';
    if (hours <= 9) return 'Идеально';
    return 'Много';
  }

  String _actFreq(String? a) => {'none':'Не тренируюсь','once':'1 раз/нед','twice':'2 раза/нед','three':'3 раза/нед','four_plus':'4+/нед'}[a] ?? a ?? '—';
  String _actDur(String? d) => {'10_15':'10–15 мин','20_30':'20–30 мин','30_45':'30–45 мин','45_60':'45–60 мин','60_plus':'Более часа'}[d] ?? d ?? '—';
  String _actType(String t) => {'walking':'Ходьба','running':'Бег','strength':'Силовые','home_workout':'Домашние',
    'swimming':'Плавание','yoga':'Йога','cycling':'Велосипед','team_sports':'Командные','pilates':'Пилатес'}[t] ?? t;

  String _budget(String? b) => {'economy':'Экономный','medium':'Средний','premium':'Премиум'}[b] ?? b ?? '—';
  String _cookStyle(String? s) => {'daily':'Каждый день','batch_2_3_days':'На 2-3 дня','batch_weekly':'Раз в неделю','none':'Не готовлю'}[s] ?? s ?? '—';
  String _shopFreq(String? s) => {'daily':'Каждый день','few_days':'Каждые 2-3 дня','weekly':'Раз в неделю'}[s] ?? s ?? '—';
  String _cookTime(String? t) => {'up_to_15':'До 15 мин','20_40':'20–40 мин','over_60':'Более 60 мин'}[t] ?? t ?? '—';

  String _suppOpen(String? o) => {'yes_select':'Да, подберите','yes_understand':'Да, но хочу понимать зачем',
    'only_necessary':'Только если необходимо','no':'Нет, без добавок'}[o] ?? o ?? '—';

  String _barrier(String b) => {'hunger':'Постоянный голод','sweets':'Тяга к сладкому','evening_binge':'Срывы вечером/ночью',
    'no_time':'Нет времени готовить','on_the_go':'Ем на ходу','hard_to_refuse':'Сложно отказаться от привычной еды',
    'emotional':'Эмоциональное переедание','social':'Праздники и окружение',
    'no_results':'Нет результата','never_tried':'Без опыта',
    'lack_time':'Нехватка времени','lack_motivation':'Мотивация','stress':'Стресс',
    'social_pressure':'Социальное давление','plateau':'Плато','sweet_tooth':'Тяга к сладкому','none':'Нет барьеров'}[b] ?? b;
  String _mealType(String m) => {'soups':'Супы','porridges':'Каши','salads':'Салаты','smoothies':'Смузи','offal':'Субпродукты','eat_all':'Ем всё'}[m] ?? m;
  String _aiPersonality(String a) => {'premium':'Премиальный (на Ты)','buddy':'Поддерживающий (на Ты)','strict':'Строгий тренер','sassy':'С сарказмом'}[a] ?? a;

  String _formatTests(String t) {
    if (t.trim().startsWith('{') && t.trim().endsWith('}')) {
      final inner = t.trim().substring(1, t.trim().length - 1);
      var formatted = inner.replaceAll('"', '').replaceAll(':', ': ').replaceAll(', ', '\n');
      formatted = formatted
          .replaceAll('glucose', 'Глюкоза')
          .replaceAll('hba1c', 'HbA1c')
          .replaceAll('insulin', 'Инсулин')
          .replaceAll('cholesterol', 'Холестерин')
          .replaceAll('vitamin_d', 'Витамин D')
          .replaceAll('ferritin', 'Ферритин')
          .replaceAll('iron', 'Железо')
          .replaceAll('tsh', 'ТТГ')
          .replaceAll('vitamin_b12', 'Витамин B12')
          .replaceAll('hemoglobin', 'Гемоглобин')
          .replaceAll('other', 'Другое');
      return formatted;
    }
    return t;
  }

  // ═══ Расчёты ═══
  Widget _metricsCard(dynamic p) {
    final goalSub = p.goal == 'weight_loss' ? '(дефицит)'
        : p.goal == 'muscle_gain' ? '(профицит)'
        : '(поддержание)';
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha:0.8)]),
        borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Text('Твои расчёты', style: TextStyle(fontFamily:'Inter',fontSize:14,fontWeight:FontWeight.w700,color:Colors.white)),
        const SizedBox(height:12),
        Row(children: [
          _mc('Базовый\nобмен', () { final v = p.bmrKcal ?? p.bmr; return v != null ? v.toStringAsFixed(0) : '—'; }(), 'ккал'),
          const SizedBox(width:8),
          _mc('Базовый с\nактивностью', p.tdeeCalculated != null ? '${p.tdeeCalculated.toStringAsFixed(0)}' : '—', 'ккал'),
        ]),
        const SizedBox(height:8),
        Row(children: [
          _mc('Целевой с\nактивностью\n$goalSub', p.targetDailyCalories != null ? '${p.targetDailyCalories.toStringAsFixed(0)}' : '—', 'ккал/день'),
          const SizedBox(width:8),
          _mc('Целевая\nклетчатка', p.targetDailyFiber != null ? '${p.targetDailyFiber.toStringAsFixed(0)}' : '—', 'г/день'),
        ]),
      ]));
  }
  Widget _mc(String t, String v, String s) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical:10,horizontal:8),
    decoration: BoxDecoration(color:Colors.white.withValues(alpha:0.15), borderRadius:BorderRadius.circular(12)),
    child: Column(children: [
      Text(v, style: const TextStyle(fontFamily:'Inter',fontSize:14,fontWeight:FontWeight.w800,color:Colors.white)),
      Text(s, style: const TextStyle(fontFamily:'Inter',fontSize:9,color:Colors.white70)),
      Text(t, style: const TextStyle(fontFamily:'Inter',fontSize:10,color:Colors.white70,height:1.2), textAlign: TextAlign.center),
    ])));

  // ═══ Тогглы ═══
  Widget _notifBlock() => _card('Получать напоминания', [
    _tog('Приёмы пищи','Завтрак, обед и ужин',_nMeals,(v)=>setState(()=>_nMeals=v)),
    _tog('Витамины','По расписанию',_nVit,(v)=>setState(()=>_nVit=v)),
    _tog('Лекарства','Приём лекарств',_nMeds,(v)=>setState(()=>_nMeds=v)),
    _tog('Тренировки','Запланированные',_nWork,(v)=>setState(()=>_nWork=v)),
    _tog('Вода','Напоминание выпить воду',_nWater,(v)=>setState(()=>_nWater=v)),
    _tog('Еженедельный отчёт','Каждое воскресенье',_nReport,(v)=>setState(()=>_nReport=v)),
  ]);
  Widget _hcBlock() => _card('Health Connect', [
    const Padding(padding:EdgeInsets.only(bottom:8), child:Text('Подключить данные о сне, шагах и тренировках',
      style:TextStyle(fontFamily:'Inter',fontSize:12,color:AppColors.textSecondary,height:1.4))),
    _tog('Сон',null,_hcSleep,(v)=>setState(()=>_hcSleep=v)),
    _tog('Шаги',null,_hcSteps,(v)=>setState(()=>_hcSteps=v)),
    _tog('Тренировки',null,_hcWork,(v)=>setState(()=>_hcWork=v)),
    _tog('Вес',null,_hcWeight,(v)=>setState(()=>_hcWeight=v)),
  ]);
  Widget _card(String t, List<Widget> ch) => Container(padding:const EdgeInsets.all(16),
    decoration: BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
      Text(t, style:const TextStyle(fontFamily:'Inter',fontSize:14,fontWeight:FontWeight.w700)),
      const SizedBox(height:12), ...ch]));
  Widget _tog(String l, String? s, bool v, ValueChanged<bool> cb) => Padding(padding:const EdgeInsets.only(bottom:8),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
        Text(l, style:const TextStyle(fontFamily:'Inter',fontSize:13,fontWeight:FontWeight.w600)),
        if (s!=null) Text(s, style:const TextStyle(fontFamily:'Inter',fontSize:11,color:AppColors.textSecondary)),
      ])),
      SizedBox(height:28, child: Switch.adaptive(value:v, onChanged:cb, activeColor:AppColors.primary)),
    ]));
}
