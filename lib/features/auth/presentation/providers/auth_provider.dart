import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// User state provider
final userStateProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(currentUserProvider);
});

// Is signed in provider
final isSignedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Is anonymous provider
final isAnonymousProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.isAnonymous ?? true,
    loading: () => true,
    error: (_, __) => true,
  );
});

// Current user ID provider
final currentUserIdProvider = Provider<String>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.uid ?? 'anonymous',
    loading: () => 'anonymous',
    error: (_, __) => 'anonymous',
  );
});

// User display name provider
final userDisplayNameProvider = Provider<String>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return 'Guest';
      if (user.isAnonymous) return 'Guest';
      return user.displayName ?? user.email?.split('@')[0] ?? 'User';
    },
    loading: () => 'Guest',
    error: (_, __) => 'Guest',
  );
});

// User email provider
final userEmailProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.email,
    loading: () => null,
    error: (_, __) => null,
  );
});

// User photo URL provider
final userPhotoUrlProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.photoURL,
    loading: () => null,
    error: (_, __) => null,
  );
});
