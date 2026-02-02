/// Model state untuk mengelola status filter pada daftar Goal.
class GoalFilterState {
  /// Kata kunci pencarian nama goal.
  final String query;

  /// Filter berdasarkan bulan tertentu (1-12), null berarti semua bulan.
  final int? month;

  /// Filter berdasarkan tahun tertentu, null berarti semua tahun.
  final int? year;

  GoalFilterState({this.query = '', this.month, this.year});

  /// Mengecek apakah ada filter yang sedang aktif.
  bool get isActive => query.isNotEmpty || month != null || year != null;

  /// Membuat salinan state baru dengan beberapa field yang diubah.
  /// Gunakan [clearMonth] atau [clearYear] untuk menghapus filter terkait.
  GoalFilterState copyWith({
    String? query,
    int? month,
    int? year,
    bool clearMonth = false,
    bool clearYear = false,
  }) {
    return GoalFilterState(
      query: query ?? this.query,
      month: clearMonth ? null : (month ?? this.month),
      year: clearYear ? null : (year ?? this.year),
    );
  }

  /// Mengembalikan state ke kondisi awal (tanpa filter).
  GoalFilterState reset() => GoalFilterState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalFilterState &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => query.hashCode ^ month.hashCode ^ year.hashCode;
}
