import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherAnalyticsRepository {
  final FirebaseFirestore _firestore;

  TeacherAnalyticsRepository(this._firestore);

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      // Get total students
      final studentsSnap = await _firestore.collection('users').where('role', isEqualTo: 'student').count().get();
      final totalStudents = studentsSnap.count ?? 0;

      // Get total quizzes
      final quizzesSnap = await _firestore.collection('quizzes').count().get();
      final totalQuizzes = quizzesSnap.count ?? 0;

      // Get total tasks
      final tasksSnap = await _firestore.collection('tasks').count().get();
      final totalTasks = tasksSnap.count ?? 0;

      // Get average score from attempts
      final attemptsSnap = await _firestore.collection('quiz_attempts').get();
      double totalPercentage = 0;
      int attemptCount = 0;

      for (var doc in attemptsSnap.docs) {
        final data = doc.data();
        final score = data['score'] as int? ?? 0;
        final totalQuestions = data['totalQuestions'] as int? ?? 1;
        totalPercentage += (score / totalQuestions);
        attemptCount++;
      }

      final averageScore = attemptCount > 0 ? (totalPercentage / attemptCount) * 100 : 0.0;

      // Get recent activity (last 5 attempts)
      final recentSnap = await _firestore.collection('quiz_attempts')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      final recentActivity = await Future.wait(recentSnap.docs.map((doc) async {
        final data = doc.data();
        data['id'] = doc.id;
        final userId = data['userId'] as String?;
        if (userId != null) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              data['studentName'] = userDoc.data()?['name'] ?? 'Unknown Student';
            } else {
              data['studentName'] = 'Unknown Student';
            }
          } catch (_) {
            data['studentName'] = 'Unknown Student';
          }
        } else {
          data['studentName'] = 'Anonymous';
        }
        return data;
      }));

      return {
        'totalStudents': totalStudents,
        'totalQuizzes': totalQuizzes,
        'totalTasks': totalTasks,
        'averageScore': averageScore,
        'recentActivity': recentActivity,
      };
    } catch (e) {
      throw Exception('Failed to load metrics: $e');
    }
  }
}

final teacherAnalyticsRepositoryProvider = Provider<TeacherAnalyticsRepository>((ref) {
  return TeacherAnalyticsRepository(FirebaseFirestore.instance);
});
