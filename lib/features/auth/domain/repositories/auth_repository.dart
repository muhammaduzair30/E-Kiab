// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    String? role,
  });

  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  });

  Future<Either<Failure, User>> googleSignIn({String? role});

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> forgotPassword(String email);

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, void>> resendOtp(String email);

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  });

  Future<Either<Failure, User>> updateStudentProfile({
    required String gradeId,
    required String boardId,
  });

  Future<bool> isAuthenticated();

  Stream<User?> get authStateChanges;
}
