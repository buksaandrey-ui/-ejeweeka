// lib/features/onboarding/data/profile_model.dart
// UserProfile — SSOT for all canonical keys from PROJECT_CONTEXT.md
// Stored as JSON in SharedPreferences under key 'aidiet_profile'
// NOTE: Encryption of sensitive fields via flutter_secure_storage is implemented
//       in ProfileRepository for medical data fields.

import 'dart:convert';

class UserProfile {
  UserProfile();

  // ── O-1 ──────────────────────────────────────────────────────
  String? country;
  String? city;

  // ── O-2 ──────────────────────────────────────────────────────
  String? goal;
  bool wantsToLoseWeight = false; // from O-3 branch
  String? weightLossDetails;

  // ── O-3 ──────────────────────────────────────────────────────
  String? name;
  String? gender; // 'male' | 'female'
  int? age;
  double? height;
  double? weight;
  double? bmi;
  String? bmiClass; // 'underweight' | 'normal' | 'overweight' | 'obese'
  double? bmr;
  double? waist;
  String? bodyType;
  String? fatDistribution;

  // ── O-4 ──────────────────────────────────────────────────────
  double? targetWeight;
  int? targetTimelineWeeks;
  String? paceClassification;
  String? speedPriority;
  String? targetDate;

  // ── O-5 ────────────────────────────────────────────────────────────────
  List<String> diets = [];
  bool hasAllergies = false;
  List<String> allergies = [];

  // ── O-6 ──────────────────────────────────────────────────────
  List<String> symptoms = [];
  List<String> diseases = [];
  String? medications;
  String? takesMedications; // 'yes' | 'no' — O-7 males too
  String? takesContraceptives;
  String? customCondition;
  bool o6Visited = false;

  // ── O-7 ──────────────────────────────────────────────────────
  List<String> womensHealth = [];

  // ── O-8 ──────────────────────────────────────────────────────
  String? mealPattern;
  String? fastingType;
  String? fastingState;
  String? dailyFormat;
  String? dailyStart;
  int? dailyMeals;
  String? dailyWindowEnd;
  String? periodicFormat;
  String? periodicFreq;
  List<int> periodicDays = [];
  String? periodicStart;

  // ── O-9 ────────────────────────────────────────────────────────────
  String? bedtime;
  String? wakeupTime;
  String? sleepPattern;
  double? sleepDurationHours;

  // ── O-10 ─────────────────────────────────────────────────────
  String? activityLevel;
  String? activityDuration; // '30min' | '45min' | '60min' | '90min+'
  List<String> activityTypes = [];
  double? activityMultiplier;
  
  // Тренировки (Workout Engine)
  String? fitnessLevel;
  String? workoutLocation;
  List<String> equipment = [];
  List<String> physicalLimitations = [];
  int? trainingDays;

  // ── O-11 ─────────────────────────────────────────────────────
  String? budgetLevel;
  String? cookingStyle;  // 'daily' | 'batch_2_3_days' | 'batch_weekly' | 'none'
  String? cookingTime;
  String? shoppingFrequency;

  // ── O-12 ───────────────────────────────────────────────────────────
  bool hasBloodTests = false;
  String? bloodTests;

  // ── O-13 ───────────────────────────────────────────────────────────
  bool currentlyTakesSupplements = false;
  String? supplements;
  String? supplementOpenness;

  // ── O-14 ─────────────────────────────────────────────────────
  List<String> motivationBarriers = [];

  // ── O-15 ─────────────────────────────────────────────────────
  List<String> likedFoods = [];
  List<String> dislikedFoods = [];
  List<String> excludedMealTypes = [];

  // ── O-17 ───────────────────────────────────────────────────────
  String? subscriptionStatus;
  String? chosenStatus;

  // ── AI Personality ─────────────────────────────────────────────
  String aiPersonality = 'premium'; // premium | buddy | strict | sassy

  // ── Calculated ─────────────────────────────────────────────────────
  double? bmrKcal;
  double? targetDailyCalories;
  double? targetDailyFiber;
  double? tdeeCalculated;
  double? waistToHeightRatio;

