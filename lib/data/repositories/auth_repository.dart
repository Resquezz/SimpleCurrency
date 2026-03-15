import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/app_settings.dart';
import '../../firebase_runtime.dart';

abstract class AuthRepository {
  Stream<AuthenticatedUser?> authStateChanges();

  AuthenticatedUser? get currentUser;

  Future<AuthenticatedUser?> restoreSession();

  Future<AuthenticatedUser> signIn({required String email, required String password});

  Future<AuthenticatedUser> register({required String email, required String password});

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._services);

  final FirebaseAppServices _services;

  FirebaseAuth get _auth {
    final auth = _services.auth;
    if (auth == null) {
      throw StateError('Firebase Auth is not initialized.');
    }
    return auth;
  }

  @override
  AuthenticatedUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return null;
    }
    return AuthenticatedUser(id: user.uid, email: user.email!);
  }

  @override
  Stream<AuthenticatedUser?> authStateChanges() {
    final auth = _services.auth;
    if (auth == null) {
      return const Stream<AuthenticatedUser?>.empty();
    }
    return auth.idTokenChanges().asyncMap(_validateUserSession);
  }

  @override
  Future<AuthenticatedUser?> restoreSession() async {
    return _validateUserSession(_auth.currentUser);
  }

  @override
  Future<AuthenticatedUser> register({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return _mapUser(credential.user)!;
  }

  @override
  Future<AuthenticatedUser> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _mapUser(credential.user)!;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AuthenticatedUser?> _validateUserSession(User? user) async {
    if (user == null || user.email == null) {
      return null;
    }

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null || refreshedUser.email == null) {
        return null;
      }
      return _mapUser(refreshedUser);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found' || error.code == 'invalid-user-token' || error.code == 'user-token-expired') {
        await _auth.signOut();
        return null;
      }
      rethrow;
    }
  }

  AuthenticatedUser? _mapUser(User? user) {
    if (user == null || user.email == null) {
      return null;
    }
    return AuthenticatedUser(id: user.uid, email: user.email!);
  }
}