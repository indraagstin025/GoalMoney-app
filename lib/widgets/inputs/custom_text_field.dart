import 'package:flutter/material.dart';

/// Widget TextField kustom dengan desain standar aplikasi.
/// Digunakan untuk input teks umum seperti nama, email, deskripsi, dll.
class CustomTextField extends StatelessWidget {
  /// Controller untuk mengelola teks yang diinput.
  final TextEditingController controller;

  /// Label yang muncul di atas field.
  final String label;

  /// Apakah teks harus disembunyikan (untuk password).
  final bool obscureText;

  /// Tipe keyboard yang akan dimunculkan (angka, teks, email, dll).
  final TextInputType keyboardType;

  /// Teks awalan (opsional), misalnya 'Rp' atau '+62'.
  final String? prefixText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}
