import 'package:flutter/material.dart';
import '../models/goal_filter_state.dart';

/// Widget Bottom Sheet untuk memfilter daftar goal berdasarkan bulan dan tahun.
/// Memungkinkan user untuk mempersempit tampilan goal yang sedang aktif maupun selesai.
class GoalFilterSheet extends StatefulWidget {
  /// State filter saat ini yang akan ditampilkan sebagai pilihan awal.
  final GoalFilterState initialState;

  /// Status mode gelap untuk penyesuaian tema UI.
  final bool isDarkMode;

  const GoalFilterSheet({
    Key? key,
    required this.initialState,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<GoalFilterSheet> createState() => _GoalFilterSheetState();
}

class _GoalFilterSheetState extends State<GoalFilterSheet> {
  /// Bulan yang dipilih dalam format angka (1-12).
  late int? _selectedMonth;

  /// Tahun yang dipilih.
  late int? _selectedYear;

  /// Daftar nama bulan dalam bahasa Indonesia.
  final List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Daftar tahun yang tersedia untuk filter.
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialState.month;
    _selectedYear = widget.initialState.year;

    final currentYear = DateTime.now().year;
    _years = List.generate(10, (index) => currentYear - 2 + index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Goal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = null;
                    _selectedYear = null;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Bulan Pelaksanaan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _months.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterChip(
                    label: 'Semua',
                    isSelected: _selectedMonth == null,
                    onSelected: () => setState(() => _selectedMonth = null),
                  );
                }
                final monthIndex = index;
                return _buildFilterChip(
                  label: _months[monthIndex - 1],
                  isSelected: _selectedMonth == monthIndex,
                  onSelected: () => setState(() => _selectedMonth = monthIndex),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Tahun',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _years.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterChip(
                    label: 'Semua',
                    isSelected: _selectedYear == null,
                    onSelected: () => setState(() => _selectedYear = null),
                  );
                }
                final year = _years[index - 1];
                return _buildFilterChip(
                  label: year.toString(),
                  isSelected: _selectedYear == year,
                  onSelected: () => setState(() => _selectedYear = year),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  widget.initialState.copyWith(
                    month: _selectedMonth,
                    year: _selectedYear,
                    clearMonth: _selectedMonth == null,
                    clearYear: _selectedYear == null,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Terapkan Filter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper untuk membangun Chip filter (ChoiceChip) dengan desain seragam.
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (widget.isDarkMode ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: widget.isDarkMode
          ? Colors.grey.shade800
          : Colors.grey.shade100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }
}
