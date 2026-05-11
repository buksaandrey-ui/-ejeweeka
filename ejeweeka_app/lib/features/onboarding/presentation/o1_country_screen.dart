// lib/features/onboarding/presentation/o1_country_screen.dart
// O-1: Страна и Город. Полный глобальный список (А→Я по-русски).
// multiClimate=true → TextField с автодополнением городов.
// «Далее»: однокл.=выбрана страна; многокл.=введён город.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_nav_bar.dart';

class _Country {
  final String flag, name, code;
  final bool multiClimate;
  final List<String> cities;
  const _Country(this.flag, this.name, this.code, {this.multiClimate = false, this.cities = const []});
}

// Строго А→Я по-русски. Все страны со значимой русскоязычной диаспорой.
const List<_Country> _countries = [
  _Country('🇦🇺', 'Австралия',        'AU', multiClimate: true,  cities: ['Сидней','Мельбурн','Брисбен','Перт','Аделаида','Голд-Кост']),
  _Country('🇦🇹', 'Австрия',          'AT'),
  _Country('🇦🇿', 'Азербайджан',      'AZ'),
  _Country('🇦🇷', 'Аргентина',        'AR', multiClimate: true,  cities: ['Буэнос-Айрес','Кордова','Росарио','Мендоса','Мар-дель-Плата']),
  _Country('🇦🇲', 'Армения',          'AM'),
  _Country('🇧🇭', 'Бахрейн',          'BH'),
  _Country('🇧🇾', 'Беларусь',         'BY'),
  _Country('🇧🇪', 'Бельгия',          'BE'),
  _Country('🇧🇬', 'Болгария',         'BG'),
  _Country('🇧🇷', 'Бразилия',         'BR', multiClimate: true,  cities: ['Сан-Паулу','Рио-де-Жанейро','Куритиба','Порту-Алегри','Бразилиа']),
  _Country('🇬🇧', 'Великобритания',   'GB'),
  _Country('🇻🇳', 'Вьетнам',          'VN', multiClimate: true,  cities: ['Хошимин','Ханой','Нячанг','Дананг','Хойан','Фукуок']),
  _Country('🇩🇪', 'Германия',         'DE'),
  _Country('🇬🇷', 'Греция',           'GR'),
  _Country('🇬🇪', 'Грузия',           'GE'),
  _Country('🇩🇰', 'Дания',            'DK'),
  _Country('🇪🇬', 'Египет',           'EG', multiClimate: true,  cities: ['Хургада','Шарм-эль-Шейх','Каир','Александрия']),
  _Country('🇮🇱', 'Израиль',          'IL'),
  _Country('🇮🇳', 'Индия',            'IN', multiClimate: true,  cities: ['Гоа','Мумбаи','Дели','Ченнай','Бангалор','Керала']),
  _Country('🇮🇩', 'Индонезия',        'ID', multiClimate: true,  cities: ['Бали','Джакарта','Ломбок']),
  _Country('🇮🇪', 'Ирландия',         'IE'),
  _Country('🇪🇸', 'Испания',          'ES', multiClimate: true,  cities: ['Мадрид','Барселона','Малага','Аликанте','Валенсия','Тенерифе','Пальма-де-Майорка']),
  _Country('🇮🇹', 'Италия',           'IT', multiClimate: true,  cities: ['Рим','Милан','Неаполь','Флоренция','Болонья','Генуя','Турин']),
  _Country('🇰🇿', 'Казахстан',        'KZ', multiClimate: true,  cities: ['Алматы','Астана','Шымкент','Актобе','Атырау','Павлодар','Усть-Каменогорск']),
  _Country('🇰🇭', 'Камбоджа',         'KH'),
  _Country('🇨🇦', 'Канада',           'CA', multiClimate: true,  cities: ['Торонто','Монреаль','Ванкувер','Калгари','Оттава','Эдмонтон']),
  _Country('🇶🇦', 'Катар',            'QA'),
  _Country('🇨🇾', 'Кипр',             'CY'),
  _Country('🇨🇳', 'Китай',            'CN', multiClimate: true,  cities: ['Пекин','Шанхай','Гуанчжоу','Харбин','Чэнду','Шэньчжэнь']),
  _Country('🇰🇼', 'Кувейт',           'KW'),
  _Country('🇰🇬', 'Кыргызстан',       'KG'),
  _Country('🇱🇻', 'Латвия',           'LV'),
  _Country('🇱🇹', 'Литва',            'LT'),
  _Country('🇲🇾', 'Малайзия',         'MY'),
  _Country('🇲🇹', 'Мальта',           'MT'),
  _Country('🇲🇽', 'Мексика',          'MX', multiClimate: true,  cities: ['Мехико','Канкун','Плайя-дель-Кармен','Гвадалахара','Монтеррей']),
  _Country('🇲🇩', 'Молдова',          'MD'),
  _Country('🇲🇳', 'Монголия',         'MN'),
  _Country('🇳🇱', 'Нидерланды',       'NL'),
  _Country('🇳🇿', 'Новая Зеландия',   'NZ', multiClimate: true,  cities: ['Окленд','Веллингтон','Крайстчерч','Квинстаун']),
  _Country('🇳🇴', 'Норвегия',         'NO'),
  _Country('🇦🇪', 'ОАЭ',              'AE'),
  _Country('🇵🇾', 'Парагвай',         'PY'),
  _Country('🇵🇱', 'Польша',           'PL'),
  _Country('🇵🇹', 'Португалия',       'PT'),
  _Country('🇷🇺', 'Россия',           'RU', multiClimate: true,  cities: ['Москва','Санкт-Петербург','Новосибирск','Екатеринбург','Казань','Нижний Новгород','Челябинск','Самара','Омск','Ростов-на-Дону','Уфа','Красноярск','Воронеж','Пермь','Волгоград','Краснодар','Тюмень','Сочи','Иркутск','Хабаровск','Владивосток','Ставрополь','Мурманск','Калининград']),
  _Country('🇷🇴', 'Румыния',          'RO'),
  _Country('🇸🇦', 'Саудовская Аравия','SA'),
  _Country('🇷🇸', 'Сербия',           'RS'),
  _Country('🇸🇬', 'Сингапур',         'SG'),
  _Country('🇸🇰', 'Словакия',         'SK'),
  _Country('🇺🇸', 'США',              'US', multiClimate: true,  cities: ['Нью-Йорк','Лос-Анджелес','Чикаго','Майами','Сан-Франциско','Сиэтл','Даллас','Хьюстон','Атланта','Бостон','Денвер','Лас-Вегас','Портленд','Феникс','Сакраменто']),
  _Country('🇹🇯', 'Таджикистан',      'TJ'),
  _Country('🇹🇭', 'Таиланд',          'TH', multiClimate: true,  cities: ['Бангкок','Паттайя','Пхукет','Чиангмай','Самуй','Хуа-Хин','Пхи-Пхи']),
  _Country('🇹🇳', 'Тунис',            'TN'),
  _Country('🇹🇲', 'Туркменистан',     'TM'),
  _Country('🇹🇷', 'Турция',           'TR', multiClimate: true,  cities: ['Стамбул','Анкара','Измир','Анталья','Бурса','Алания','Мерсин','Газиантеп','Бодрум']),
  _Country('🇺🇿', 'Узбекистан',       'UZ', multiClimate: true,  cities: ['Ташкент','Самарканд','Бухара','Навои','Андижан','Фергана','Нукус']),
  _Country('🇺🇦', 'Украина',          'UA', multiClimate: true,  cities: ['Киев','Харьков','Одесса','Днепр','Запорожье','Львов','Николаев']),
  _Country('🇺🇾', 'Уругвай',          'UY'),
  _Country('🇫🇮', 'Финляндия',        'FI'),
  _Country('🇫🇷', 'Франция',          'FR', multiClimate: true,  cities: ['Париж','Ницца','Марсель','Лион','Бордо','Монпелье','Канны']),
  _Country('🇭🇷', 'Хорватия',         'HR'),
  _Country('🇲🇪', 'Черногория',       'ME'),
  _Country('🇨🇿', 'Чехия',            'CZ'),
  _Country('🇨🇱', 'Чили',             'CL', multiClimate: true,  cities: ['Сантьяго','Вальпараисо','Консепсьон','Антофагаста','Пунта-Аренас']),
  _Country('🇨🇭', 'Швейцария',        'CH'),
  _Country('🇸🇪', 'Швеция',           'SE'),
  _Country('🇱🇰', 'Шри-Ланка',        'LK'),
  _Country('🇿🇦', 'ЮАР',              'ZA', multiClimate: true,  cities: ['Йоханнесбург','Кейптаун','Дурбан','Претория']),
  _Country('🇪🇪', 'Эстония',          'EE'),
  _Country('🇯🇵', 'Япония',           'JP', multiClimate: true,  cities: ['Токио','Осака','Саппоро','Фукуока','Нагоя','Киото']),
];

