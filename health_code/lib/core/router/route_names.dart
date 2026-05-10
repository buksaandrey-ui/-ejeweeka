// lib/core/router/route_names.dart
// All route path constants — single source of truth for navigation

abstract class Routes {
  static const o0Welcome = '/onboarding/welcome';
  static const o1Country = '/onboarding/country';
  static const o2Goal = '/onboarding/goal';
  static const o25AiPersonality = '/onboarding/ai-personality';
  static const o3Profile = '/onboarding/profile';
  static const o4WeightLoss = '/onboarding/weight-loss';
  static const o5Restrictions = '/onboarding/restrictions';
  static const o6Health = '/onboarding/health';
  static const o7WomensHealth = '/onboarding/womens-health';
  static const o8MealPattern = '/onboarding/meal-pattern';
  static const o9Sleep = '/onboarding/sleep';
  static const o10Activity = '/onboarding/activity';
  static const o11Budget = '/onboarding/budget';
  static const o12BloodTests = '/onboarding/blood-tests';
  static const o13Supplements = '/onboarding/supplements';
  static const o14Motivation = '/onboarding/motivation';
  static const o15FoodPrefs = '/onboarding/food-preferences';
  static const o16Summary = '/onboarding/summary';
  static const o165PlanBreakdown = '/onboarding/plan-breakdown';
  static const o17Statuswall = '/onboarding/status';
  static const o175Disclaimer = '/onboarding/disclaimer';
  static const activation = '/onboarding/activation';

  // Main app (tab bar)
  static const dashboard = '/dashboard';
  static const planBuilder = '/plan-builder';
  static const plan = '/plan';
  static const shopping = '/shopping';
  static const progress = '/progress';
  static const profile = '/profile';

  // Nested routes
  static const mealCard = '/plan/meal/:id';
  static const mealSwap = '/plan/meal/:id/swap';
  static const fullRecipe = '/plan/meal/:id/recipe';
  static const vitamins = '/plan/vitamins';
  static const photoAnalysis = '/photo';
  static const aiChat = '/chat';
  static const statusScreen = '/profile/status';
  static const hydration = '/progress/hydration';

  // Phase 6 screens
  static const familyGroup = '/profile/family';
  static const healthConnect = '/profile/health-connect';
  static const productDetail = '/shopping/product';
  static const aiReport = '/progress/report';
  static const reportHistory = '/progress/reports';
  static const themeScreen = '/profile/theme';
}
