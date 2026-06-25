import 'package:ekitab/core/theme/app_theme.dart';
import 'package:ekitab/core/theme/theme_provider.dart';
import 'package:ekitab/features/auth/domain/entities/user.dart';
import 'package:ekitab/features/auth/presentation/providers/auth_provider.dart';
import 'package:ekitab/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/student_quiz_history_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatsRow(profile: user.studentProfile),
                const SizedBox(height: 20),
                const _ActivitySection(),
                const SizedBox(height: 20),
                _SettingsSection(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit Profile coming soon!')),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF1E40AF)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                            fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('${user.studentProfile?.gradeName ?? 'Grade'} • ${user.studentProfile?.boardName ?? 'Board'}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final StudentProfile? profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${profile?.readingStreak ?? 0}🔥',
          label: 'Day Streak',
          color: const Color(0xFFF97316),
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${profile?.totalPoints ?? 0}',
          label: 'Points',
          color: const Color(0xFF3B82F6), // Brighter blue
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${profile?.quizzesAttempted ?? 0}',
          label: 'Quizzes',
          color: const Color(0xFF10B981), // Brighter green
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: theme.brightness == Brightness.light ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─── Activity ─────────────────────────────────────────────────────────────────

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(studentQuizHistoryProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Recent Quizzes'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 60, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                itemBuilder: (context, i) {
                  final item = history[i];
                  final timestamp = item['timestamp'] as Timestamp?;
                  final timeStr = timestamp != null
                      ? _formatTimeAgo(timestamp.toDate())
                      : '';

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.quiz_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    title: Text(item['quizTitle'] as String? ?? 'Quiz',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    subtitle: Text(
                        'Score: ${item['score']}/${item['totalQuestions']}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    trailing: Text(timeStr,
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Error loading activity',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Settings ─────────────────────────────────────────────────────────────────

class _SettingsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    
    String themeLabel = 'System';
    if (themeMode == ThemeMode.light) themeLabel = 'Light';
    if (themeMode == ThemeMode.dark) themeLabel = 'Dark';
    
    final items = [
      {'icon': Icons.person_outline_rounded, 'label': 'Edit Profile', 'value': null, 'color': isDark ? const Color(0xFF60A5FA) : AppColors.primary},
      {'icon': Icons.menu_book_rounded, 'label': 'My Books', 'value': null, 'color': isDark ? const Color(0xFF34D399) : AppColors.secondary},
      {'icon': isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 'label': 'Appearance', 'value': themeLabel, 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'value': null, 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.logout_rounded, 'label': 'Sign Out', 'value': null, 'color': isDark ? const Color(0xFFF87171) : AppColors.error},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Settings'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item['icon'] as IconData,
                      color: item['color'] as Color, size: 18),
                ),
                title: Text(item['label'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: item['label'] == 'Sign Out'
                            ? (isDark ? const Color(0xFFF87171) : AppColors.error)
                            : theme.colorScheme.onSurface)),
                trailing: item['value'] != null
                    ? Text(item['value'] as String,
                        style: TextStyle(
                            fontSize: 13, color: theme.colorScheme.onSurfaceVariant))
                    : Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                onTap: () {
                  if (item['label'] == 'Sign Out') {
                    _showSignOutDialog(context, ref);
                  } else if (item['label'] == 'Appearance') {
                    _showThemeDialog(context, ref, themeMode);
                  } else if (item['label'] == 'My Books') {
                    context.go(AppRoutes.bookList);
                  } else if (item['label'] == 'Edit Profile' || item['label'] == 'Help & Support') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['label']} coming soon!')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You\'ll need to log in again to access your account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
              );
              
              await ref.read(authStateProvider.notifier).logout();
              
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // Close loading overlay safely
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Theme'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (mode) {
                ref.read(themeProvider.notifier).setTheme(mode!);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (mode) {
                ref.read(themeProvider.notifier).setTheme(mode!);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (mode) {
                ref.read(themeProvider.notifier).setTheme(mode!);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}

