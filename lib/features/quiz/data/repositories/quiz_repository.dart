import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuizRepository(this._firestore, this._auth);

  // Quizzes Collection
  Future<String> saveQuiz(Map<String, dynamic> quizData) async {
    final user = _auth.currentUser;
    // We'll allow saving if no user exists, but it won't have a createdBy
    if (user != null) {
      quizData['createdBy'] = user.uid;
    }
    quizData['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('quizzes').add(quizData);
    return docRef.id;
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    final querySnapshot = await _firestore
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .limit(20) // Load last 20 by default
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['_id'] = doc.id;
      return data;
    }).toList();
  }

  // Quiz Attempts Collection
  Future<void> saveQuizAttempt(String quizId, String quizTitle, int score, int totalQuestions, Map<int, int> selectedAnswers) async {
    final user = _auth.currentUser;
    if (user == null) return; // Silent return if anonymous user takes quiz

    await _firestore.collection('quiz_attempts').add({
      'userId': user.uid,
      'quizId': quizId,
      'quizTitle': quizTitle, // Keep title denormalized for easy history rendering
      'score': score,
      'totalQuestions': totalQuestions,
      'selectedAnswers': selectedAnswers.map((key, value) => MapEntry(key.toString(), value)), // Firestore keys must be strings
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserQuizHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore
        .collection('quiz_attempts')
        .where('userId', isEqualTo: user.uid)
        .get();

    final docs = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // Sort locally to avoid needing a composite index in Firestore
    docs.sort((a, b) {
      final t1 = a['timestamp'] as Timestamp?;
      final t2 = b['timestamp'] as Timestamp?;
      if (t1 == null || t2 == null) return 0;
      return t2.compareTo(t1); // descending
    });

    return docs;
  }

  Future<List<Map<String, dynamic>>> getGlobalQuizAttempts() async {
    final querySnapshot = await _firestore
        .collection('quiz_attempts')
        .orderBy('timestamp', descending: true)
        .limit(100) // limit for MVP
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});
