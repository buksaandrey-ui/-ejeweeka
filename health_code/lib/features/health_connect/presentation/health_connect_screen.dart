// lib/features/health_connect/presentation/health_connect_screen.dart
// HC-1: Health Connect — подключение и управление интеграцией
// Спека: screens-map.md §HC-1 / §U-14
//   Блок 1 — Статус подключения (платформа, статус, последняя синхронизация)
//   Блок 2 — Переключатели данных (сон, шаги, тренировки, вес)
//   Блок 3 — Действия (подключить, переподключить, отключить)
//   Доступ: Black+ (White → замок)

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/widgets/status_gate.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class HealthConnectScreen extends ConsumerStatefulWidget {
  const HealthConnectScreen({super.key});

  @override
  ConsumerState<HealthConnectScreen> createState() => _HealthConnectScreenState();
}

class _HealthConnectScreenState extends ConsumerState<HealthConnectScreen> {
  bool _connected = false;
  String? _lastSync;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isBlack = hasStatusAccess(ref, RequiredTier.black);

    // Determine platform
    final platformName = _isIOS ? 'Apple Health' : 'Google Health Connect';
    final platformIcon = _isIOS ? Icons.apple_rounded : Icons.monitor_heart_outlined;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Health Connect',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: !isBlack
          ? _lockedView()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Блок 1: Статус подключения ────────────────────
                _connectionStatus(platformName, platformIcon),
                const SizedBox(height: 20),

                // ── Блок 2: Переключатели данных ──────────────────
                _dataToggles(profile),
                const SizedBox(height: 20),

                // ── Блок 3: Действия ──────────────────────────────
                _actions(platformName),

                // ── Поведение при смене статуса ───────────────────
                const SizedBox(height: 24),
                _infoCard(),
              ]),
            ),
    );
  }

  bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false; // web or other
    }
  }

  Widget _lockedView() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.monitor_heart_outlined, size: 36, color: AppColors.primary),
      ),
      const SizedBox(height: 16),
      const Text('Синхронизация здоровья', style: TextStyle(fontFamily: 'Inter',
        fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Подключи Black для синхронизации\nс Apple Health / Google Health Connect',
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
  ));

  Widget _connectionStatus(String platform, IconData icon) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _connected
            ? [const Color(0xFF10B981).withValues(alpha: 0.08), const Color(0xFF10B981).withValues(alpha: 0.02)]
            : [const Color(0xFFF3F4F6), const Color(0xFFFAFAFA)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _connected
          ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFE5E7EB)),
    ),
    child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: (_connected ? const Color(0xFF10B981) : AppColors.textSecondary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 28,
          color: _connected ? const Color(0xFF10B981) : AppColors.textSecondary),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(platform, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(_connected ? 'Подключено' : 'Не подключено',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
              color: _connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.w600)),
        ]),
        if (_lastSync != null) ...[
          const SizedBox(height: 2),
          Text('Синхронизация: $_lastSync',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
        ],
      ])),
    ]),
  );

  Widget _dataToggles(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        _toggleRow(Icons.bedtime_outlined, 'Сон', profile.hcSleep,
          (v) => ref.read(profileNotifierProvider.notifier).saveField('hc_sleep', v)),
        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
        _toggleRow(Icons.directions_walk_outlined, 'Шаги', profile.hcSteps,
          (v) => ref.read(profileNotifierProvider.notifier).saveField('hc_steps', v)),
        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
        _toggleRow(Icons.fitness_center_outlined, 'Тренировки', profile.hcWorkouts,
          (v) => ref.read(profileNotifierProvider.notifier).saveField('hc_workouts', v)),
        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
        _toggleRow(Icons.monitor_weight_outlined, 'Вес', profile.hcWeight,
          (v) => ref.read(profileNotifierProvider.notifier).saveField('hc_weight', v)),
      ]),
    );
  }

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) =>
    SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
        fontWeight: FontWeight.w600)),
      value: _connected ? value : false,
      onChanged: _connected ? (v) { setState(() {}); onChanged(v); } : null,
      activeColor: AppColors.primary,
    );

  Widget _actions(String platform) => Column(children: [
    SizedBox(
      width: double.infinity, height: 48,
      child: FilledButton.icon(
        onPressed: () {
          setState(() {
            _connected = !_connected;
            if (_connected) {
              final now = DateTime.now();
              _lastSync = '${now.hour}:${now.minute.toString().padLeft(2, '0')} сегодня';
            } else {
              _lastSync = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_connected
                ? '✅ $platform подключён' : '❌ $platform отключён'),
            backgroundColor: _connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            duration: const Duration(seconds: 2)));
        },
        icon: Icon(_connected ? Icons.sync_rounded : Icons.add_link_rounded, size: 18),
        label: Text(_connected ? 'Переподключить' : 'Подключить',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: _connected ? const Color(0xFF6366F1) : AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ),
    if (_connected) ...[
      const SizedBox(height: 10),
      TextButton(
        onPressed: () {
          setState(() { _connected = false; _lastSync = null; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Интеграция отключена'),
            backgroundColor: Color(0xFFEF4444), duration: Duration(seconds: 2)));
        },
        child: const Text('Отключить интеграцию',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFEF4444))),
      ),
    ],
  ]);

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F9FF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFBAE6FD))),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0284C7)),
      SizedBox(width: 10),
      Expanded(child: Text(
        'При даунгрейде на White импорт приостанавливается, '
        'но данные сохраняются. При повышении статуса — импорт возобновляется автоматически.',
        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF0369A1), height: 1.4),
      )),
    ]),
  );
}
