// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'13f720e453e49a400b44ee54d3ead375e956254e';

/// See also [profile].
@ProviderFor(profile)
final profileProvider = AutoDisposeProvider<UserProfile>.internal(
  profile,
  name: r'profileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRef = AutoDisposeProviderRef<UserProfile>;
String _$isOnboardedHash() => r'40e956fbaf4e040814242075137e0fee05191dc7';

/// See also [isOnboarded].
@ProviderFor(isOnboarded)
final isOnboardedProvider = AutoDisposeProvider<bool>.internal(
  isOnboarded,
  name: r'isOnboardedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isOnboardedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnboardedRef = AutoDisposeProviderRef<bool>;
String _$profileNotifierHash() => r'cba8b96a5e34b7cebf938a972db14fbfc5281b14';

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
final profileNotifierProvider =
    AutoDisposeNotifierProvider<ProfileNotifier, UserProfile>.internal(
  ProfileNotifier.new,
  name: r'profileNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileNotifier = AutoDisposeNotifier<UserProfile>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
