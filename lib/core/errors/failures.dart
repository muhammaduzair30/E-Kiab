// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure({required super.message, this.fieldErrors});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Unauthorized. Please login again.'});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}

class AIFailure extends Failure {
  const AIFailure({required super.message, super.statusCode});
}

class OfflineFailure extends Failure {
  const OfflineFailure({super.message = 'No internet connection. Using offline data.'});
}

// ─── Exceptions ─────────────────────────────────────────────────────────────

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ServerException({required this.message, this.statusCode, this.errors});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  const ValidationException({required this.message, this.fieldErrors});
}
