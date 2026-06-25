import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TaskRepository(this._firestore, this._auth);

  Future<void> createTask(Map<String, dynamic> taskData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to create a task');

    taskData['teacherId'] = user.uid;
    taskData['createdAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('tasks').add(taskData);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final querySnapshot = await _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTasksByTeacher() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore
        .collection('tasks')
        .where('teacherId', isEqualTo: user.uid)
        .get();

    final docs = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    docs.sort((a, b) {
      final t1 = a['createdAt'] as Timestamp?;
      final t2 = b['createdAt'] as Timestamp?;
      if (t1 == null || t2 == null) return 0;
      return t2.compareTo(t1);
    });

    return docs;
  }

  Future<void> submitTask(String taskId, String fileUrl, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to submit a task');

    await _firestore.collection('tasks').doc(taskId).update({
      'completedBy': FieldValue.arrayUnion([user.uid]),
      'submissions.${user.uid}': {
        'fileUrl': fileUrl,
        'fileName': fileName,
        'submittedAt': FieldValue.serverTimestamp(),
      }
    });
  }

  Future<void> markTaskComplete(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to complete a task');

    await _firestore.collection('tasks').doc(taskId).update({
      'completedBy': FieldValue.arrayUnion([user.uid])
    });
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> rateStudentTask(String taskId, String studentId, int rating, String feedback) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to rate a task');

    await _firestore.collection('tasks').doc(taskId).update({
      'ratings.$studentId': {
        'rating': rating,
        'feedback': feedback,
        'ratedAt': FieldValue.serverTimestamp(),
      }
    });
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});
