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
  final String? sourceMethod; // Add sourceMethod

  const OverflowAllocationDialog({
    Key? key,
    required this.overflowAmount,
    required this.completedGoalName,
    this.sourceMethod,
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
  bool hasIncompatibleGoals = false; // Track if we filtered out goals

  @override
  void initState() {
    super.initState();
    remainingOverflow = widget.overflowAmount;
    _loadAvailableGoals();
  }

  Future<void> _loadAvailableGoals() async {
    try {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      
      // Check if there are ANY incomplete goals before filtering
      final allIncomplete = goalProvider.goals.where((g) => g.currentAmount < g.targetAmount).toList();
      
      // Filter goals by TYPE
      availableGoals = allIncomplete.where((g) {
        // Must match source type (Cash for Cash, Digital for Digital)
        final isSourceCash = widget.sourceMethod == 'manual';
        final isGoalCash = g.type == 'cash';
        return isSourceCash == isGoalCash;
      }).toList();

      // If we had incomplete goals but availableGoals is empty, it means they were incompatible
      if (allIncomplete.isNotEmpty && availableGoals.isEmpty) {
        hasIncompatibleGoals = true;
      } else {
        hasIncompatibleGoals = false;
      }

      // Initialize controllers
      for (var goal in availableGoals) {
        controllers[goal.id] = TextEditingController();
      }

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
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
              // CASE: All goals completed or incompatible - offer withdrawal option
              ? _AllGoalsCompletedView(
                  overflowAmount: widget.overflowAmount,
                  isDarkMode: isDarkMode,
                  currencyFormat: _currencyFormat,
                  sourceMethod: widget.sourceMethod, // Pass sourceMethod
                  hasIncompatibleGoals: hasIncompatibleGoals, // Pass flag
                  onSubmit: (bool toBalance) async {
                       _handleAllCompletedSubmission(toBalance);
                  },
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
                              return AllocationGoalItem(
                                key: ValueKey(goal.id),
                                goal: goal,
                                controller: controllers[goal.id]!,
                                currencyFormat: _currencyFormat,
                                isDarkMode: isDarkMode,
                                onChanged: (_) => _calculateRemaining(),
                              );
                            }).toList(),
                          ),
                        ),

                        const Divider(height: 24),

                        // Remaining Summary
                        _SummarySection(
                          remainingOverflow: remainingOverflow,
                          isDarkMode: isDarkMode,
                          currencyFormat: _currencyFormat,
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

  Future<void> _handleAllCompletedSubmission(bool toBalance) async {
       if (toBalance) {
          // Option 1
          final remaining = widget.overflowAmount;

          setState(() => isSubmitting = true);
          try {
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
       } else {
          // Option 2 (Withdraw)
          // If source is manual, we treat this as "Ambil Tunai" (Manual Withdrawal)
          // immediately without going to Withdrawal Screen.
          if (widget.sourceMethod == 'manual') {
             setState(() => isSubmitting = true);
             try {
                // Request manual withdrawal to deduct the balance that was just added
                await Provider.of<GoalProvider>(context, listen: false)
                  .requestWithdrawal(
                    // No goal ID (withdraw from balance)
                    // Wait, goalId check in provider supports null? Yes, we fixed it.
                    goalId: null, 
                    amount: widget.overflowAmount,
                    method: 'manual',
                    notes: 'Ambil tunai sisa overflow dari ${widget.completedGoalName}',
                  );

                // No need to setAvailableBalance explicitly as requestWithdrawal likely doesn't return it
                // But we should refresh profile? Or just assume it's deducted.
                // Actually requestWithdrawal response might not contain new balance.
                // We should fetch profile.
                await Provider.of<AuthProvider>(context, listen: false).fetchProfile();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sisa dana tunai telah diambil kembali'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
             } catch(e) {
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
                if(mounted) setState(() => isSubmitting = false);
             }
             return;
          }

          // Existing logic for other methods (Navigate to Withdrawal Screen)
          setState(() => isSubmitting = true);
          try {
            final response = await Provider.of<GoalProvider>(context,
                    listen: false)
                .allocateOverflow(
              allocations: [],
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
       }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class AllocationGoalItem extends StatelessWidget {
  final Goal goal;
  final TextEditingController controller;
  final NumberFormat currencyFormat;
  final bool isDarkMode;
  final ValueChanged<String> onChanged;

  const AllocationGoalItem({
    Key? key,
    required this.goal,
    required this.controller,
    required this.currencyFormat,
    required this.isDarkMode,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = goal.targetAmount - goal.currentAmount;
    
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
            'Sisa target: ${currencyFormat.format(remaining)}',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              suffixText:
                  'max ${currencyFormat.format(remaining)}',
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final double remainingOverflow;
  final bool isDarkMode;
  final NumberFormat currencyFormat;

  const _SummarySection({
    Key? key,
    required this.remainingOverflow,
    required this.isDarkMode,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: remainingOverflow < 0
                  ? Colors.red.shade50
                  : (isDarkMode
                      ? Colors.green.shade900.withOpacity(0.3)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      currencyFormat.format(remainingOverflow),
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
    );
  }
}

class _AllGoalsCompletedView extends StatelessWidget {
  final double overflowAmount;
  final bool isDarkMode;
  final NumberFormat currencyFormat;
  final Function(bool) onSubmit;
  final String? sourceMethod;
  final bool hasIncompatibleGoals;

  const _AllGoalsCompletedView({
    Key? key,
    required this.overflowAmount,
    required this.isDarkMode,
    required this.currencyFormat,
    required this.onSubmit,
    this.sourceMethod,
    this.hasIncompatibleGoals = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            
            // Warning if incompatible goals exist
            if (hasIncompatibleGoals)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terdapat goal lain yang belum selesai, namun tipenya berbeda (${sourceMethod == 'manual' ? "Digital" : "Tunai"}).\nDana ${sourceMethod == 'manual' ? "Tunai" : "Digital"} tidak bisa dialokasikan ke sana.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.orange.shade900),
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
              currencyFormat.format(overflowAmount),
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

            // Option 1: Save as Balance (Only if NOT manual)
            if (sourceMethod != 'manual')
              InkWell(
                onTap: () => onSubmit(true),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.account_balance_wallet,
                              color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Simpan di Akun',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Gunakan untuk goal baru nanti',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (sourceMethod != 'manual')
               const SizedBox(height: 12),

            // Option 2: Withdraw to E-Wallet
              InkWell(
                onTap: () => onSubmit(false),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sourceMethod == 'manual' 
                                ? Colors.green.shade50 
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                             sourceMethod == 'manual'
                                ? Icons.money_rounded // Icon for manual cash
                                : Icons.payment,
                             color: sourceMethod == 'manual'
                                ? Colors.green.shade700
                                : Colors.orange.shade700
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sourceMethod == 'manual' 
                                    ? 'Ambil Kembalian' 
                                    : 'Tarik ke E-Wallet',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                sourceMethod == 'manual'
                                    ? 'Uang tunai deposit tidak disetorkan'
                                    : 'Transfer ke Dana, GoPay, dll',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Helper function to show dialog
void showOverflowAllocationDialog({
  required BuildContext context,
  required double overflowAmount,
  required String completedGoalName,
  String? sourceMethod,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => OverflowAllocationDialog(
      overflowAmount: overflowAmount,
      completedGoalName: completedGoalName,
      sourceMethod: sourceMethod,
    ),
  );
}
