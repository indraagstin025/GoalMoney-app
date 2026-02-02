// No imports needed for basic date logic

/// Helper utilitas untuk operasi tanggal, khususnya perhitungan tenggat waktu (deadline).
class DateHelper {
  /// Menghitung selisih hari antara dua tanggal tanpa memperhitungkan jam/menit.
  /// Mengembalikan nilai integer positif jika date1 > date2, negatif jika date1 < date2.
  static int getDaysDifference(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d1.difference(d2).inDays;
  }

  /// Menghitung berapa hari tersisa dari hari ini menuju tanggal deadline.
  /// - Positif: Masih ada waktu (hari tersisa).
  /// - Negatif: Sudah lewat tenggat (terlambat).
  /// - Nol: Hari ini adalah tenggat waktu.
  static int getDaysFromToday(String deadlineStr) {
    if (deadlineStr.isEmpty) return 0; // Fallback jika string kosong
    final deadline = DateTime.parse(deadlineStr);
    final today = DateTime.now();
    return getDaysDifference(deadline, today);
  }

  /// Menentukan status deadline berdasarkan selisih hari.
  static DeadlineStatus getDeadlineStatus(String deadlineStr) {
    final diff = getDaysFromToday(deadlineStr);
    if (diff < 0) return DeadlineStatus.overdue;
    if (diff == 0) return DeadlineStatus.dueToday;
    return DeadlineStatus.onTrack;
  }
}

/// Enum untuk status tenggat waktu goal.
enum DeadlineStatus {
  /// Masih dalam jalur (masih ada waktu).
  onTrack,

  /// Tenggat waktu hari ini.
  dueToday,

  /// Sudah melewati tenggat waktu.
  overdue,
}
