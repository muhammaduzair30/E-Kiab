// lib/features/auth/presentation/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      emoji: '📚',
      title: 'Digital Textbooks',
      titleUrdu: 'ڈیجیٹل کتابیں',
      description: 'Access all Pakistani curriculum textbooks — Punjab, Sindh, KPK and FBISE boards — anytime, anywhere.',
      color: AppColors.primary,
      bgColor: AppColors.primaryContainer,
    ),
    _OnboardingPage(
      emoji: '🤖',
      title: 'AI Learning Tutor',
      titleUrdu: 'ذہین سیکھنے کا نظام',
      description: 'Ask questions in Urdu or English. Get instant explanations, chapter summaries and homework help.',
      color: AppColors.secondary,
      bgColor: AppColors.secondaryContainer,
    ),
    _OnboardingPage(
      emoji: '📊',
      title: 'Track Your Progress',
      titleUrdu: 'اپنی ترقی دیکھیں',
      description: 'Attempt quizzes, earn badges, compete on leaderboards, and track your learning journey.',
      color: AppColors.accent,
      bgColor: Color(0xFFFFF8E1),
    ),
    _OnboardingPage(
      emoji: '📶',
      title: 'Learn Offline Too',
      titleUrdu: 'آف لائن بھی پڑھیں',
      description: 'Download books and lessons. Study even without internet — perfect for rural students.',
      color: AppColors.info,
      bgColor: Color(0xFFE1F5FE),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(authStateProvider.notifier).setOnboarded();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _pages[i],
                ),
              ),
              // Bottom controls
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: _pages[_currentPage].color,
                          dotColor: _pages[_currentPage].color.withValues(alpha: 0.3),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          // Skip
                          if (!isLast)
                            TextButton(
                              onPressed: _finish,
                              child: Text(
                                'Skip',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ),
                          const Spacer(),
                          // Next / Get Started
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: ElevatedButton(
                              onPressed: _next,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pages[_currentPage].color,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLast ? 32 : 24,
                                  vertical: 14,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(isLast ? 'Get Started' : 'Next'),
                                  const SizedBox(width: 8),
                                  Icon(isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Skip to login shortcut at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text('Sign In', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String titleUrdu;
  final String description;
  final Color color;
  final Color bgColor;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.titleUrdu,
    required this.description,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration area
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 90)),
                ),
              ),
              const SizedBox(height: 48),
              // Urdu title
              Text(
                titleUrdu,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              // English title
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
