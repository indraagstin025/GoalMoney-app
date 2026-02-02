/// Kumpulan fungsi validasi untuk berbagai input form dalam aplikasi.
class Validators {
  /// Validasi format alamat email.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi panjang password (minimal 6 karakter).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validasi konfirmasi password agar sama dengan password utama.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  /// Validasi nama pengguna (minimal 3 karakter).
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  /// Validasi nama goal agar tidak kosong.
  static String? validateGoalName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama goal wajib diisi';
    }
    return null;
  }

  /// Validasi jumlah uang (harus angka positif dan lebih dari 0).
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jumlah wajib diisi';
    }
    // Hapus pemisah ribuan sebelum diubah menjadi angka
    final amount = double.tryParse(
      value.replaceAll(',', '').replaceAll('.', ''),
    );
    if (amount == null) {
      return 'Masukkan angka yang valid';
    }
    if (amount <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    return null;
  }

  /// Validasi umum untuk kolom yang wajib diisi.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }
}
