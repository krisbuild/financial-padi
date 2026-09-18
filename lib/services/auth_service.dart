import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/category_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName.trim());

    final appUser = AppUser(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(user.uid), appUser.toMap());
    for (final category in CategoryModel.defaultCategories()) {
      batch.set(
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .doc(category.id),
        category.toMap(),
      );
    }
    await batch.commit();

    return appUser;
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return fetchAppUser(credential.user!.uid);
  }

  Future<AppUser> fetchAppUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      final user = _auth.currentUser!;
      final appUser = AppUser(
        uid: uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(appUser.toMap());
      return appUser;
    }
    return AppUser.fromSnapshot(doc);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'weak-password':
          return 'Please choose a stronger password (6+ characters).';
        case 'requires-recent-login':
          return 'Please sign in again to continue.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
