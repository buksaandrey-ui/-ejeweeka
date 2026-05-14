import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/utils/motivation_engine.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  // Состояние: индекс упражнения -> массив булевых значений (выполнены ли подходы)
  final Map<int, List<bool>> _setsProgress = {};
  
  // Состояние таймера
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    final exercises = (widget.workout['exercises'] as List<dynamic>?) ?? [];
    for (int i = 0; i < exercises.length; i++) {
      final sets = (exercises[i]['sets'] as num?)?.toInt() ?? 3;
      _setsProgress[i] = List.generate(sets, (_) => false);
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _toggleSet(int exerciseIndex, int setIndex) {
    if (_setsProgress[exerciseIndex]![setIndex]) return; // Нельзя отменить выполненный

    setState(() {
      _setsProgress[exerciseIndex]![setIndex] = true;
    });
    
    // Легкая вибрация при тапе (Геймификация)
    HapticFeedback.lightImpact();

    // Запускаем таймер отдыха
    _startRestTimer(60); // Дефолт 60 сек, можно брать из JSON
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = seconds;
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        _stopRestTimer();
        HapticFeedback.heavyImpact(); // Сигнал окончания отдыха
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercises = (widget.workout['exercises'] as List<dynamic>?) ?? [];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: exercises.isEmpty
                      ? _buildEmptyActivityStub()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Отступ под плашку таймера
                          itemCount: exercises.length,
                          itemBuilder: (context, i) => _buildExerciseCard(exercises[i] as Map<String, dynamic>, i),
                        ),
                ),
              ],
            ),
            
            // Плашка таймера отдыха (поверх списка)
            if (_isResting)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildRestTimerOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.workout['title'] ?? 'Тренировка',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${widget.workout['muscle_group'] ?? 'Всё тело'} • ~${widget.workout['estimated_minutes'] ?? 45} мин',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityStub() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_run_rounded,
                  size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Время действовать!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Для этой активности нет пошаговых инструкций. Просто выполни её в своём темпе!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  final profile = ref.read(profileProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${MotivationEngine.getPostWorkout(profile)}! Активность завершена.'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: const Text('Сделано'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final name = exercise['exercise_name'] ?? 'Упражнение';
    final reps = exercise['reps'] ?? 12;
    final sets = _setsProgress[index]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заглушка для видео/гифки
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_outline_rounded, size: 48, color: Color(0xFF9CA3AF)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                
                // Рендер чек-листов (кружочков подходов)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(sets.length, (setIndex) {
                    final isDone = sets[setIndex];
                    return GestureDetector(
                      onTap: () => _toggleSet(index, setIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF10B981) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          boxShadow: isDone ? [
                            BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ] : [],
                        ),
                        child: Center(
                          child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                            : Text(reps.toString(), style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Отдых', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                  Text('00:${_restSeconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: _stopRestTimer,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Пропустить', style: TextStyle(fontFamily: 'Inter', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
