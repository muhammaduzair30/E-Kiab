import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/teacher_analytics_provider.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final analyticsAsync = ref.watch(teacherAnalyticsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: analyticsAsync.when(
        data: (metrics) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Header Section
                  Container(
                    decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                'Welcome back, ${user?.displayName != null && user!.displayName!.isNotEmpty ? user.displayName!.split(' ').first : 'Teacher'}! 👋',
                                style: const TextStyle(
                                  fontSize: 26, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Here is what\'s happening with your classes today.',
                                style: TextStyle(
                                  fontSize: 15, 
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final themeMode = ref.watch(themeProvider);
                              final isDark = themeMode == ThemeMode.dark || 
                                  (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
                              return IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide.none,
                                ),
                                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
                                onPressed: () {
                                  ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide.none,
                            ),
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                            onPressed: () => ref.refresh(teacherAnalyticsProvider),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide.none,
                            ),
                            icon: const Icon(Icons.logout_rounded, color: Colors.white),
                            onPressed: () => ref.read(authStateProvider.notifier).logout(),
                          ),
                        ],
                      ),
                    ],
                  ),),
                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Analytics Overview', 
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Metrics Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return GridView.count(
                        crossAxisCount: isDesktop ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: isDesktop ? 1.2 : 0.9,
                        children: [
                          _MetricCard(
                            title: 'Total Students',
                            value: '${metrics['totalStudents']}',
                            icon: Icons.people_alt_rounded,
                            color: AppColors.primary,
                          ),
                          _MetricCard(
                            title: 'Avg. Score',
                            value: '${(metrics['averageScore'] as double).toStringAsFixed(1)}%',
                            icon: Icons.auto_graph_rounded,
                            color: AppColors.success,
                          ),
                          _MetricCard(
                            title: 'Total Quizzes',
                            value: '${metrics['totalQuizzes']}',
                            icon: Icons.quiz_rounded,
                            color: AppColors.secondary,
                          ),
                          _MetricCard(
                            title: 'Assignments',
                            value: '${metrics['totalTasks']}',
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    'Quick Actions', 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return GridView.count(
                        crossAxisCount: isDesktop ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.4 : 1.1,
                        children: [
                          _ActionCard(
                            title: 'Assign Material',
                            icon: Icons.assignment_rounded,
                            color: AppColors.primary,
                            onTap: () => context.go(AppRoutes.teacherTasks),
                          ),
                          _ActionCard(
                            title: 'Library',
                            icon: Icons.menu_book_rounded,
                            color: AppColors.secondary,
                            onTap: () => context.go(AppRoutes.teacherBooks),
                          ),
                          _ActionCard(
                            title: 'Class Notes',
                            icon: Icons.note_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => context.go(AppRoutes.teacherNotes),
                          ),
                          _ActionCard(
                            title: 'AI Quiz',
                            icon: Icons.auto_awesome_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => context.go(AppRoutes.teacherAiQuizGenerator),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 40),

                  Text(
                    'Recent Activity', 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecentActivity(context, metrics['recentActivity'] as List<dynamic>),
                ],
              ),
            ),
              ]) ,
        )
      );
    
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<dynamic> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded, 
              size: 48, 
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity.', 
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant, 
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final act = activities[i];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), 
                blurRadius: 10, 
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${act['studentName'] ?? 'Student'} completed quiz', 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      act['quizTitle'] ?? 'Unknown Quiz', 
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, 
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${act['score']}/${act['totalQuestions']}', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title, 
    required this.value, 
    required this.icon, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1), 
            blurRadius: 16, 
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.trending_up_rounded, color: AppColors.success.withValues(alpha: 0.8), size: 20),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 28, 
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title, 
    required this.icon, 
    required this.color, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const Spacer(),
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15, 
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