  // ── UI ───────────────────────────────────────────────────────
  String selectedTheme = 'default';
  DateTime? firstLaunch;
  DateTime? trialStart;
  int schemaVersion = 1;
  bool onboardingComplete = false;
  bool disclaimerAccepted = false;

  // ── Notifications ────────────────────────────────────────────
  bool notifMeals = true;
  bool notifVitamins = true;
  bool notifMedications = true;
  bool notifWorkouts = true;
  bool notifWater = true;
  bool notifWeeklyReport = true;

  // ── Health Connect ────────────────────────────────────────────
  bool hcSleep = true;
  bool hcSteps = true;
  bool hcWorkouts = true;
  bool hcWeight = true;

  // ── saveField: AIDiet.saveField() equivalent ──────────────────
  void setField(String key, dynamic value) {
    switch (key) {
      case 'country': country = value?.toString(); break;
      case 'city': city = value?.toString(); break;
      case 'goal': goal = value?.toString(); break;
      case 'wants_to_lose_weight': wantsToLoseWeight = value == true || value == 'true'; break;
      case 'weight_loss_details': weightLossDetails = value?.toString(); break;
      case 'name': name = value?.toString(); break;
      case 'gender': gender = value?.toString(); break;
      case 'age': age = _parseInt(value); break;
      case 'height': height = _parseDouble(value); break;
      case 'weight': weight = _parseDouble(value); break;
      case 'bmi': bmi = _parseDouble(value); break;
      case 'bmi_class': bmiClass = value?.toString(); break;
      case 'bmr': bmr = _parseDouble(value); break;
      case 'waist': waist = _parseDouble(value); break;
      case 'body_type': bodyType = value?.toString(); break;
      case 'fat_distribution': fatDistribution = value?.toString(); break;
      case 'target_weight': targetWeight = _parseDouble(value); break;
      case 'target_timeline_weeks': targetTimelineWeeks = _parseInt(value); break;
      case 'pace_classification': paceClassification = value?.toString(); break;
      case 'speed_priority': speedPriority = value?.toString(); break;
      case 'target_date': targetDate = value?.toString(); break;
      case 'has_allergies': hasAllergies = value == true || value == 'true'; break;
      case 'diets': diets = _parseList(value); break;
      case 'allergies': allergies = _parseList(value); break;
      case 'symptoms': symptoms = _parseList(value); break;
      case 'diseases': diseases = _parseList(value); break;
      case 'medications': medications = value?.toString(); break;
      case 'takes_medications': takesMedications = value?.toString(); break;
      case 'takes_contraceptives': takesContraceptives = value?.toString(); break;
      case 'custom_condition': customCondition = value?.toString(); break;
      case 'o6_visited': o6Visited = value == true || value == 'true'; break;
      case 'womens_health': womensHealth = _parseList(value); break;
      case 'meal_pattern': mealPattern = value?.toString(); break;
      case 'fasting_type': fastingType = value?.toString(); break;
      case 'fasting_state': fastingState = value?.toString(); break;
      case 'daily_format': dailyFormat = value?.toString(); break;
      case 'daily_start': dailyStart = value?.toString(); break;
      case 'daily_meals': dailyMeals = _parseInt(value); break;
      case 'daily_window_end': dailyWindowEnd = value?.toString(); break;
      case 'periodic_format': periodicFormat = value?.toString(); break;
      case 'periodic_freq': periodicFreq = value?.toString(); break;
      case 'periodic_days': periodicDays = _parseIntList(value); break;
      case 'periodic_start': periodicStart = value?.toString(); break;
      case 'bedtime': bedtime = value?.toString(); break;
      case 'wakeup_time': wakeupTime = value?.toString(); break;
      case 'sleep_pattern': sleepPattern = value?.toString(); break;
      case 'sleep_duration_hours': sleepDurationHours = _parseDouble(value); break;
      case 'activity_level': activityLevel = value?.toString(); break;
      case 'activity_duration': activityDuration = value?.toString(); break;
      case 'activity_types': activityTypes = _parseList(value); break;
      case 'activity_multiplier': activityMultiplier = _parseDouble(value); break;
      case 'fitness_level': fitnessLevel = value?.toString(); break;
      case 'workout_location': workoutLocation = value?.toString(); break;
      case 'equipment': equipment = _parseList(value); break;
      case 'physical_limitations': physicalLimitations = _parseList(value); break;
      case 'training_days': trainingDays = _parseInt(value); break;
      case 'budget_level': budgetLevel = value?.toString(); break;
      case 'cooking_style': cookingStyle = value?.toString(); break;
      case 'cooking_time': cookingTime = value?.toString(); break;
      case 'shopping_frequency': shoppingFrequency = value?.toString(); break;
      case 'blood_tests': bloodTests = value?.toString(); break;
      case 'has_blood_tests': hasBloodTests = value == true || value == 'true'; break;
      case 'currently_takes_supplements': currentlyTakesSupplements = value == true || value == 'true'; break;
      case 'supplements': supplements = value?.toString(); break;
      case 'supplement_openness': supplementOpenness = value?.toString(); break;
      case 'motivation_barriers': motivationBarriers = _parseList(value); break;
      case 'liked_foods': likedFoods = _parseList(value); break;
      case 'disliked_foods': dislikedFoods = _parseList(value); break;
      case 'excluded_meal_types': excludedMealTypes = _parseList(value); break;
      case 'subscription_status': subscriptionStatus = value?.toString(); break;
      case 'chosen_status': chosenStatus = value?.toString(); break;
      case 'first_launch':
        if (value is String) firstLaunch = DateTime.tryParse(value);
        break;
      case 'trial_start':
        if (value is String) trialStart = DateTime.tryParse(value);
        break;
      case 'bmr_kcal': bmrKcal = _parseDouble(value); break;
      case 'target_daily_calories': targetDailyCalories = _parseDouble(value); break;
      case 'target_daily_fiber': targetDailyFiber = _parseDouble(value); break;
      case 'tdee_calculated': tdeeCalculated = _parseDouble(value); break;
      case 'selected_theme': selectedTheme = value?.toString() ?? 'default'; break;
      case 'waist_to_height_ratio': waistToHeightRatio = _parseDouble(value); break;
      case 'disclaimer_accepted': disclaimerAccepted = value == true || value == 'true'; break;
      case 'notif_meals': notifMeals = value == true || value == 'true'; break;
      case 'notif_vitamins': notifVitamins = value == true || value == 'true'; break;
      case 'notif_medications': notifMedications = value == true || value == 'true'; break;
      case 'notif_workouts': notifWorkouts = value == true || value == 'true'; break;
      case 'notif_water': notifWater = value == true || value == 'true'; break;
      case 'notif_weekly_report': notifWeeklyReport = value == true || value == 'true'; break;
      case 'hc_sleep': hcSleep = value == true || value == 'true'; break;
      case 'hc_steps': hcSteps = value == true || value == 'true'; break;
      case 'hc_workouts': hcWorkouts = value == true || value == 'true'; break;
      case 'hc_weight': hcWeight = value == true || value == 'true'; break;
      case 'ai_personality': aiPersonality = value?.toString() ?? 'premium'; break;
    }
  }

