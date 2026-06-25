// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final fb.FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    fb.FirebaseAuth? firebaseAuth,
  })  : _remote = remote,
        _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges {
    // Map Firebase auth state changes to our domain User
    // We only emit null (logged out) here; the provider handles
    // fetching the full User object.
    return _firebaseAuth.authStateChanges().map((fbUser) => null);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final user = await _remote.login(email: email, password: password, role: role);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final user = await _remote.register(
        name: name, email: email, password: password, role: role, phone: phone,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> googleSignIn({String? role}) async {
    try {
      final user = await _remote.googleSignIn(role: role);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
      return const Right(null);
    } catch (e) {
      // Still consider logout successful locally
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(token: token, newPassword: newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _remote.verifyOtp(email: email, otp: otp);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resendOtp(String email) async {
    try {
      await _remote.resendOtp(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await _remote.getCurrentUser();
      return Right(user);
    } on AuthException catch (_) {
      return const Left(UnauthorizedFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    try {
      // TODO: Implement Firestore profile update
      final user = await _remote.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateStudentProfile({
    required String gradeId,
    required String boardId,
  }) async {
    try {
      // TODO: Implement Firestore student profile update
      final user = await _remote.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _remote.isAuthenticated();
  }
}
