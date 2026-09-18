import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// A [FirestoreService] scoped to the currently signed-in user.
/// Throws if accessed while signed out — callers should always be behind
/// the auth guard in the router, so this should never happen in practice.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    throw StateError('FirestoreService accessed without a signed-in user');
  }
  return FirestoreService(user.uid);
});
