// lib/features/photo/presentation/photo_screen.dart
// PH-1: Анализ фото еды через Gemini Vision
// - ImagePicker (камера или галерея)
// - Multipart POST /api/v1/photo/analyze (с контекстом профиля)
// - Показ: название блюда, ккал, КБЖУ, вердикт, предупреждения

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_code/core/network/api_client.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/auth/data/auth_service.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/features/photo/data/photo_analysis_result.dart';
import 'package:health_code/features/plan/providers/plan_provider.dart';

class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});

  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  File? _selectedImage;
  PhotoAnalysisResult? _result;
  bool _loading = false;
  String? _error;
  final _picker = ImagePicker();
  int _dailyCount = 0;
  static const _maxDaily = 5;
  static const _countKey = 'hc_photo_count';

  @override
  void initState() {
    super.initState();
    _loadDailyCount();
  }

  Future<void> _loadDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    _dailyCount = prefs.getInt('${_countKey}_$today') ?? 0;
    if (mounted) setState(() {});
  }

  Future<void> _incrementCount() async {
    _dailyCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_countKey}_${_todayKey()}', _dailyCount);
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int get _remaining => (_maxDaily - _dailyCount).clamp(0, _maxDaily);
  Future<void> _pickImage(ImageSource source) async {
    if (_dailyCount >= _maxDaily) {
      setState(() => _error = 'Лимит $_maxDaily анализов в день исчерпан. Попробуй завтра!');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _selectedImage = File(picked.path);
        _result = null;
        _error = null;
      });
      await _analyze();
    } catch (e) {
      setState(() => _error = 'Не удалось получить изображение: $e');
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() { _loading = true; _error = null; });

    try {
      final profile = ref.read(profileProvider);
      final planState = ref.read(planNotifierProvider);
      final targetKcal = (planState is PlanLoaded) ? planState.plan.targetKcal : 2000;

      final authService = ref.read(authServiceProvider);
      final token = await authService.getValidToken();

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: 'photo.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'goal': profile.goal ?? '',
        'allergies': profile.allergies.toString(),
        'diseases': profile.diseases.toString(),
        'daily_calories': targetKcal.toString(),
        'calories_consumed': '0',
      });

      final res = await ApiClient.instance.post(
        '/api/v1/photo/analyze',
        data: formData,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        await _incrementCount();
        setState(() => _result = PhotoAnalysisResult.fromJson(res.data));
      } else {
        setState(() => _error = 'Ошибка сервера: ${res.data}');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['detail'] as String?
          ?? 'Ошибка сети. Проверьте подключение.');
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              const Text('Анализ фото',
                style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800)),
              Row(children: [
                const Expanded(child: Text('Сфотографируйте блюдо — ИИ определит КБЖУ',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))),
                // Spec Блок 4: Счётчик
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remaining > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('$_remaining/$_maxDaily',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700,
                      color: _remaining > 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Image picker area ──────────────────────────────
              _imageArea(),
              const SizedBox(height: 16),

              // ── Picker buttons ─────────────────────────────────
              Row(children: [
                Expanded(child: _pickerBtn(Icons.camera_alt_rounded, 'Камера', ImageSource.camera)),
                const SizedBox(width: 12),
                Expanded(child: _pickerBtn(Icons.photo_library_rounded, 'Галерея', ImageSource.gallery)),
              ]),

              // ── Loading ─────────────────────────────────────────
              if (_loading) ...[
                const SizedBox(height: 24),
                _loadingCard(),
              ],

              // ── Error ───────────────────────────────────────────
              if (_error != null && !_loading) ...[
                const SizedBox(height: 16),
                _errorCard(_error!),
              ],

              // ── Result ──────────────────────────────────────────
              if (_result != null && !_loading) ...[
                const SizedBox(height: 20),
                _resultCard(_result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageArea() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage != null ? AppColors.primary : const Color(0xFFE5E7EB),
            width: _selectedImage != null ? 2 : 1.5,
            style: _selectedImage != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _selectedImage != null
              ? Stack(fit: StackFit.expand, children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  if (_loading) Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('Нажмите чтобы добавить фото',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('JPEG или PNG, до 10 МБ',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textDisabled)),
                ]),
        ),
      ),
    );
  }

  Widget _pickerBtn(IconData icon, String label, ImageSource source) =>
    ElevatedButton.icon(
      onPressed: _loading ? null : () => _pickImage(source),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );

  Widget _loadingCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: [
      const CircularProgressIndicator(color: AppColors.primary),
      const SizedBox(height: 16),
      const Text('🧠 Анализируем фото...', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
        fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Gemini Vision определяет блюдо и считает КБЖУ',
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
        textAlign: TextAlign.center),
    ]),
  );

  Widget _errorCard(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEF9A9A))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
        color: Color(0xFFC62828)))),
      TextButton(onPressed: _analyze, child: const Text('Повторить')),
    ]),
  );

  Widget _resultCard(PhotoAnalysisResult r) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Dish name + confidence
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(r.foodName,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800,
                color: Colors.white))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
              child: Text(r.confidenceLabel,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('≈ ${r.portionGrams}г • ${r.calories} ккал',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white70)),
          const SizedBox(height: 12),
          // Macro row
          Row(children: [
            _whitePill('Б', '${r.macros.proteins.toStringAsFixed(0)}г', AppColors.protein),
            const SizedBox(width: 6),
            _whitePill('Ж', '${r.macros.fats.toStringAsFixed(0)}г', AppColors.fat),
            const SizedBox(width: 6),
            _whitePill('У', '${r.macros.carbs.toStringAsFixed(0)}г', AppColors.carb),
            const SizedBox(width: 6),
            _whitePill('К', '${r.macros.fiber.toStringAsFixed(0)}г', const Color(0xFFA5D6A7)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // Verdict
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('💬', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Вердикт диетолога', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(r.verdict.isNotEmpty ? r.verdict : r.impact,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5)),
        ]),
      ),

      // Warnings
      if (r.hasWarnings) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCC02))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 18),
              SizedBox(width: 6),
              Text('Предупреждения', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFFF57C00))),
            ]),
            const SizedBox(height: 8),
            ...r.warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('• ', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.bold)),
                Expanded(child: Text(w, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                  color: Color(0xFF5D4037), height: 1.4))),
              ]),
            )),
          ]),
        ),
      ],

      // Impact
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.bar_chart_rounded, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(r.impact, style: const TextStyle(fontFamily: 'Inter',
            fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500))),
        ]),
      ),
    ],
  );

  Widget _whitePill(String label, String value, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
        fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white70)),
    ]),
  );
}