class O1CountryScreen extends ConsumerStatefulWidget {
  const O1CountryScreen({super.key});
  @override
  ConsumerState<O1CountryScreen> createState() => _O1CountryScreenState();
}

class _O1CountryScreenState extends ConsumerState<O1CountryScreen> {
  _Country? _sel;
  String _city = '';
  final _searchCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _cityFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    // Восстанавливаем сохранённые данные при возврате на экран
    final profile = ProfileRepository.getOrCreate();
    if (profile.country != null) {
      try {
        _sel = _countries.firstWhere((c) => c.name == profile.country, orElse: () => _countries.first);
      } catch (_) {}
    }
    if (profile.city != null) {
      _city = profile.city!;
      _cityCtrl.text = profile.city!;
    }
  }

  bool get _isValid => _sel != null;

  List<_Country> get _filtered => _q.isEmpty
      ? _countries
      : _countries.where((c) => c.name.toLowerCase().contains(_q.toLowerCase())).toList();

  List<String> get _suggestions {
    if (_sel == null || !_sel!.multiClimate) return [];
    if (_city.isEmpty) return _sel!.cities;
    return _sel!.cities.where((c) => c.toLowerCase().contains(_city.toLowerCase())).toList();
  }

  void _pick(_Country c) {
    setState(() { _sel = c; _city = ''; _cityCtrl.clear(); _searchCtrl.clear(); _q = ''; });
    // Прокрутить список наверх — чтобы бейдж и поле города были сразу видны
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
      }
    });
    if (c.multiClimate) Future.delayed(const Duration(milliseconds: 420), _cityFocus.requestFocus);
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    await ref.read(profileNotifierProvider.notifier).saveFields({
      'country': _sel!.name,
      'city': _city.trim().isEmpty ? null : _city.trim(),
    });
    if (!mounted) return;
    final fromSummary = GoRouterState.of(context).uri.queryParameters['fromSummary'] == 'true';
    if (fromSummary) {
      context.go(Routes.o16Summary);
    } else {
      context.go(Routes.o2Goal);
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); _cityCtrl.dispose(); _cityFocus.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sugg = _suggestions;
    final showDrop = _city.isNotEmpty && sugg.isNotEmpty
        && !sugg.any((s) => s.toLowerCase() == _city.toLowerCase());

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Шапка: Заголовок слева, Логотип справа
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Где ты живёшь?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight:FontWeight.w800, fontSize:24, height:1.2)),
                      const SizedBox(height: 6),
                      Text('Подберём продукты, которые реально купить в твоём городе',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:AppColors.textSecondary, height:1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 54),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Поиск
          Padding(padding: const EdgeInsets.symmetric(horizontal:20),
            child: TextField(
              controller: _searchCtrl,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (v) {
                setState(() => _q = v);
                // Autosave immediately for persistence
                ref.read(profileNotifierProvider.notifier).saveField('country_query', v);
              },
              decoration: InputDecoration(
                hintText: 'Поиск страны...',
                prefixIcon: const Icon(Icons.search_rounded, color:AppColors.textSecondary),
                suffixIcon: _q.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color:AppColors.textSecondary),
                  onPressed: () { _searchCtrl.clear(); setState(() => _q = ''); },
                ) : null,
              ))),
          const SizedBox(height: 12),

          // Список
          Expanded(child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20,0,20,16),
            children: [

              // Выбранная страна
              if (_sel != null) ...[
                _badge(),
                const SizedBox(height: 12),
              ],

              // Поле города
              if (_sel != null && _sel!.multiClimate) ...[
                _cityWidget(sugg, showDrop),
                const SizedBox(height: 16),
              ],

              // Заголовок списка
              Text(_q.isEmpty ? 'СТРАНА ПРОЖИВАНИЯ' : 'РЕЗУЛЬТАТЫ ПОИСКА',
                style: const TextStyle(fontFamily:'Inter', fontSize:11,
                  fontWeight:FontWeight.w700, color:AppColors.textSecondary, letterSpacing:1.0)),
              const SizedBox(height: 8),

              ..._filtered.map(_row),
              const SizedBox(height: 8),
            ],
          )),

          // Мотивирующий блок — виден если достаточно пространства
          LayoutBuilder(builder: (ctx, bc) {
            // Скрываем tip когда экранного места совсем мало
            final available = MediaQuery.of(context).size.height
                - MediaQuery.of(context).viewInsets.bottom;
            if (available < 580) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: MotivatingTipCard(
                text: 'Знаешь ли ты, что в Финляндии молочные продукты обогащают витамином D по закону, а в Средней Азии дефицит витамина D — редкость благодаря солнцу? Твой регион напрямую влияет на рацион.',
              ),
            );
          }),

          Builder(builder: (ctx) {
            final fromSummary = GoRouterState.of(ctx).uri.queryParameters['fromSummary'] == 'true';
            return OnboardingNavBar(
              isValid: _isValid,
              onBack: fromSummary ? () => ctx.go(Routes.o16Summary) : () {},
              onNext: _proceed,
              showBack: fromSummary,
              fromSummary: fromSummary,
            );
          }),
        ]),
      ),
    ));
  }

  Widget _badge() => Container(
    padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14),
      border: Border.all(color:AppColors.primary, width:1.5)),
    child: Row(children: [
      Text(_sel!.flag, style: const TextStyle(fontSize:22)),
      const SizedBox(width:12),
      Expanded(child: Text(_sel!.name, style: const TextStyle(
        fontFamily:'Inter', fontSize:15, fontWeight:FontWeight.w700))),
      GestureDetector(
        onTap: () => setState(() { _sel = null; _city = ''; _cityCtrl.clear(); }),
        child: const Icon(Icons.close_rounded, color:AppColors.textSecondary, size:18)),
    ]));

  Widget _cityWidget(List<String> sugg, bool showDrop) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ГОРОД ПРОЖИВАНИЯ', style: TextStyle(fontFamily:'Inter', fontSize:11,
        fontWeight:FontWeight.w700, color:AppColors.textSecondary, letterSpacing:1.0)),
      const SizedBox(height:8),
      TextField(
        controller: _cityCtrl, focusNode: _cityFocus,
        onChanged: (v) => setState(() => _city = v),
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Введи город (необязательно)',
          prefixIcon: Icon(Icons.location_city_rounded, color:AppColors.textSecondary))),
      if (showDrop)
        Container(
          margin: const EdgeInsets.only(top:4),
          decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(12),
            border:Border.all(color:const Color(0xFFE5E7EB)),
            boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.06), blurRadius:12, offset:const Offset(0,4))]),
          child: Column(children: sugg.take(6).map((city) => InkWell(
            onTap: () { _cityCtrl.text = city; setState(() => _city = city); _cityFocus.unfocus(); },
            borderRadius: BorderRadius.circular(12),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, size:16, color:AppColors.primary),
                const SizedBox(width:10),
                Text(city, style: const TextStyle(fontFamily:'Inter', fontSize:14, fontWeight:FontWeight.w500)),
              ])),
          )).toList())),
    ]);

  Widget _row(_Country c) {
    final sel = _sel?.code == c.code;
    return GestureDetector(
      onTap: () => _pick(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds:150),
        margin: const EdgeInsets.only(bottom:6),
        padding: const EdgeInsets.symmetric(horizontal:16, vertical:14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
            width: sel ? 1.5 : 1)),
        child: Row(children: [
          Text(c.flag, style: const TextStyle(fontSize:22)),
          const SizedBox(width:14),
          Expanded(child: Text(c.name, style: TextStyle(
            fontFamily:'Inter', fontSize:15, fontWeight:FontWeight.w600,
            color: sel ? AppColors.primary : AppColors.textPrimary))),
          if (c.multiClimate && !sel)
            const Icon(Icons.location_on_outlined, size:14, color:AppColors.textSecondary),
          if (sel)
            const Padding(padding: EdgeInsets.only(left:6),
              child: Icon(Icons.check_circle_rounded, color:AppColors.primary, size:20)),
        ])));
  }
}
