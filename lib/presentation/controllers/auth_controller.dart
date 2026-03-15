import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/auth_repository.dart';

enum AuthFormMode { signIn, register }

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  AuthFormMode mode = AuthFormMode.register;
  bool isSubmitting = false;
  String? errorMessage;

  void setMode(AuthFormMode nextMode) {
    if (mode == nextMode) {
      return;
    }
    mode = nextMode;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      errorMessage = 'Заповніть email і пароль.';
      notifyListeners();
      return false;
    }
    if (mode == AuthFormMode.register && password != confirmPassword) {
      errorMessage = 'Паролі не співпадають.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      errorMessage = 'Пароль має містити щонайменше 6 символів.';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (mode == AuthFormMode.signIn) {
        await _authRepository.signIn(email: normalizedEmail, password: password);
      } else {
        await _authRepository.register(email: normalizedEmail, password: password);
      }
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = _mapFirebaseError(error.code);
      return false;
    } catch (_) {
      errorMessage = 'Не вдалося виконати авторизацію.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _mapFirebaseError(String code) {
    return switch (code) {
      'email-already-in-use' => 'Такий email уже зареєстрований.',
      'invalid-email' => 'Невірний формат email.',
      'weak-password' => 'Надто слабкий пароль.',
      'user-not-found' => 'Користувача не знайдено.',
      'wrong-password' || 'invalid-credential' => 'Невірний email або пароль.',
      'too-many-requests' => 'Забагато спроб. Спробуйте пізніше.',
      _ => 'Сталася помилка Firebase Auth: $code',
    };
  }
}