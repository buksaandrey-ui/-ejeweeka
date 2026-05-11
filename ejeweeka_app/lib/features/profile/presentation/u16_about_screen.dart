// lib/features/profile/presentation/u16_about_screen.dart
// U-16: О проекте — информация, юридические ссылки, версия
// Спека: screens-map.md §U-16

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';

class U16AboutScreen extends StatelessWidget {
  const U16AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('О проекте',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1 — О продукте ───────────────────────────────
          _sectionCard(
            icon: Icons.favorite_outline_rounded,
            color: AppColors.primary,
            children: [
              const Text('ejeweeka',
                style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Персональный план питания на основе доказательной медицины',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 14),
              _infoRow(Icons.video_library_outlined, 'Проанализировано 4000+ видео реальных врачей'),
              const SizedBox(height: 8),
              _infoRow(Icons.groups_outlined, '20+ специалистов в экспертной базе'),
              const SizedBox(height: 14),
              const Text('СПЕЦИАЛИЗАЦИИ',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _specChip('Эндокринология'),
                _specChip('Гастроэнтерология'),
                _specChip('Диетология'),
                _specChip('Кардиология'),
                _specChip('Нутрициология'),
              ]),
            ],
          ),
          const SizedBox(height: 12),

          // ── Блок 2 — Юридическое ─────────────────────────────
          _sectionCard(
            icon: Icons.gavel_outlined,
            color: const Color(0xFF667EEA),
            children: [
              const Text('Юридическая информация',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _linkRow('Политика конфиденциальности', 'https://ejeweeka.app/privacy'),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _linkRow('Пользовательское соглашение', 'https://ejeweeka.app/terms'),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _linkRow('Согласие на обработку данных', 'https://ejeweeka.app/consent'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Блок 3 — Версия ──────────────────────────────────
          _sectionCard(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF4CAF50),
            children: [
              const Text('Версия приложения',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('ejeweeka v2.2.0',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                      fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Build ${DateTime.now().toString().substring(0, 10)}',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          Center(child: Text('ejeweeka • Zero-Knowledge Privacy',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.6)))),
        ]),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 16, color: AppColors.primary),
    const SizedBox(width: 8),
    Expanded(child: Text(text,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
  ]);

  Widget _specChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
      fontWeight: FontWeight.w500, color: AppColors.primary)),
  );

  Widget _linkRow(String text, String url) => GestureDetector(
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Row(children: [
      Expanded(child: Text(text,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500))),
      const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textSecondary),
    ]),
  );
}
