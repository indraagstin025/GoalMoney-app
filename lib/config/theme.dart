import 'package:flutter/material.dart';

/// Konfigurasi Tema Global untuk aplikasi GoalMoney.
/// Menyediakan skema warna, gaya teks, dan dekorasi UI untuk Mode Terang (Light) dan Gelap (Dark).
class AppTheme {
  // Warna Utama (Primary)
  static const Color primaryLight = Color(0xFF2196F3); // Biru Terang
  static const Color primaryDark = Color(
    0xFF64B5F6,
  ); // Biru Lebih Muda (untuk kontras di mode gelap)

  /// Konfigurasi Tema Mode Terang.
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: primaryLight,
    scaffoldBackgroundColor: Colors
        .grey[50], // Background agak keabu-abuan agar konten putih menonjol
    // Tema AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),

    // Tema Tombol Utama (ElevatedButton)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Tema Input Field (TextField)
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Tema Kartu (Card)
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
    ),

    // Tema Navigasi Bawah (Bottom Navigation)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryLight,
      unselectedItemColor: Colors.grey,
    ),

    // Tema Tombol Melayang (FloatingActionButton)
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
    ),
  );

  /// Konfigurasi Tema Mode Gelap.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: primaryDark,
    scaffoldBackgroundColor: const Color(
      0xFF121212,
    ), // Background hitam pekat khas Material Dark
    // Tema AppBar Gelap
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E), // Abu-abu gelap (Surface)
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),

    // Tema Tombol Utama Gelap
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor:
            Colors.black, // Teks hitam di atas tombol biru muda agar terbaca
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Tema Input Field Gelap
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Tema Kartu Gelap
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
    ),

    // Tema Navigasi Bawah Gelap
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryDark,
      unselectedItemColor: Colors.grey,
    ),

    // Tema Tombol Melayang Gelap
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: Colors.black,
    ),

    dividerColor: Colors.grey[800],

    // Tema List (ListTile) Gelap
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
      textColor: Colors.white,
    ),
  );
}
