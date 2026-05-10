// lib/features/family/presentation/family_group_screen.dart
// F-1: Групповой доступ — управление семейным статусом
// Спека: screens-map.md §F-1
//   Блок 1 — Участники (макс 4): аватар, имя, статус
//   Блок 2 — Приглашение (ссылка или email)
//   Блок 3 — Общие настройки (блюда + покупки)
//   Блок 4 — Удаление участника
//   Доступ: Group Gold only

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/widgets/status_gate.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/features/family/presentation/member_profile_screen.dart';

class FamilyGroupScreen extends ConsumerStatefulWidget {
  const FamilyGroupScreen({super.key});

  @override
  ConsumerState<FamilyGroupScreen> createState() => _FamilyGroupScreenState();
}

class _FamilyGroupScreenState extends ConsumerState<FamilyGroupScreen> {
  bool _sharedMeals = false;
  bool _sharedShopping = false;

  // Demo members — in production comes from backend
  final List<_FamilyMember> _members = [
    _FamilyMember('Ты', 'Владелец', true),
    _FamilyMember('Анна', 'Активна', true),
    _FamilyMember('Максим', 'Приглашён', false),
  ];

  @override
  Widget build(BuildContext context) {
    // Gate: Group Gold only
    if (!hasStatusAccess(ref, RequiredTier.familyGold)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background, elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
          title: const Text('Семейный доступ',
            style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                shape: BoxShape.circle),
              child: const Icon(Icons.family_restroom_rounded, size: 36, color: Color(0xFFB45309)),
            ),
            const SizedBox(height: 16),
            const Text('Семейный план', style: TextStyle(fontFamily: 'Inter',
              fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Питание для всей семьи с единым управлением.\nДоступно со статусом Group Gold.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Назад', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            ),
          ]),
        )),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Семейный доступ',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Участники ──────────────────────────────────
          _sectionHeader('УЧАСТНИКИ', '${_members.length}/4'),
          const SizedBox(height: 10),
          ..._members.map((m) => _memberCard(m)),
          const SizedBox(height: 8),
          Text('+690 ₽/мес за каждого участника',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          // ── Блок 2: Приглашение ────────────────────────────────
          _sectionHeader('ПРИГЛАШЕНИЕ', null),
          const SizedBox(height: 10),
          _inviteCard(),
          const SizedBox(height: 24),

          // ── Блок 3: Общие настройки ────────────────────────────
          _sectionHeader('ОБЩИЕ НАСТРОЙКИ', null),
          const SizedBox(height: 10),
          _settingsCard(),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, String? badge) => Row(children: [
    Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
      fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    if (badge != null) ...[
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(badge, style: TextStyle(fontFamily: 'Inter', fontSize: 11,
          fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
    ],
  ]);

  Widget _memberCard(_FamilyMember member) {
    final isOwner = member.name == 'Ты';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: isOwner
                ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFC8A96E)])
                : LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.1)]),
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(member.name[0],
            style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700,
              color: isOwner ? Colors.white : AppColors.primary))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
            fontWeight: FontWeight.w700)),
          Text(member.status, style: TextStyle(fontFamily: 'Inter', fontSize: 12,
            color: member.active ? const Color(0xFF10B981) : AppColors.textSecondary)),
        ])),
        if (!isOwner) ...[
          // View profile
          IconButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MemberProfileScreen(member: member))),
            icon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
          // Remove
          IconButton(
            onPressed: () => _confirmRemove(member),
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
            visualDensity: VisualDensity.compact,
          ),
        ],
        if (isOwner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6)),
            child: const Text('Ты', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
          ),
      ]),
    );
  }

  Widget _inviteCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: [
      SizedBox(
        width: double.infinity, height: 44,
        child: FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('🔗 Ссылка-приглашение скопирована'),
              backgroundColor: AppColors.primary, duration: Duration(seconds: 2)));
          },
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text('Скопировать ссылку',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(height: 12),
      const TextField(
        decoration: InputDecoration(
          hintText: 'Email или телефон',
          isDense: true,
          suffixIcon: Icon(Icons.send_rounded, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
    ]),
  );

  Widget _settingsCard() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: [
      SwitchListTile(
        value: _sharedMeals,
        onChanged: (v) => setState(() => _sharedMeals = v),
        title: const Text('Общие блюда', style: TextStyle(fontFamily: 'Inter',
          fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text('HC подберёт рецепты, подходящие всем',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
        secondary: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
        activeColor: AppColors.primary,
      ),
      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
      SwitchListTile(
        value: _sharedShopping,
        onChanged: (v) => setState(() => _sharedShopping = v),
        title: const Text('Общий список покупок', style: TextStyle(fontFamily: 'Inter',
          fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text('Объединённый S-1 для всей семьи',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
        secondary: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
        activeColor: AppColors.primary,
      ),
    ]),
  );

  void _confirmRemove(_FamilyMember member) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Удалить участника?',
        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: Text('${member.name} будет удалён из группы.',
        style: const TextStyle(fontFamily: 'Inter')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена', style: TextStyle(fontFamily: 'Inter'))),
        TextButton(
          onPressed: () {
            setState(() => _members.remove(member));
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${member.name} удалён'),
              backgroundColor: const Color(0xFFEF4444)));
          },
          child: const Text('Удалить', style: TextStyle(fontFamily: 'Inter',
            color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

class _FamilyMember {
  final String name;
  final String status;
  final bool active;
  _FamilyMember(this.name, this.status, this.active);
}
