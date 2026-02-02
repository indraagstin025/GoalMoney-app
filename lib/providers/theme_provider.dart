import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola tema aplikasi (Terang/Gelap).
/// Pengaturan tema disimpan secara permanen menggunakan [SharedPreferences].
class ThemeProvider with ChangeNotifier {
  /// Key untuk menyimpan preferensi tema di memori lokal.
  static const String _themeKey = 'theme_mode';

  /// Mode tema saat ini, default mengikuti sistem (ThemeMode.system).
  ThemeMode _themeMode = ThemeMode.system;

  /// Mengambil mode tema saat ini.
  ThemeMode get themeMode => _themeMode;

  /// Mengecek apakah aplikasi sedang dalam mode gelap.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    // Memuat preferensi tema saat aplikasi dijalankan.
    _loadThemeMode();
  }

  /// Memuat mode tema yang tersimpan di [SharedPreferences].
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);

    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  /// Mengubah mode tema dan menyimpannya secara permanen.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// Berpindah antara mode gelap dan mode terang.
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
