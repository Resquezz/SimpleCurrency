import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/currency_repository.dart';
import '../data/repositories/preferences_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../firebase_runtime.dart';
import '../presentation/controllers/app_controller.dart';
import '../presentation/controllers/auth_controller.dart';
import '../presentation/screens/auth_screen.dart';
import '../presentation/screens/home_screen.dart';

class SimpleCurrencyApp extends StatefulWidget {
  const SimpleCurrencyApp({
    super.key,
    this.firebaseServices = const FirebaseAppServices.disabled(),
    this.authRepository,
    this.currencyRepository,
  });

  final FirebaseAppServices firebaseServices;
  final AuthRepository? authRepository;
  final CurrencyRepository? currencyRepository;

  @override
  State<SimpleCurrencyApp> createState() => _SimpleCurrencyAppState();
}

class _SimpleCurrencyAppState extends State<SimpleCurrencyApp> {
  late final AuthRepository _authRepository = widget.authRepository ?? FirebaseAuthRepository(widget.firebaseServices);
  late final AuthController _authController = AuthController(_authRepository);
  late final Future<AuthenticatedUser?> _restoredSession = _authRepository.restoreSession();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SimpleCurrency',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: FutureBuilder<AuthenticatedUser?>(
        future: _restoredSession,
        builder: (context, sessionSnapshot) {
          if (sessionSnapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return StreamBuilder<AuthenticatedUser?>(
            stream: _authRepository.authStateChanges(),
            initialData: sessionSnapshot.data,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final user = snapshot.data;
              if (user == null) {
                return AuthScreen(controller: _authController);
              }
              return _AuthenticatedArea(
                key: ValueKey(user.id),
                user: user,
                firebaseServices: widget.firebaseServices,
                currencyRepository: widget.currencyRepository ?? NbuCurrencyRepository(),
                onSignOut: _authRepository.signOut,
              );
            },
          );
        },
      ),
    );
  }
}

class _AuthenticatedArea extends StatefulWidget {
  const _AuthenticatedArea({
    super.key,
    required this.user,
    required this.firebaseServices,
    required this.currencyRepository,
    required this.onSignOut,
  });

  final AuthenticatedUser user;
  final FirebaseAppServices firebaseServices;
  final CurrencyRepository currencyRepository;
  final Future<void> Function() onSignOut;

  @override
  State<_AuthenticatedArea> createState() => _AuthenticatedAreaState();
}

class _AuthenticatedAreaState extends State<_AuthenticatedArea> {
  late final AppController _controller = AppController(
    user: widget.user,
    currencyRepository: widget.currencyRepository,
    preferencesRepository: PreferencesRepository(widget.firebaseServices),
    walletRepository: WalletRepository(widget.firebaseServices),
    analyticsRepository: AnalyticsRepository(widget.firebaseServices),
    firebaseServices: widget.firebaseServices,
  );
  late ThemeMode _themeMode = _controller.themeMode;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final nextThemeMode = _controller.themeMode;
    if (_themeMode == nextThemeMode || !mounted) {
      return;
    }
    setState(() => _themeMode = nextThemeMode);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = switch (_themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };

    return Theme(
      data: buildAppTheme(brightness),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return HomeScreen(controller: _controller, email: widget.user.email, onSignOut: widget.onSignOut);
        },
      ),
    );
  }
}