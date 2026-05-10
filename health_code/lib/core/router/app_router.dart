// lib/core/router/app_router.dart
// GoRouter config — all screens from screens-map.md
// Directional slide transitions: forward slides right→left, back slides left→right

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/router/slide_transition_page.dart';
import 'package:health_code/features/plan/data/meal_plan_model.dart';

// Onboarding
import 'package:health_code/features/onboarding/presentation/o0_welcome_screen.dart';
import 'package:health_code/features/onboarding/presentation/o1_country_screen.dart';
import 'package:health_code/features/onboarding/presentation/o2_goal_screen.dart';
import 'package:health_code/features/onboarding/presentation/o2_5_ai_personality_screen.dart';
import 'package:health_code/features/onboarding/presentation/o3_profile_screen.dart';
import 'package:health_code/features/onboarding/presentation/o4_weight_loss_screen.dart';
import 'package:health_code/features/onboarding/presentation/o5_restrictions_screen.dart';
import 'package:health_code/features/onboarding/presentation/o6_health_screen.dart';
import 'package:health_code/features/onboarding/presentation/o7_womens_health_screen.dart';
import 'package:health_code/features/onboarding/presentation/o8_meal_pattern_screen.dart';
import 'package:health_code/features/onboarding/presentation/o9_sleep_screen.dart';
import 'package:health_code/features/onboarding/presentation/o10_activity_screen.dart';
import 'package:health_code/features/onboarding/presentation/o11_budget_screen.dart';
import 'package:health_code/features/onboarding/presentation/o12_blood_tests_screen.dart';
import 'package:health_code/features/onboarding/presentation/o13_supplements_screen.dart';
import 'package:health_code/features/onboarding/presentation/o14_motivation_screen.dart';
import 'package:health_code/features/onboarding/presentation/o15_food_prefs_screen.dart';
import 'package:health_code/features/onboarding/presentation/o16_summary_screen.dart';
import 'package:health_code/features/onboarding/presentation/o16_5_plan_breakdown_screen.dart';
import 'package:health_code/features/onboarding/presentation/o17_statuswall_screen.dart';
import 'package:health_code/features/onboarding/presentation/o17_5_disclaimer_screen.dart';
import 'package:health_code/features/onboarding/presentation/activation_code_screen.dart';

