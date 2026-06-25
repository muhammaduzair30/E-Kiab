// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/failures.dart';
import '../../../../main.dart' show firebaseInitialized;
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password, String? role});
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  });
  Future<UserModel> googleSignIn({String? role});
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({required String token, required String newPassword});
  Future<void> verifyOtp({required String email, required String otp});
  Future<void> resendOtp(String email);
  Future<UserModel> getCurrentUser();
  Future<bool> isAuthenticated();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  // ─── Login ──────────────────────────────────────────────────────────────────

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      debugPrint('AuthRemoteDataSourceImpl: Calling signInWithEmailAndPassword...');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'Login failed. No user returned.');
      }

      debugPrint('AuthRemoteDataSourceImpl: checking if user document exists...');
      final doc = await _usersCol.doc(user.uid).get();
      if (!doc.exists) {
        debugPrint('AuthRemoteDataSourceImpl: document missing, creating one...');
        final now = FieldValue.serverTimestamp();
        await _usersCol.doc(user.uid).set({
          'name': user.displayName ?? 'Student',
          'email': user.email ?? email,
          'role': role ?? 'student',
          'phone': user.phoneNumber,
          'profileImage': user.photoURL,
          'isVerified': user.emailVerified,
          'isActive': true,
          'createdAt': now,
          'lastLoginAt': now,
          'studentProfile': {
            'gradeId': null,
            'gradeName': null,
            'boardId': null,
            'boardName': null,
            'readingStreak': 0,
            'totalPoints': 0,
            'badges': <String>[],
            'booksRead': 0,
            'quizzesAttempted': 0,
          },
        });
      } else {
        final data = doc.data()!;
        final existingRole = data['role'] as String?;
        if (role != null && existingRole != null && role != existingRole) {
          await _firebaseAuth.signOut();
          throw AuthException(
            message: 'Invalid role for this account. Please select the correct role ($existingRole).',
          );
        }
        debugPrint('AuthRemoteDataSourceImpl: updating lastLoginAt in Firestore...');
        final updateData = <String, dynamic>{
          'lastLoginAt': FieldValue.serverTimestamp(),
        };
        await _usersCol.doc(user.uid).update(updateData);
      }

      debugPrint('AuthRemoteDataSourceImpl: calling _getUserFromFirestore...');
      return await _getUserFromFirestore(user.uid);
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('AuthRemoteDataSourceImpl: FirebaseAuthException: ${e.code}');
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('AuthRemoteDataSourceImpl: Exception: $e');
      throw AuthException(message: 'Login error: $e');
    }
  }

  // ─── Register ───────────────────────────────────────────────────────────────

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'Registration failed.');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create user document in Firestore
      final now = FieldValue.serverTimestamp();
      final userData = <String, dynamic>{
        'name': name,
        'email': email,
        'role': role, // Fix: Use the provided role
        'phone': phone,
        'profileImage': user.photoURL,
        'isVerified': user.emailVerified,
        'isActive': true,
        'createdAt': now,
        'lastLoginAt': now,
        'studentProfile': {
          'gradeId': null,
          'gradeName': null,
          'boardId': null,
          'boardName': null,
          'readingStreak': 0,
          'totalPoints': 0,
          'badges': <String>[],
          'booksRead': 0,
          'quizzesAttempted': 0,
        },
      };

      await _usersCol.doc(user.uid).set(userData);

      // Send email verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      return await _getUserFromFirestore(user.uid);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  // ─── Google Sign-In ─────────────────────────────────────────────────────────

  @override
  Future<UserModel> googleSignIn({String? role}) async {
    if (!firebaseInitialized) {
      throw const AuthException(
        message: 'Google Sign-In is not available (Firebase not configured). '
            'Please use email/password login.',
      );
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(message: 'Google sign-in cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(message: 'Google sign-in failed.');
      }

      // Check if user doc exists; if not, create one
      final doc = await _usersCol.doc(user.uid).get();
      if (!doc.exists) {
        final now = FieldValue.serverTimestamp();
        await _usersCol.doc(user.uid).set({
          'name': user.displayName ?? 'Student',
          'email': user.email ?? '',
          'role': role ?? 'student',
          'phone': user.phoneNumber,
          'profileImage': user.photoURL,
          'isVerified': true,
          'isActive': true,
          'createdAt': now,
          'lastLoginAt': now,
          'studentProfile': {
            'gradeId': null,
            'gradeName': null,
            'boardId': null,
            'boardName': null,
            'readingStreak': 0,
            'totalPoints': 0,
            'badges': <String>[],
            'booksRead': 0,
            'quizzesAttempted': 0,
          },
        });
      } else {
        final data = doc.data()!;
        final existingRole = data['role'] as String?;
        if (role != null && existingRole != null && role != existingRole) {
          await _firebaseAuth.signOut();
          try {
            await _googleSignIn.signOut();
          } catch (_) {}
          throw AuthException(
            message: 'Invalid role for this account. Please select the correct role ($existingRole).',
          );
        }
        
        final updateData = <String, dynamic>{
          'lastLoginAt': FieldValue.serverTimestamp(),
        };
        await _usersCol.doc(user.uid).update(updateData);
      }

      return await _getUserFromFirestore(user.uid);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  // ─── Forgot Password ───────────────────────────────────────────────────────

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  // ─── Reset Password (not used with Firebase — handled via email link) ─────

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    // Firebase handles password reset via email link, not token.
    // This is kept for interface compatibility.
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: token,
        newPassword: newPassword,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  // ─── Verify OTP / Email ────────────────────────────────────────────────────

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    // Firebase uses email verification links, not OTP codes.
    // Re-check verification status.
    await _firebaseAuth.currentUser?.reload();
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      throw const AuthException(
        message: 'Email not verified yet. Please check your inbox.',
      );
    }
  }

  @override
  Future<void> resendOtp(String email) async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ─── Get Current User ──────────────────────────────────────────────────────

  @override
  Future<UserModel> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'Not authenticated.');
    }
    return await _getUserFromFirestore(user.uid);
  }

  // ─── Is Authenticated ─────────────────────────────────────────────────────

  @override
  Future<bool> isAuthenticated() async {
    final user = await _firebaseAuth.authStateChanges().first;
    return user != null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Reads user doc from Firestore and converts to UserModel.
  Future<UserModel> _getUserFromFirestore(String uid) async {
    debugPrint('AuthRemoteDataSourceImpl: getting document $uid from Firestore...');
    final doc = await _usersCol.doc(uid).get();
    debugPrint('AuthRemoteDataSourceImpl: got document. exists: ${doc.exists}');
    
    if (!doc.exists) {
      throw const AuthException(message: 'User profile not found in database.');
    }
    final data = doc.data()!;
    // Inject the document ID as '_id'
    data['_id'] = uid;
    // Convert Firestore Timestamps to ISO strings for the model
    data['createdAt'] = _timestampToString(data['createdAt']);
    data['lastLoginAt'] = _timestampToString(data['lastLoginAt']);
    return UserModel.fromJson(data);
  }

  String? _timestampToString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return DateTime.now().toIso8601String();
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: $code';
    }
  }
}
