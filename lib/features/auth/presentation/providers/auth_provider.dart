import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSourceImpl(),
  );
});

// ─── Auth State ──────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isOnboarded;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isOnboarded = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isOnboarded,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    // Check onboarding
    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool(AppConstants.onboardingKey) ?? false;

    // Check auth
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      final result = await _repository.getCurrentUser();
      result.fold(
        (failure) => state = state.copyWith(isLoading: false, isOnboarded: isOnboarded, clearUser: true),
        (user) => state = state.copyWith(isLoading: false, isOnboarded: isOnboarded, user: user),
      );
    } else {
      state = state.copyWith(isLoading: false, isOnboarded: isOnboarded);
    }
  }

  Future<bool> login({required String email, required String password, String? role}) async {
    debugPrint('AuthNotifier: login() called for $email');
    state = state.copyWith(isLoading: true, clearError: true);
    
    debugPrint('AuthNotifier: calling _repository.login()');
    final result = await _repository.login(email: email, password: password, role: role);
    debugPrint('AuthNotifier: _repository.login() returned');
    
    return result.fold(
      (failure) {
        debugPrint('AuthNotifier: login failed: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        debugPrint('AuthNotifier: login successful: ${user.email}');
        state = state.copyWith(isLoading: false, user: user, clearError: true);
        return true;
      },
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.register(
      name: name, email: email, password: password, role: role, phone: phone,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user, clearError: true);
        return true;
      },
    );
  }

  Future<bool> googleSignIn({String? role}) async {
    debugPrint('AuthNotifier: googleSignIn() called');
    state = state.copyWith(isLoading: true, clearError: true);
    
    debugPrint('AuthNotifier: calling _repository.googleSignIn()');
    final result = await _repository.googleSignIn(role: role);
    debugPrint('AuthNotifier: _repository.googleSignIn() returned');
    
    return result.fold(
      (failure) {
        debugPrint('AuthNotifier: googleSignIn failed: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        debugPrint('AuthNotifier: googleSignIn successful: ${user.email}');
        state = state.copyWith(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(isOnboarded: true);
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.forgotPassword(email);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.verifyOtp(email: email, otp: otp);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        // Mark verified in current user
        if (state.user != null) {
          state = state.copyWith(
            isLoading: false,
            user: state.user!.copyWith(isVerified: true),
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      },
    );
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    state = state.copyWith(isOnboarded: true);
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<bool> updateStudentProfile({
    required String gradeId, required String boardId,
  }) async {
    final result = await _repository.updateStudentProfile(gradeId: gradeId, boardId: boardId);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(user: user);
        return true;
      },
    );
  }
}