// Main app shell + screens
import 'package:health_code/shared/widgets/main_scaffold.dart';
import 'package:health_code/features/dashboard/presentation/dashboard_screen.dart';
import 'package:health_code/features/plan/presentation/weekly_plan_screen.dart';
import 'package:health_code/features/plan/presentation/plan_builder_screen.dart';
import 'package:health_code/features/shopping/presentation/shopping_list_screen.dart';
import 'package:health_code/features/progress/presentation/progress_screen.dart';
import 'package:health_code/features/profile/presentation/profile_screen.dart';
import 'package:health_code/features/photo/presentation/photo_screen.dart';
import 'package:health_code/features/chat/presentation/chat_screen.dart';
import 'package:health_code/features/progress/presentation/hydration_screen.dart';
import 'package:health_code/features/plan/presentation/vitamins_screen.dart';
import 'package:health_code/features/profile/presentation/u12_status_screen.dart';
import 'package:health_code/features/family/presentation/family_group_screen.dart';
import 'package:health_code/features/health_connect/presentation/health_connect_screen.dart';
import 'package:health_code/features/progress/presentation/ai_report_screen.dart';
import 'package:health_code/features/progress/presentation/report_history_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final isOnboarded = ref.watch(isOnboardedProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.o0Welcome,
    redirect: (context, state) async {
      final onOnboarding = state.matchedLocation.startsWith('/onboarding');

      if (isOnboarded && onOnboarding) {
        return Routes.dashboard;
      }
      if (!isOnboarded && !onOnboarding) {
        return Routes.o0Welcome;
      }
      return null;
    },
    routes: [
      // ── ONBOARDING (no shell, no tab bar) ─────────────────────
      GoRoute(
        path: Routes.o0Welcome,
        name: Routes.o0Welcome,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O0WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o1Country,
        name: Routes.o1Country,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O1CountryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o2Goal,
        name: Routes.o2Goal,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O2GoalScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o25AiPersonality,
        name: Routes.o25AiPersonality,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O25AiPersonalityScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o3Profile,
        name: Routes.o3Profile,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O3ProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o4WeightLoss,
        name: Routes.o4WeightLoss,
        redirect: (context, state) {
          // Skip O-4 if goal != weight_loss AND wantsToLoseWeight is false (screens-map.md rule)
          final profile = ref.read(profileProvider);
          if (profile.goal != 'weight_loss' && profile.wantsToLoseWeight != true) {
            return Routes.o5Restrictions;
          }
          return null;
        },
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O4WeightLossScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o5Restrictions,
        name: Routes.o5Restrictions,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O5RestrictionsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o6Health,
        name: Routes.o6Health,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O6HealthScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o7WomensHealth,
        name: Routes.o7WomensHealth,
        redirect: (context, state) {
          // Skip O-7 if gender != female (screens-map.md rule)
          final profile = ref.read(profileProvider);
          if (profile.gender != 'female') {
            return Routes.o8MealPattern;
          }
          return null;
        },
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O7WomensHealthScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o8MealPattern,
        name: Routes.o8MealPattern,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O8MealPatternScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o9Sleep,
        name: Routes.o9Sleep,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O9SleepScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o10Activity,
        name: Routes.o10Activity,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O10ActivityScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o11Budget,
        name: Routes.o11Budget,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O11BudgetScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o12BloodTests,
        name: Routes.o12BloodTests,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O12BloodTestsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o13Supplements,
        name: Routes.o13Supplements,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O13SupplementsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o14Motivation,
        name: Routes.o14Motivation,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O14MotivationScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o15FoodPrefs,
        name: Routes.o15FoodPrefs,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O15FoodPrefsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o16Summary,
        name: Routes.o16Summary,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O16SummaryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o165PlanBreakdown,
        name: Routes.o165PlanBreakdown,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O165PlanBreakdownScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o17Statuswall,
        name: Routes.o17Statuswall,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O17StatuswallScreen(),
        ),
      ),
      GoRoute(
        path: Routes.o175Disclaimer,
        name: Routes.o175Disclaimer,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const O175DisclaimerScreen(),
        ),
      ),
      GoRoute(
        path: Routes.activation,
        name: Routes.activation,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const ActivationCodeScreen(),
        ),
      ),

      // ── MAIN APP (with bottom tab bar — ShellRoute) ────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            name: Routes.dashboard,
            pageBuilder: (_, state) => slideTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.plan,
            name: Routes.plan,
            pageBuilder: (_, state) => slideTransitionPage(
              key: state.pageKey,
              child: const WeeklyPlanScreen(),
            ),
          ),
          GoRoute(
            path: Routes.shopping,
            name: Routes.shopping,
            pageBuilder: (_, state) => slideTransitionPage(
              key: state.pageKey,
              child: const ShoppingListScreen(),
            ),
          ),
          GoRoute(
            path: Routes.progress,
            name: Routes.progress,
            pageBuilder: (_, state) => slideTransitionPage(
              key: state.pageKey,
              child: const ProgressScreen(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: Routes.profile,
            pageBuilder: (_, state) => slideTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
      // ── MODAL / FULL-SCREEN ROUTES (no tab bar) ───────────────
      GoRoute(
        path: Routes.planBuilder,
        name: Routes.planBuilder,
        pageBuilder: (_, state) {
          final rawPlan = state.extra as MealPlan?;
          return slideTransitionPage(
            key: state.pageKey,
            child: rawPlan != null 
              ? PlanBuilderScreen(rawPlan: rawPlan)
              : const SizedBox(), // fallback if missing extra
          );
        },
      ),
      GoRoute(
        path: Routes.photoAnalysis,
        name: Routes.photoAnalysis,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const PhotoScreen(),
        ),
      ),
      GoRoute(
        path: Routes.aiChat,
        name: Routes.aiChat,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const ChatScreen(),
        ),
      ),
      GoRoute(
        path: Routes.hydration,
        name: Routes.hydration,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const HydrationScreen(),
        ),
      ),
      GoRoute(
        path: Routes.vitamins,
        name: Routes.vitamins,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const VitaminsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.statusScreen,
        name: Routes.statusScreen,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const U12StatusScreen(),
        ),
      ),
      GoRoute(
        path: Routes.familyGroup,
        name: Routes.familyGroup,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const FamilyGroupScreen(),
        ),
      ),
      GoRoute(
        path: Routes.healthConnect,
        name: Routes.healthConnect,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const HealthConnectScreen(),
        ),
      ),
      GoRoute(
        path: Routes.aiReport,
        name: Routes.aiReport,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const AiReportScreen(),
        ),
      ),
      GoRoute(
        path: Routes.reportHistory,
        name: Routes.reportHistory,
        pageBuilder: (_, state) => slideTransitionPage(
          key: state.pageKey,
          child: const ReportHistoryScreen(),
        ),
      ),
    ],
  );
}
