import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double totalSaved;
  final double overallProgress;
  final NumberFormat currencyFormat;

  const SummaryCard({
    super.key,
    required this.totalSaved,
    required this.overallProgress,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Saved',
              style: TextStyle(fontSize: 14, color: Colors.green.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(totalSaved),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: overallProgress / 100,
              backgroundColor: Colors.green.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              '${overallProgress.toStringAsFixed(1)}% of Total Target',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
          ],
        ),
      ),
    );
  }
}
