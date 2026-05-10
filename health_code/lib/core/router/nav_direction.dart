// lib/core/router/nav_direction.dart
// Global navigation direction state for slide animations.
// Set before calling context.go() — router reads it to pick transition direction.

enum NavDirection { forward, back }

/// Global mutable direction. Set to [NavDirection.back] before context.go()
/// in onBack handlers. Defaults to [NavDirection.forward].
NavDirection currentNavDirection = NavDirection.forward;
