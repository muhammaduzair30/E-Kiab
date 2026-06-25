import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final user = ref.watch(authStateProvider).user;
  final role = user?.role ?? 'guest';
  return ThemeNotifier(role);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final String role;
  late SharedPreferences _prefs;

  ThemeNotifier(this.role) : super(ThemeMode.system) {
    _loadTheme();
  }

  String get _themeKey => 'app_theme_mode_$role';

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final String? themeStr = _prefs.getString(_themeKey);
    if (themeStr != null) {
      if (themeStr == 'light') {
        state = ThemeMode.light;
      } else if (themeStr == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } else {
      // Fallback to legacy global key
      final String? globalThemeStr = _prefs.getString('app_theme_mode');
      if (globalThemeStr != null) {
        if (globalThemeStr == 'light') {
          state = ThemeMode.light;
        } else if (globalThemeStr == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      } else {
        state = ThemeMode.system;
      }
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    String themeStr = 'system';
    if (mode == ThemeMode.light) themeStr = 'light';
    if (mode == ThemeMode.dark) themeStr = 'dark';
    await _prefs.setString(_themeKey, themeStr);
  }
}
