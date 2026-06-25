// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/custom_snackbar.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  bool _isTeacherLogin = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutQuart);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _isTeacherLogin ? 'teacher' : 'student',
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (success && mounted) {
      context.go(AppRoutes.otp, extra: _emailCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (_, next) {
      if (next.error != null) {
        CustomSnackBar.showError(context, next.error!);
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth > 800;
          return Row(
            children: [
              if (isWeb)
                Expanded(
                  flex: 5,
                  child: _buildBrandingPanel(),
                ),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 64.0 : 24.0,
                      vertical: 24.0,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isWeb) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.go(AppRoutes.login),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildMobileHeader(),
                            const SizedBox(height: 32),
                          ],
                          _buildForm(authState, isWeb),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Join E-Kitab!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to get started',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                      )
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 64),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ای کتاب',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.8,
                  ),
                ),
                const Text(
                  'E-Kitab',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Empowering Education Digitally.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState authState, bool isWeb) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWeb) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.login),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Login'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Join E-Kitab 🚀',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your account to get started',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 40),
          ],
          // Role Toggle
          Container(
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTeacherLogin = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: !_isTeacherLogin ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !_isTeacherLogin
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: !_isTeacherLogin ? FontWeight.bold : FontWeight.w500,
                          color: !_isTeacherLogin ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTeacherLogin = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _isTeacherLogin ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isTeacherLogin
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Teacher',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: _isTeacherLogin ? FontWeight.bold : FontWeight.w500,
                          color: _isTeacherLogin ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'Muhammad Ali',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Name is required';
              if (v.length < 2) return 'Name too short';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'your@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email required';
              if (!RegExp(r'^[\w.]+@[\w.]+\.\w+$').hasMatch(v)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'At least 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password required';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _phoneCtrl,
            label: 'Phone (Optional)',
            hint: '03XX-XXXXXXX',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
              GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Simple background pattern for branding panel
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble() + 100), paint);
      canvas.drawLine(Offset(size.width, i.toDouble()), Offset(0, i.toDouble() + 100), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