  // ── JSON serialization ────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'country': country, 'city': city, 'goal': goal,
    'wants_to_lose_weight': wantsToLoseWeight,
    'weight_loss_details': weightLossDetails, 'name': name,
    'gender': gender, 'age': age, 'height': height, 'weight': weight,
    'bmi': bmi, 'bmi_class': bmiClass, 'bmr': bmr, 'waist': waist,
    'body_type': bodyType, 'fat_distribution': fatDistribution,
    'target_weight': targetWeight,
    'target_timeline_weeks': targetTimelineWeeks,
    'pace_classification': paceClassification,
    'speed_priority': speedPriority,
    'target_date': targetDate,
    'has_allergies': hasAllergies,
    'diets': diets, 'allergies': allergies, 'symptoms': symptoms,
    'diseases': diseases, 'medications': medications,
    'takes_medications': takesMedications,
    'takes_contraceptives': takesContraceptives,
    'custom_condition': customCondition, 'o6_visited': o6Visited,
    'womens_health': womensHealth, 'meal_pattern': mealPattern,
    'fasting_type': fastingType, 'fasting_state': fastingState,
    'daily_format': dailyFormat, 'daily_start': dailyStart, 'daily_meals': dailyMeals, 'daily_window_end': dailyWindowEnd,
    'periodic_format': periodicFormat, 'periodic_freq': periodicFreq, 'periodic_days': periodicDays, 'periodic_start': periodicStart,
    'bedtime': bedtime, 'wakeup_time': wakeupTime,
    'sleep_pattern': sleepPattern, 'sleep_duration_hours': sleepDurationHours,
    'activity_level': activityLevel,
    'activity_duration': activityDuration,
    'activity_types': activityTypes, 'activity_multiplier': activityMultiplier,
    'fitness_level': fitnessLevel, 'workout_location': workoutLocation,
    'equipment': equipment, 'physical_limitations': physicalLimitations,
    'training_days': trainingDays,
    'budget_level': budgetLevel, 'cooking_style': cookingStyle, 'cooking_time': cookingTime,
    'shopping_frequency': shoppingFrequency,
    'blood_tests': bloodTests, 'has_blood_tests': hasBloodTests,
    'currently_takes_supplements': currentlyTakesSupplements,
    'supplements': supplements,
    'supplement_openness': supplementOpenness,
    'motivation_barriers': motivationBarriers, 'liked_foods': likedFoods,
    'disliked_foods': dislikedFoods, 'excluded_meal_types': excludedMealTypes,
    'subscription_status': subscriptionStatus, 'chosen_status': chosenStatus,
    'bmr_kcal': bmrKcal,
    'target_daily_calories': targetDailyCalories,
    'target_daily_fiber': targetDailyFiber,
    'tdee_calculated': tdeeCalculated,
    'waist_to_height_ratio': waistToHeightRatio,
    'selected_theme': selectedTheme,
    'first_launch': firstLaunch?.toIso8601String(),
    'trial_start': trialStart?.toIso8601String(),
    'schema_version': schemaVersion,
    'onboarding_complete': onboardingComplete,
    'disclaimer_accepted': disclaimerAccepted,
    'notif_meals': notifMeals, 'notif_vitamins': notifVitamins,
    'notif_medications': notifMedications, 'notif_workouts': notifWorkouts,
    'notif_water': notifWater, 'notif_weekly_report': notifWeeklyReport,
    'hc_sleep': hcSleep, 'hc_steps': hcSteps,
    'hc_workouts': hcWorkouts, 'hc_weight': hcWeight,
    'ai_personality': aiPersonality,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final p = UserProfile();
    json.forEach((key, value) => p.setField(key, value));
    p.wantsToLoseWeight = json['wants_to_lose_weight'] == true;
    p.onboardingComplete = json['onboarding_complete'] == true;
    p.schemaVersion = json['schema_version'] as int? ?? 1;
    p.firstLaunch = json['first_launch'] != null
        ? DateTime.tryParse(json['first_launch'].toString())
        : null;
    p.notifMeals = json['notif_meals'] != false;
    p.notifVitamins = json['notif_vitamins'] != false;
    p.notifMedications = json['notif_medications'] != false;
    p.notifWorkouts = json['notif_workouts'] != false;
    p.notifWater = json['notif_water'] != false;
    p.notifWeeklyReport = json['notif_weekly_report'] != false;
    p.hcSleep = json['hc_sleep'] != false;
    p.hcSteps = json['hc_steps'] != false;
    p.hcWorkouts = json['hc_workouts'] != false;
    p.hcWeight = json['hc_weight'] != false;
    return p;
  }

  String toJsonString() => jsonEncode(toJson());
  static UserProfile fromJsonString(String s) =>
      UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);

  // ── Helpers ───────────────────────────────────────────────────
  static double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());
  static int? _parseInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());
  static List<String> _parseList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [v.toString()];
  }
  static List<int> _parseIntList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => _parseInt(e)).whereType<int>().toList();
    return [];
  }
}
