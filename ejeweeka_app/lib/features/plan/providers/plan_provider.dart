// lib/features/plan/providers/plan_provider.dart
// Riverpod providers for plan state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/network/api_client.dart';
import 'package:ejeweeka_app/features/auth/data/auth_service.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';
import 'package:ejeweeka_app/features/plan/data/plan_repository.dart';
import 'package:ejeweeka_app/features/plan/domain/plan_generation_use_case.dart';

// ─── Plan state ─────────────────────────────────────────────────

sealed class PlanState {
  const PlanState();
}

class PlanIdle extends PlanState { const PlanIdle(); }
class PlanLoading extends PlanState { const PlanLoading(); }
class PlanLoaded extends PlanState {
  final MealPlan plan;
  final bool fromCache;
  final bool isStale;
  const PlanLoaded(this.plan, {this.fromCache = false, this.isStale = false});
}
class PlanAwaitingReview extends PlanState {
  final MealPlan rawPlan;
  const PlanAwaitingReview(this.rawPlan);
}
class PlanFailed extends PlanState {
  final String message;
  final String? errorCode;
  const PlanFailed(this.message, {this.errorCode});
}
class PlanOffline extends PlanState {
  final MealPlan plan;
  const PlanOffline(this.plan);
}

// ─── Providers ──────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ApiClient.instance;
  return AuthService(dio);
});

final planUseCaseProvider = Provider<PlanGenerationUseCase>((ref) {
  final dio = ApiClient.instance;
  final auth = ref.watch(authServiceProvider);
  return PlanGenerationUseCase(dio: dio, auth: auth);
});

/// Loads cached plan on startup
final cachedPlanProvider = FutureProvider<MealPlan?>((ref) async {
  return PlanRepository.loadCached();
});

/// Main plan notifier
class PlanNotifier extends StateNotifier<PlanState> {
  final PlanGenerationUseCase _useCase;
  final Ref _ref;

  PlanNotifier(this._useCase, this._ref) : super(const PlanIdle());

  Future<void> generate() async {
    state = const PlanLoading();
    final profile = _ref.read(profileProvider);
    final result = await _useCase.generate(profile);
    state = switch (result) {
      PlanSuccess s => s.fromCache ? PlanLoaded(s.plan, fromCache: true) : PlanAwaitingReview(s.plan),
      PlanOfflineFallback o => PlanOffline(o.plan),
      PlanError e => PlanFailed(e.message, errorCode: e.errorCode),
    };
  }

  Future<void> confirmPlan(MealPlan finalPlan) async {
    await PlanRepository.savePlan(finalPlan);
    state = PlanLoaded(finalPlan);
  }

  Future<void> loadCached() async {
    final plan = await PlanRepository.loadCached();
    if (plan != null) {
      state = PlanLoaded(plan, fromCache: true, isStale: plan.isStale);
    }
  }

  Future<void> swapMeal(int dayNumber, String mealType, MealItem newMeal) async {
    if (state is PlanLoaded) {
      final currentPlan = (state as PlanLoaded).plan;
      final newDays = currentPlan.days.map((day) {
        if (day.dayNumber == dayNumber) {
          final newMeals = day.meals.map((m) {
            if (m.mealType == mealType) return newMeal;
            return m;
          }).toList();
          return day.copyWith(meals: newMeals);
        }
        return day;
      }).toList();
      
      final updatedPlan = currentPlan.copyWith(days: newDays);
      await PlanRepository.savePlan(updatedPlan);
      state = PlanLoaded(
        updatedPlan, 
        fromCache: (state as PlanLoaded).fromCache, 
        isStale: (state as PlanLoaded).isStale
      );
    }
  }

  void reset() => state = const PlanIdle();
}

final planNotifierProvider = StateNotifierProvider<PlanNotifier, PlanState>((ref) {
  final useCase = ref.watch(planUseCaseProvider);
  return PlanNotifier(useCase, ref);
});
