import 'package:flutter/material.dart';

/// Widget Input field pencarian dengan desain modern (sudut membulat dan bayangan).
/// Mendukung mode gelap/terang dan tombol untuk menghapus teks secara cepat.
class SearchField extends StatelessWidget {
  /// Controller untuk teks pencarian.
  final TextEditingController controller;

  /// Callback saat teks berubah.
  final ValueChanged<String> onChanged;

  /// Callback saat tombol clear (x) ditekan.
  final VoidCallback onClear;

  /// Placeholder teks pencarian.
  final String hintText;

  /// Status mode gelap untuk penyesuaian warna.
  final bool isDarkMode;

  const SearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isDarkMode,
    this.hintText = 'Cari berdasarkan nama...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.green.shade700,
            size: 22,
          ),
          // Tombol clear hanya muncul jika ada teks
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                  color: Colors.grey,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
