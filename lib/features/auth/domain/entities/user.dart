// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'student'
  final String? phone;
  final String? profileImage;
  final bool isVerified;
  final bool isActive;
  final StudentProfile? studentProfile;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImage,
    required this.isVerified,
    required this.isActive,
    this.studentProfile,
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';

  String get displayName => name.split(' ').first;
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  User copyWith({
    String? name,
    String? phone,
    String? profileImage,
    bool? isVerified,
    StudentProfile? studentProfile,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive,
      studentProfile: studentProfile ?? this.studentProfile,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [id, email, role];
}

class StudentProfile extends Equatable {
  final String? gradeId;
  final String? gradeName;
  final String? boardId;
  final String? boardName;
  final int? readingStreak;
  final int? totalPoints;
  final List<String> badges;
  final int booksRead;
  final int quizzesAttempted;

  const StudentProfile({
    this.gradeId,
    this.gradeName,
    this.boardId,
    this.boardName,
    this.readingStreak,
    this.totalPoints,
    required this.badges,
    required this.booksRead,
    required this.quizzesAttempted,
  });

  @override
  List<Object?> get props => [gradeId, boardId];
}
