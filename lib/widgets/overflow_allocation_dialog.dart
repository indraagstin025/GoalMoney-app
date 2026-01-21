import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/goal_provider.dart';
import '../providers/auth_provider.dart';
import '../models/goal.dart';
import '../screens/withdrawals/withdrawal_screen.dart';

class OverflowAllocationDialog extends StatefulWidget {
  final double overflowAmount;
  final String completedGoalName;

  const OverflowAllocationDialog({
    Key? key,
    required this.overflowAmount,
    required this.completedGoalName,
  }) : super(key: key);

  @override
  State<OverflowAllocationDialog> createState() =>
      _OverflowAllocationDialogState();
}

class _OverflowAllocationDialogState extends State<OverflowAllocationDialog> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Goal> availableGoals = [];
  Map<int, TextEditingController> controllers = {};
  double remainingOverflow = 0;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    remainingOverflow = widget.overflowAmount;
    _loadAvailableGoals();
  }

  Future<void> _loadAvailableGoals() async {
    try {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      
      // Filter goals yang belum completed
      availableGoals = goalProvider.goals.where((g) {
        return g.currentAmount < g.targetAmount;
      }).toList();

      // Initialize controllers
      for (var goal in availableGoals) {
        controllers[goal.id] = TextEditingController();
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat goal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _calculateRemaining() {
    double total = 0;
    for (var controller in controllers.values) {
      final text = controller.text.replaceAll('.', '').replaceAll(',', '');
      final value = double.tryParse(text) ?? 0;
      total += value;
    }
    setState(() {
      remainingOverflow = widget.overflowAmount - total;
    });
  }

  Future<void> _submitAllocation() async {
    if (isSubmitting) return;

    try {
      setState(() => isSubmitting = true);

      // Build allocations array
      List<Map<String, dynamic>> allocations = [];

      for (var goal in availableGoals) {
        final controller = controllers[goal.id]!;
        final text = controller.text.replaceAll('.', '').replaceAll(',', '');
        final amount = double.tryParse(text) ?? 0;

        if (amount > 0) {
          // Validate tidak melebihi remaining target
          final remaining = goal.targetAmount - goal.currentAmount;
          if (amount > remaining) {
            throw Exception(
              'Jumlah untuk "${goal.name}" melebihi sisa target (${_currencyFormat.format(remaining)})',
            );
          }

          allocations.add({
            'goal_id': goal.id,
            'amount': amount,
          });
        }
      }

      if (allocations.isEmpty && remainingOverflow == widget.overflowAmount) {
        throw Exception(
          'Silakan alokasikan minimal ke satu goal atau simpan sebagai balance',
        );
      }

      // Call allocation endpoint
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      final response = await goalProvider.allocateOverflow(
        allocations: allocations,
        saveToBalanceAmount: remainingOverflow > 0 ? remainingOverflow : null,
      );

      if (mounted && response['available_balance'] != null) {
         final newBalance = (response['available_balance'] is num)
            ? (response['available_balance'] as num).toDouble()
            : 0.0;
         Provider.of<AuthProvider>(context, listen: false)
            .setAvailableBalance(newBalance);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overflow berhasil dialokasikan! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Goal Tercapai! 🎉',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Goal "${widget.completedGoalName}" telah selesai',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      content: isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : availableGoals.isEmpty
              // CASE: All goals completed - offer withdrawal option
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.celebration,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selamat! Semua goal telah tercapai! 🎉',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Anda memiliki sisa dana:',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currencyFormat.format(widget.overflowAmount),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Pilih tindakan:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Option 1: Save as Balance
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.white,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.account_balance_wallet,
                                  color: Colors.blue.shade700),
                            ),
                            title: const Text(
                              'Simpan di Akun',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Gunakan untuk goal baru nanti',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            onTap: () async {
                              // Save remaining amount to balance instead of using boolean
                              final remaining = widget.overflowAmount;

                              setState(() => isSubmitting = true);
                              try {
                                // Prepare allocations list (empty in this case as all goals are completed)
                                final allocations = <Map<String, dynamic>>[];

                                final response = await Provider.of<GoalProvider>(context,
                                        listen: false)
                                    .allocateOverflow(
                                  allocations: allocations,
                                  saveToBalanceAmount:
                                      remaining > 0 ? remaining : null,
                                );

                                if (mounted && response['available_balance'] != null) {
                                   final newBalance = (response['available_balance'] is num)
                                      ? (response['available_balance'] as num).toDouble()
                                      : 0.0;
                                   Provider.of<AuthProvider>(context, listen: false)
                                      .setAvailableBalance(newBalance);
                                }

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dana disimpan sebagai Available Balance'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e
                                          .toString()
                                          .replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => isSubmitting = false);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Option 2: Withdraw to E-Wallet
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.white,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.payment,
                                  color: Colors.orange.shade700),
                            ),
                            title: const Text(
                              'Tarik ke E-Wallet',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Transfer ke Dana, GoPay, dll',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            onTap: () async {
                              // CRITICAL: Save to balance FIRST before withdrawing
                              setState(() => isSubmitting = true);
                              try {
                                final response = await Provider.of<GoalProvider>(context,
                                        listen: false)
                                    .allocateOverflow(
                                  allocations: [],
                                  // Save FULL amount to balance first
                                  saveToBalanceAmount: widget.overflowAmount,
                                );
                                
                                if (mounted && response['available_balance'] != null) {
                                   final newBalance = (response['available_balance'] is num)
                                      ? (response['available_balance'] as num).toDouble()
                                      : 0.0;
                                   Provider.of<AuthProvider>(context, listen: false)
                                      .setAvailableBalance(newBalance);
                                }

                                if (mounted) {
                                  Navigator.pop(context); // Close dialog

                                  // Navigate to withdrawal screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WithdrawalScreen(
                                        prefilledAmount: widget.overflowAmount,
                                        fromOverflow: true,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => isSubmitting = false);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                )
              // CASE: Goals available for allocation
              : SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Anda memiliki sisa ${_currencyFormat.format(widget.overflowAmount)} untuk dialokasikan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Default padding for list
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: availableGoals.map((goal) {
                        final remaining =
                            goal.targetAmount - goal.currentAmount;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.flag_rounded,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      goal.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sisa target: ${_currencyFormat.format(remaining)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controllers[goal.id],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  prefixText: 'Rp ',
                                  suffixText:
                                      'max ${_currencyFormat.format(remaining)}',
                                  suffixStyle: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.green.shade700,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => _calculateRemaining(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                          ),
                        ),

                        const Divider(height: 24),

                        // Remaining Summary
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: remainingOverflow < 0
                                  ? Colors.red.shade50
                                  : (isDarkMode
                                      ? Colors.green.shade900
                                          .withOpacity(0.3)
                                      : Colors.green.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: remainingOverflow < 0
                                    ? Colors.red.shade300
                                    : Colors.green.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Sisa yang akan disimpan:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: remainingOverflow < 0
                                              ? Colors.red.shade900
                                              : (isDarkMode
                                                  ? Colors.green.shade100
                                                  : Colors.green.shade900),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currencyFormat
                                          .format(remainingOverflow),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: remainingOverflow < 0
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (remainingOverflow < 0)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 12, left: 24, right: 24),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Total alokasi melebihi overflow!',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      actions: availableGoals.isEmpty
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ]
          : [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: (remainingOverflow < 0 || isSubmitting)
                    ? null
                    : _submitAllocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Alokasikan'),
              ),
            ],
    );
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

// Helper function to show dialog
void showOverflowAllocationDialog({
  required BuildContext context,
  required double overflowAmount,
  required String completedGoalName,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => OverflowAllocationDialog(
      overflowAmount: overflowAmount,
      completedGoalName: completedGoalName,
    ),
  );
}
