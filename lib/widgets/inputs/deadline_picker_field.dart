import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget Input kustom untuk memilih tanggal tenggat waktu (deadline).
/// Menampilkan tanggal yang dipilih atau placeholder, dengan tombol hapus jika sudah dipilih.
class DeadlinePickerField extends StatelessWidget {
  /// Tanggal yang saat ini dipilih (null jika belum ada).
  final DateTime? selectedDate;

  /// Format tampilan tanggal (misal: 'dd MMM yyyy').
  final DateFormat displayFormat;

  /// Status mode gelap untuk penyesuaian gaya UI.
  final bool isDarkMode;

  /// Callback saat area picker ditekan (membuka DatePicker).
  final VoidCallback onTap;

  /// Callback saat tombol hapus (x) ditekan untuk mereset tanggal.
  final VoidCallback onClear;

  /// Label field (default: 'Tenggat Waktu (Opsional)').
  final String label;

  const DeadlinePickerField({
    Key? key,
    required this.selectedDate,
    required this.displayFormat,
    required this.isDarkMode,
    required this.onTap,
    required this.onClear,
    this.label = 'Tenggat Waktu (Opsional)',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tampilkan label jika string tidak kosong
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade50,
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? displayFormat.format(selectedDate!)
                        : 'Pilih tanggal target pencapaian',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                // Tampilkan tombol hapus hanya jika tanggal sudah dipilih
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
