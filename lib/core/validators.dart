class Validators {
  // Email validation
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

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // Goal name validation
  static String? validateGoalName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama goal wajib diisi';
    }
    return null;
  }

  // Amount validation (for target_amount & transaction amount)
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jumlah wajib diisi';
    }
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

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }
}
