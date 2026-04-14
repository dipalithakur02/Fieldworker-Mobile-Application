import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/field_steward_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().login(
            _identifierController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (!mounted) {
        return;
      }
      Helpers.showSnackBar(context, 'Login failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FieldStewardColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: FieldStewardColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'FieldSteward',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: FieldStewardColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Empowering Agriculture Through Insight',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FieldStewardColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),
                  FieldStewardSurfaceCard(
                    color: FieldStewardColors.surfaceLow,
                    padding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        Container(
                          height: 192,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                FieldStewardColors.secondaryContainer,
                                FieldStewardColors.primary
                                    .withValues(alpha: 0.35),
                                FieldStewardColors.primaryDark,
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    color: FieldStewardColors.primaryDark,
                                    size: 30,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Fieldworker Access',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        FieldStewardTextField(
                          controller: _identifierController,
                          label: 'Email Address',
                          hintText: 'steward@field.com',
                          icon: Icons.mail_outline_rounded,
                          validator: (value) => Validators.validateRequired(
                              value, 'Email or Mobile'),
                        ),
                        const SizedBox(height: 18),
                        FieldStewardTextField(
                          controller: _passwordController,
                          label: 'Secure Password',
                          hintText: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          validator: Validators.validatePassword,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/forgot-password',
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: FieldStewardColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FieldStewardPrimaryButton(
                          onPressed: _isLoading ? null : _login,
                          icon: Icons.arrow_forward_rounded,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'New to the steward program?',
                    style: TextStyle(
                      fontSize: 12,
                      color: FieldStewardColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: FieldStewardColors.surfaceLow,
                      foregroundColor: FieldStewardColors.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Contact Coordinator',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'STEWARD',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: FieldStewardColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
