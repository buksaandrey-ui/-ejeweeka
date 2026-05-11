// lib/features/onboarding/providers/profile_provider.dart
// Riverpod providers — sync reads from SharedPreferences + async saves

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_model.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';

part 'profile_provider.g.dart';

// ── Read current profile ──────────────────────────────────────────
@riverpod
UserProfile profile(ProfileRef ref) {
  return ProfileRepository.getOrCreate();
}

// ── Is onboarding complete? ───────────────────────────────────────
@riverpod
bool isOnboarded(IsOnboardedRef ref) {
  return ref.watch(profileProvider).onboardingComplete;
}

// ── ProfileNotifier: saveField + invalidation ─────────────────────
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  UserProfile build() => ProfileRepository.getOrCreate();

  Future<void> saveField(String key, dynamic value) async {
    await ProfileRepository.saveField(key, value);
    ref.invalidateSelf();
    ref.invalidate(profileProvider);
  }

  Future<void> saveFields(Map<String, dynamic> fields) async {
    await ProfileRepository.saveFields(fields);
    ref.invalidateSelf();
    ref.invalidate(profileProvider);
  }

  Future<void> completeOnboarding() async {
    await ProfileRepository.completeOnboarding();
    ref.invalidateSelf();
    ref.invalidate(profileProvider);
  }
}
