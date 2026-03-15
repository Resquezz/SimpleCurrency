import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isRegister = widget.controller.mode == AuthFormMode.register;
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7FAFF), Color(0xFFE8F0FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SimpleCurrency', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 20),
                          SegmentedButton<AuthFormMode>(
                            segments: const [
                              ButtonSegment(value: AuthFormMode.register, label: Text('Реєстрація')),
                              ButtonSegment(value: AuthFormMode.signIn, label: Text('Вхід')),
                            ],
                            selected: {widget.controller.mode},
                            onSelectionChanged: (selection) => widget.controller.setMode(selection.first),
                            showSelectedIcon: false,
                          ),
                          const SizedBox(height: 18),
                          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                          const SizedBox(height: 12),
                          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
                          if (isRegister) ...[
                            const SizedBox(height: 12),
                            TextField(controller: _confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Підтвердження пароля')),
                          ],
                          if (widget.controller.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Text(widget.controller.errorMessage!, style: const TextStyle(color: dangerColor, fontWeight: FontWeight.w700)),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: inkColor),
                              onPressed: widget.controller.isSubmitting
                                  ? null
                                  : () async {
                                      await widget.controller.submit(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        confirmPassword: _confirmController.text,
                                      );
                                    },
                              child: widget.controller.isSubmitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(isRegister ? 'Зареєструватися' : 'Увійти', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}