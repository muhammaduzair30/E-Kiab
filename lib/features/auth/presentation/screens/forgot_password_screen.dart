import 'package:ekitab/core/theme/app_theme.dart';
import 'package:ekitab/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:ekitab/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _ForgotStep { email, otp, newPassword, success }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.email;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    // TODO: call authRepository.forgotPassword(email)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _step = _ForgotStep.otp;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    // TODO: call authRepository.verifyOtp(email, otp)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _step = _ForgotStep.newPassword;
    });
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    // TODO: call authRepository.resetPassword(otp, newPassword)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _step = _ForgotStep.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step != _ForgotStep.success
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  if (_step == _ForgotStep.email) {
                    context.pop();
                  } else {
                    setState(() {
                      _errorMessage = '';
                      _step = _ForgotStep.values[_step.index - 1];
                    });
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepIndicator(currentStep: _step.index, totalSteps: 3),
              const SizedBox(height: 32),
              _buildContent(),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _errorMessage),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
      child: switch (_step) {
        _ForgotStep.email   => _EmailStep(
            key: const ValueKey('email'),
            controller: _emailController,
            isLoading: _isLoading,
            onContinue: _sendOtp,
          ),
        _ForgotStep.otp     => _OtpStep(
            key: const ValueKey('otp'),
            email: _emailController.text.trim(),
            controller: _otpController,
            isLoading: _isLoading,
            onContinue: _verifyOtp,
            onResend: _sendOtp,
          ),
        _ForgotStep.newPassword => _NewPasswordStep(
            key: const ValueKey('password'),
            passwordController: _passwordController,
            confirmController: _confirmController,
            obscurePassword: _obscurePassword,
            obscureConfirm: _obscureConfirm,
            isLoading: _isLoading,
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onContinue: _resetPassword,
          ),
        _ForgotStep.success => _SuccessStep(
            key: const ValueKey('success'),
            onGoToLogin: () => context.go(AppRoutes.login),
          ),
      },
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    if (currentStep >= totalSteps) return const SizedBox.shrink();
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Email ────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onContinue;

  const _EmailStep({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 48, color: AppColors.primary),
        const SizedBox(height: 20),
        Text('Forgot Password?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email address and we\'ll send you a verification code.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        AuthTextField(
          controller: controller,
          label: 'Email Address',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onContinue,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: OTP ──────────────────────────────────────────────────────────────

class _OtpStep extends StatefulWidget {
  final String email;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onContinue;
  final VoidCallback onResend;

  const _OtpStep({
    super.key,
    required this.email,
    required this.controller,
    required this.isLoading,
    required this.onContinue,
    required this.onResend,
  });

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = widget.email.replaceRange(
        2, widget.email.indexOf('@'), '***');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primary),
        const SizedBox(height: 20),
        Text('Check Your Email',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to $maskedEmail. Enter it below to continue.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        AuthTextField(
          controller: widget.controller,
          label: 'Verification Code',
          hint: '000000',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.pin_outlined,
          maxLength: 6,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text("Didn't receive it? ",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            _canResend
                ? GestureDetector(
                    onTap: () {
                      widget.onResend();
                      setState(() {
                        _canResend = false;
                        _resendCountdown = 60;
                      });
                      _startCountdown();
                    },
                    child: const Text('Resend',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  )
                : Text('Resend in ${_resendCountdown}s',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onContinue,
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Verify Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Step 3: New Password ─────────────────────────────────────────────────────

class _NewPasswordStep extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onContinue;

  const _NewPasswordStep({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.primary),
        const SizedBox(height: 20),
        Text('Set New Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Create a strong password that you haven\'t used before.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        AuthTextField(
          controller: passwordController,
          label: 'New Password',
          hint: 'Min. 8 characters',
          obscureText: obscurePassword,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textHint,
            ),
            onPressed: onTogglePassword,
          ),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: confirmController,
          label: 'Confirm Password',
          hint: 'Repeat your password',
          obscureText: obscureConfirm,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textHint,
            ),
            onPressed: onToggleConfirm,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onContinue,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Step 4: Success ──────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  final VoidCallback onGoToLogin;
  const _SuccessStep({super.key, required this.onGoToLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 56, color: AppColors.success),
          ),
          const SizedBox(height: 32),
          Text('Password Reset!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          Text(
            'Your password has been reset successfully. You can now log in with your new password.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onGoToLogin,
              child: const Text('Back to Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
