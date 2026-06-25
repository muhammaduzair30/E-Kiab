// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // Collections
  CollectionReference<Map<String, dynamic>> get usersCol => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get booksCol => _firestore.collection('books');
  CollectionReference<Map<String, dynamic>> get quizzesCol => _firestore.collection('quizzes');

  // Helper method to add the document ID to the document data
  Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['_id'] = doc.id;
    return data;
  }

  // Generic list query
  Future<List<Map<String, dynamic>>> getCollection({
    required CollectionReference<Map<String, dynamic>> collection,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = collection;

    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_withId).toList();
  }

  // Generic get document
  Future<Map<String, dynamic>?> getDocument(DocumentReference<Map<String, dynamic>> docRef) async {
    final doc = await docRef.get();
    if (!doc.exists) return null;
    return _withId(doc);
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firestoreProvider));
});
