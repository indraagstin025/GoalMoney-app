import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter untuk mengonversi input angka mentah menjadi format mata uang Rupiah secara langsung saat mengetik.
/// Contoh: input "1000" berubah menjadi "1.000".
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jika input dihapus semua (kosong)
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Hanya izinkan angka (menghapus karakter non-numerik)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parsing teks bersih menjadi angka desimal
    double value = double.parse(cleanText);

    // Formatter Rupiah tanpa simbol "Rp" (hanya pemisah ribuan)
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    // Format angka dan hilangkan spasi
    String newText = formatter.format(value).trim();

    // Kembalikan input baru dengan kursor tetap di akhir teks
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
