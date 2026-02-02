import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget Input field khusus untuk mata uang (Rupiah).
/// Otomatis memformat angka dengan pemisah ribuan saat diketik.
class CurrencyInputField extends StatefulWidget {
  /// Label field.
  final String label;

  /// Controller untuk teks (harus berisi angka murni atau terformat).
  final TextEditingController controller;

  /// Status mode gelap.
  final bool isDarkMode;

  /// Apakah field bisa diedit.
  final bool enabled;

  /// Fungsi validasi input.
  final String? Function(String?)? validator;

  const CurrencyInputField({
    Key? key,
    required this.label,
    required this.controller,
    required this.isDarkMode,
    this.enabled = true,
    this.validator,
  }) : super(key: key);

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  // Formatter untuk format mata uang Indonesia (IDR).
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Tambahkan listener untuk mendeteksi perubahan fokus.
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// Mengubah state fokus untuk mengatur tampilan UI (ikon dan border).
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  /// Memformat teks input menjadi format mata uang saat user mengetik.
  void _formatCurrency(String value) {
    if (value.isEmpty) return;

    // Hapus semua karakter non-digit untuk mendapatkan nilai murni.
    final numericValue = value.replaceAll(RegExp('[^0-9]'), '');
    if (numericValue.isNotEmpty) {
      // Format kembali ke bentuk Rupiah.
      final formatted = _currencyFormat.format(int.parse(numericValue));
      // Hapus simbol 'Rp ' agar yang tersimpan di controller hanya angka terformat bersih (opsional, tergantung kebutuhan).
      // Di sini kita menghapus 'Rp ' agar user tidak perlu menghapusnya manual.
      final cleanText = formatted.replaceAll('Rp ', '').trim();

      widget.controller.value = TextEditingValue(
        text: cleanText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: cleanText.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    // Tampilkan prefix 'Rp' jika field fokus atau sudah ada isinya.
    final showPrefix = _isFocused || hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: showPrefix ? '' : 'Contoh: Rp 1.000.000',
            hintStyle: TextStyle(
              color: widget.isDarkMode
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            prefixText: showPrefix ? 'Rp ' : null,
            prefixStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.payments_rounded,
              color: _isFocused ? Colors.lightGreen.shade700 : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.lightGreen.shade700,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
            ),
            filled: true,
            fillColor: widget.enabled
                ? (widget.isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.3)
                      : Colors.grey.shade50)
                : (widget.isDarkMode
                      ? Colors.grey.shade900.withOpacity(0.5)
                      : Colors.grey.shade200),
          ),
          keyboardType: TextInputType.number,
          onChanged: _formatCurrency,
          validator: widget.validator,
        ),
      ],
    );
  }
}
