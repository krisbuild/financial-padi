import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The signed-in Firebase [User], or null. Convenience wrapper around
/// [authStateProvider] for widgets that only need a synchronous read.
final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// The current user's app-level profile document. Re-fetches whenever the
/// auth state changes.
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;
  return ref.watch(authServiceProvider).fetchAppUser(user.uid);
});
