import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    if (success) {
      context.go('/app/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.screenPaddingHorizontal,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxFormWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          const Center(child: AppLogo()),
                          const SizedBox(height: 32),
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Log in to manage your business permits.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.mail_outline),
                            validator: Validators.email,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) => Validators.required(
                              value,
                              fieldLabel: 'Password',
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) => setState(
                                          () => _rememberMe = value ?? false,
                                        ),
                                      ),
                                      const Flexible(
                                        child: Text(
                                          'Remember me',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: 'Log In',
                            isLoading: authProvider.isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/register'),
                                child: const Text(
                                  'Create account',
                                  style: TextStyle(
                                    color: AppColors.secondaryBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusMedium,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Prototype access — use ${AppStrings.mockEmail} / ${AppStrings.mockPassword} to explore the app.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
