// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0)),
    );
    _ctrl.forward();

    // Check current auth state after the first frame — handles the case
    // where AuthNotifier._init() already completed before this listener
    // was registered (ref.listen only fires on *changes*, not current state).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      if (!authState.isLoading) {
        _navigate(authState);
      }
    });

    // Safety timeout: if auth state is still loading after 5 seconds,
    // navigate to login so the user is never stuck.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_navigated) {
        context.go(AppRoutes.login);
      }
    });
  }

  void _navigate(AuthState authState) {
    if (_navigated || !mounted) return;
    _navigated = true;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (!authState.isOnboarded) {
        context.go(AppRoutes.onboarding);
      } else if (authState.isAuthenticated) {
        context.go(authState.user?.isTeacher == true ? AppRoutes.teacherHome : AppRoutes.studentHome);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to navigate
    ref.listen(authStateProvider, (prev, next) {
      if (!next.isLoading) {
        _navigate(next);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      const Text(
                        'ای کتاب',
                        style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.8,
                        ),
                      ),
                      const Text(
                        'E-KITAB',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learn Smart. Learn Digital.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                FadeTransition(
                  opacity: _fade,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

