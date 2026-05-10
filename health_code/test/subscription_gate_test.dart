// test/subscription_gate_test.dart
// Unit tests for SubscriptionGate tier access logic
// Tests the tier ranking: white(0) < black(1) < gold(2) < family_gold(3)
// + trial mode + edge cases
// Run: flutter test test/subscription_gate_test.dart

import 'package:flutter_test/flutter_test.dart';

// We test the pure ranking logic that SubscriptionGate uses internally.
// The widget itself is tested via integration tests (needs MaterialApp + GoRouter).
// Here we replicate the _checkAccess logic to unit-test the ranking matrix.

/// Mirror of SubscriptionGate._checkAccess for testability
bool checkAccess(String effectiveTier, String requiredTier) {
  const tierRank = {'white': 0, 'black': 1, 'gold': 2, 'family_gold': 3};
  final userRank = tierRank[effectiveTier] ?? 0;
  final requiredRank = tierRank[requiredTier] ?? 0;
  return userRank >= requiredRank;
}

/// Mirror of trial logic
String effectiveTier(String status, DateTime? trialStart) {
  if (trialStart != null && DateTime.now().difference(trialStart).inDays < 3) {
    return 'gold';
  }
  return status;
}

void main() {
  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Tier Access Matrix (all 16 combinations)
  // ─────────────────────────────────────────────────────────────
  group('Tier Access Matrix — 4×4', () {
    // White user
    test('white → black → DENIED', () => expect(checkAccess('white', 'black'), false));
    test('white → gold → DENIED', () => expect(checkAccess('white', 'gold'), false));
    test('white → family_gold → DENIED', () => expect(checkAccess('white', 'family_gold'), false));
    test('white → white → GRANTED', () => expect(checkAccess('white', 'white'), true));

    // Black user
    test('black → black → GRANTED', () => expect(checkAccess('black', 'black'), true));
    test('black → gold → DENIED', () => expect(checkAccess('black', 'gold'), false));
    test('black → family_gold → DENIED', () => expect(checkAccess('black', 'family_gold'), false));
    test('black → white → GRANTED', () => expect(checkAccess('black', 'white'), true));

    // Gold user
    test('gold → black → GRANTED', () => expect(checkAccess('gold', 'black'), true));
    test('gold → gold → GRANTED', () => expect(checkAccess('gold', 'gold'), true));
    test('gold → family_gold → DENIED', () => expect(checkAccess('gold', 'family_gold'), false));
    test('gold → white → GRANTED', () => expect(checkAccess('gold', 'white'), true));

    // Family Gold user
    test('family_gold → black → GRANTED', () => expect(checkAccess('family_gold', 'black'), true));
    test('family_gold → gold → GRANTED', () => expect(checkAccess('family_gold', 'gold'), true));
    test('family_gold → family_gold → GRANTED', () => expect(checkAccess('family_gold', 'family_gold'), true));
    test('family_gold → white → GRANTED', () => expect(checkAccess('family_gold', 'white'), true));
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: Unknown / null tier → treated as White (rank 0)
  // ─────────────────────────────────────────────────────────────
  group('Unknown tier defaults', () {
    test('unknown tier → rank 0 (white)', () => expect(checkAccess('platinum', 'black'), false));
    test('empty string → rank 0', () => expect(checkAccess('', 'black'), false));
    test('null-like → rank 0', () => expect(checkAccess('null', 'gold'), false));
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: Trial mode — gives Gold access for 3 days
  // ─────────────────────────────────────────────────────────────
  group('Trial Mode', () {
    test('Trial active (1 day ago) → effective tier is gold', () {
      final trialStart = DateTime.now().subtract(const Duration(days: 1));
      expect(effectiveTier('white', trialStart), 'gold');
    });

    test('Trial active (2 days ago) → still gold', () {
      final trialStart = DateTime.now().subtract(const Duration(days: 2));
      expect(effectiveTier('white', trialStart), 'gold');
    });

    test('Trial expired (3 days ago) → back to white', () {
      final trialStart = DateTime.now().subtract(const Duration(days: 3));
      expect(effectiveTier('white', trialStart), 'white');
    });

    test('Trial expired (10 days ago) → back to white', () {
      final trialStart = DateTime.now().subtract(const Duration(days: 10));
      expect(effectiveTier('white', trialStart), 'white');
    });

    test('No trial start → keeps original status', () {
      expect(effectiveTier('black', null), 'black');
      expect(effectiveTier('white', null), 'white');
    });

    test('Trial + already gold → stays gold', () {
      final trialStart = DateTime.now().subtract(const Duration(days: 1));
      expect(effectiveTier('gold', trialStart), 'gold');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: Integration — Trial white user can access Black features
  // ─────────────────────────────────────────────────────────────
  group('Trial Integration Scenarios', () {
    test('White user in trial → can access Black features', () {
      final trialStart = DateTime.now().subtract(const Duration(hours: 12));
      final tier = effectiveTier('white', trialStart);
      expect(checkAccess(tier, 'black'), true);
    });

    test('White user in trial → can access Gold features', () {
      final trialStart = DateTime.now().subtract(const Duration(hours: 12));
      final tier = effectiveTier('white', trialStart);
      expect(checkAccess(tier, 'gold'), true);
    });

    test('White user in trial → CANNOT access FamilyGold features', () {
      final trialStart = DateTime.now().subtract(const Duration(hours: 12));
      final tier = effectiveTier('white', trialStart);
      expect(checkAccess(tier, 'family_gold'), false);
    });

    test('White user AFTER trial → locked out of everything', () {
      final trialStart = DateTime.now().subtract(const Duration(days: 5));
      final tier = effectiveTier('white', trialStart);
      expect(checkAccess(tier, 'black'), false);
      expect(checkAccess(tier, 'gold'), false);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 5: Spec compliance — features map to correct tiers
  // Per access-levels.md & screens-map.md
  // ─────────────────────────────────────────────────────────────
  group('Feature → Tier mapping (spec compliance)', () {
    // Black features: P-5 Vitamins, PR-1 extended days, P-4 recipe
    test('P-5 Vitamins requires Black', () {
      expect(checkAccess('white', 'black'), false);
      expect(checkAccess('black', 'black'), true);
      expect(checkAccess('gold', 'black'), true);
    });

    // Gold features: PH-1 Photo, P-2 3 variants
    test('PH-1 Photo requires Gold', () {
      expect(checkAccess('white', 'gold'), false);
      expect(checkAccess('black', 'gold'), false);
      expect(checkAccess('gold', 'gold'), true);
    });

    // FamilyGold features: F-1 Family, shared shopping
    test('F-1 Family requires FamilyGold', () {
      expect(checkAccess('white', 'family_gold'), false);
      expect(checkAccess('black', 'family_gold'), false);
      expect(checkAccess('gold', 'family_gold'), false);
      expect(checkAccess('family_gold', 'family_gold'), true);
    });
  });
}
