import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/goal.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/goal_provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(widget.goal.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(widget.goal.name)),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).fetchTransactions(widget.goal.id);
          // Also refresh goal data to keep balance in sync
          await Provider.of<GoalProvider>(context, listen: false).fetchGoals();
        },
        child: Column(
          children: [
            // Header Card
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(widget.goal.currentAmount),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: widget.goal.progress / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${currency.format(widget.goal.targetAmount)}',
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Transaction List
            Expanded(
              child: transactionProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : transactionProvider.transactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactionProvider.transactions.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final transaction =
                            transactionProvider.transactions[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(transaction.description ?? 'Deposit'),
                          subtitle: Text(
                            dateFormat.format(
                              DateTime.parse(transaction.transactionDate),
                            ),
                          ),
                          trailing: Text(
                            '+ ${currency.format(transaction.amount)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Transaction?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await transactionProvider
                                          .deleteTransaction(
                                            transaction.id,
                                            widget.goal.id,
                                          );
                                      // Refresh goal to update balance
                                      if (mounted) {
                                        Provider.of<GoalProvider>(
                                          context,
                                          listen: false,
                                        ).fetchGoals();
                                      }
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
