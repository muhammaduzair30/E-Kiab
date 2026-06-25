import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NoteRepository(this._firestore, this._auth);

  Future<void> createNote(Map<String, dynamic> noteData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to upload a note');

    noteData['teacherId'] = user.uid;
    noteData['createdAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('notes').add(noteData);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final querySnapshot = await _firestore
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getNotesByTeacher() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore
        .collection('notes')
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
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});
