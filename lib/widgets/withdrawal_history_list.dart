import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/goal_provider.dart';

/// Widget yang menampilkan daftar riwayat penarikan dana (Withdrawal).
/// Mengambil data dari `GoalProvider` dan menampilkannya dalam bentuk list kartu.
class WithdrawalHistoryList extends StatelessWidget {
  final bool isDarkMode;

  const WithdrawalHistoryList({Key? key, required this.isDarkMode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Formatter mata uang untuk format Rupiah Indonesia.
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return FutureBuilder(
      // Mengambil riwayat penarikan saat pertama kali dimuat.
      future: Provider.of<GoalProvider>(
        context,
        listen: false,
      ).fetchWithdrawalHistory(),
      builder: (context, snapshot) {
        // Tampilkan indikator loading saat data sedang diambil.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Consumer<GoalProvider>(
          builder: (context, provider, child) {
            final withdrawals = provider.withdrawals;

            // Tampilan jika belum ada data riwayat penarikan.
            if (withdrawals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade100.withOpacity(0.3),
                            Colors.grey.shade50.withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat penarikan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Tampilkan daftar transaksi penarikan.
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: withdrawals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = withdrawals[index];
                Color statusColor;
                IconData statusIcon;

                // Tentukan warna dan ikon berdasarkan status penarikan.
                switch (item.status) {
                  case 'approved':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                  default: // pending
                    statusColor = Colors.orange;
                    statusIcon = Icons.access_time;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.shade200.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Ikon Status
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 28),
                        ),
                        const SizedBox(width: 16),

                        // Informasi Detail Penarikan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Jumlah penarikan
                              Text(
                                currencyFormat.format(item.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Metode penarikan (misal: E-Wallet DANA)
                              Text(
                                item.method.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Tanggal transaksi
                              Text(
                                item.createdAt,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Label Status (Badge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
