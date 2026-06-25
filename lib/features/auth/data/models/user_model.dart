// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.profileImage,
    required super.isVerified,
    required super.isActive,
    super.studentProfile,
    required super.createdAt,
    super.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      studentProfile: json['studentProfile'] != null
          ? StudentProfileModel.fromJson(json['studentProfile'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'studentProfile': studentProfile != null ? {
        'gradeId': studentProfile!.gradeId,
        'gradeName': studentProfile!.gradeName,
        'boardId': studentProfile!.boardId,
        'boardName': studentProfile!.boardName,
        'readingStreak': studentProfile!.readingStreak,
        'totalPoints': studentProfile!.totalPoints,
        'badges': studentProfile!.badges,
        'booksRead': studentProfile!.booksRead,
        'quizzesAttempted': studentProfile!.quizzesAttempted,
      } : null,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      profileImage: user.profileImage,
      isVerified: user.isVerified,
      isActive: user.isActive,
      studentProfile: user.studentProfile,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }
}

class StudentProfileModel extends StudentProfile {
  const StudentProfileModel({
    super.gradeId,
    super.gradeName,
    super.boardId,
    super.boardName,
    super.readingStreak,
    super.totalPoints,
    required super.badges,
    required super.booksRead,
    required super.quizzesAttempted,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      gradeId: json['gradeId'] as String?,
      gradeName: json['gradeName'] as String?,
      boardId: json['boardId'] as String?,
      boardName: json['boardName'] as String?,
      readingStreak: json['readingStreak'] as int?,
      totalPoints: json['totalPoints'] as int?,
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? [],
      booksRead: json['booksRead'] as int? ?? 0,
      quizzesAttempted: json['quizzesAttempted'] as int? ?? 0,
    );
  }
}
