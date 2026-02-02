import 'package:flutter/material.dart';
import '../utils/date_helper.dart';

/// Widget Badge untuk menampilkan status tenggat waktu goal.
/// Menampilkan indikator visual (warna & ikon) apakah goal tepat waktu, terlambat, atau jatuh tempo hari ini.
class DeadlineBadge extends StatelessWidget {
  /// Tanggal deadline dalam format string.
  final String deadline;

  /// Opsi untuk menampilkan label teks (default: true).
  final bool showLabel;

  const DeadlineBadge({Key? key, required this.deadline, this.showLabel = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hitung sisa hari dan tentukan statusnya menggunakan DateHelper.
    final diff = DateHelper.getDaysFromToday(deadline);
    final status = DateHelper.getDeadlineStatus(deadline);

    String text;
    IconData icon;
    Color color;

    // Tentukan tampilan berdasarkan status deadline.
    switch (status) {
      case DeadlineStatus.overdue:
        text = 'Terlambat ${diff.abs()} hari';
        icon = Icons.error_outline_rounded;
        color = Colors.orange.shade700;
        break;
      case DeadlineStatus.dueToday:
        text = 'Jatuh tempo hari ini';
        icon = Icons.alarm_rounded;
        color = Colors.amber.shade700;
        break;
      case DeadlineStatus.onTrack:
        text = 'Sisa $diff hari';
        icon = Icons.event_available_rounded;
        color = Colors.blue.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          // Tambahkan jarak jika teks ditampilkan
          if (showLabel) const SizedBox(width: 4),
          if (showLabel)
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
