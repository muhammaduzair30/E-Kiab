import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/teacher_analytics_repository.dart';

final teacherAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(teacherAnalyticsRepositoryProvider);
  return repo.getDashboardMetrics();
});
