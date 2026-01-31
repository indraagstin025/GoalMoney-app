import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/goal_provider.dart';
import '../providers/auth_provider.dart';
import '../models/goal.dart';
import '../providers/badge_provider.dart';
import '../widgets/badge_celebration_dialog.dart';
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
      final allIncomplete = goalProvider.goals
          .where((g) => g.currentAmount < g.targetAmount)
          .toList();

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

          allocations.add({'goal_id': goal.id, 'amount': amount});
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
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).setAvailableBalance(newBalance);
      }

      if (mounted) {
        // --- NEW: Trigger Badge Check ---
        try {
          final badgeProvider = Provider.of<BadgeProvider>(
            context,
            listen: false,
          );
          final newBadges = await badgeProvider.checkAndAwardBadges();

          if (newBadges.isNotEmpty && mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  BadgeCelebrationDialog(newBadges: newBadges),
            );
          }
        } catch (e) {
          debugPrint('[OverflowDialog] Badge check error: $e');
        }
        // -------------------------------

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

  /// Handle quick action for save to balance or withdraw
  Future<void> _handleQuickAction({required bool toBalance}) async {
    if (isSubmitting) return;

    if (toBalance) {
      // Save all remaining to balance
      setState(() => isSubmitting = true);
      try {
        final response = await Provider.of<GoalProvider>(context, listen: false)
            .allocateOverflow(
              allocations: [],
              saveToBalanceAmount: remainingOverflow > 0
                  ? remainingOverflow
                  : null,
            );

        if (mounted && response['available_balance'] != null) {
          final newBalance = (response['available_balance'] is num)
              ? (response['available_balance'] as num).toDouble()
              : 0.0;
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setAvailableBalance(newBalance);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sisa telah dipindahkan ke saldo akun.'),
              backgroundColor: Colors.green,
            ),
          );

          // --- NEW: Trigger Badge Check ---
          try {
            final badgeProvider = Provider.of<BadgeProvider>(
              context,
              listen: false,
            );
            badgeProvider.checkAndAwardBadges().then((newBadges) {
              if (newBadges.isNotEmpty && mounted) {
                showBadgeCelebration(context, newBadges);
              }
            });
          } catch (e) {
            print('[OverflowDialog] Badge check error: $e');
          }
          // -------------------------------

          Navigator.of(context).pop();
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
        if (mounted) setState(() => isSubmitting = false);
      }
    } else {
      // Withdraw - depends on source method
      if (widget.sourceMethod == 'manual') {
        // Manual cash - ambil tunai langsung
        setState(() => isSubmitting = true);
        try {
          await Provider.of<GoalProvider>(
            context,
            listen: false,
          ).requestWithdrawal(
            goalId: null,
            amount: remainingOverflow,
            method: 'manual',
            notes: 'Ambil tunai sisa overflow dari ${widget.completedGoalName}',
          );
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).fetchProfile();

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
          if (mounted) setState(() => isSubmitting = false);
        }
      } else {
        // Digital - navigate to withdrawal screen
        setState(() => isSubmitting = true);
        try {
          final response =
              await Provider.of<GoalProvider>(
                context,
                listen: false,
              ).allocateOverflow(
                allocations: [],
                saveToBalanceAmount: remainingOverflow,
              );

          if (mounted && response['available_balance'] != null) {
            final newBalance = (response['available_balance'] is num)
                ? (response['available_balance'] as num).toDouble()
                : 0.0;
            Provider.of<AuthProvider>(
              context,
              listen: false,
            ).setAvailableBalance(newBalance);
          }

          if (mounted) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WithdrawalScreen(
                  prefilledAmount: remainingOverflow,
                  fromOverflow: true,
                ),
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
          if (mounted) setState(() => isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    // Info Card - Improved contrast
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.shade900.withOpacity(0.4)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.blue.shade400
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: isDarkMode
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Anda memiliki sisa ${_currencyFormat.format(widget.overflowAmount)} untuk dialokasikan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade900,
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

                    // Quick Action Buttons
                    if (remainingOverflow > 0) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atau langsung:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Save to Balance Button
                            if (widget.sourceMethod != 'manual')
                              _QuickActionButton(
                                icon: Icons.account_balance_wallet,
                                label: 'Simpan ke Saldo Akun',
                                subtitle: 'Semua sisa dana ke saldo',
                                color: Colors.blue,
                                isDarkMode: isDarkMode,
                                onTap: () =>
                                    _handleQuickAction(toBalance: true),
                              ),
                            if (widget.sourceMethod != 'manual')
                              const SizedBox(height: 8),
                            // Withdraw Button
                            _QuickActionButton(
                              icon: widget.sourceMethod == 'manual'
                                  ? Icons.money_rounded
                                  : Icons.payments_outlined,
                              label: widget.sourceMethod == 'manual'
                                  ? 'Ambil Kembalian Tunai'
                                  : 'Tarik Dana',
                              subtitle: widget.sourceMethod == 'manual'
                                  ? 'Uang tunai tidak disetorkan'
                                  : 'Transfer ke E-Wallet',
                              color: widget.sourceMethod == 'manual'
                                  ? Colors.green
                                  : Colors.orange,
                              isDarkMode: isDarkMode,
                              onTap: () => _handleQuickAction(toBalance: false),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
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

        final response = await Provider.of<GoalProvider>(context, listen: false)
            .allocateOverflow(
              allocations: allocations,
              saveToBalanceAmount: remaining > 0 ? remaining : null,
            );

        if (mounted && response['available_balance'] != null) {
          final newBalance = (response['available_balance'] is num)
              ? (response['available_balance'] as num).toDouble()
              : 0.0;
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setAvailableBalance(newBalance);
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
    } else {
      // Option 2 (Withdraw)
      // If source is manual, we treat this as "Ambil Tunai" (Manual Withdrawal)
      // immediately without going to Withdrawal Screen.
      if (widget.sourceMethod == 'manual') {
        setState(() => isSubmitting = true);
        try {
          // Request manual withdrawal to deduct the balance that was just added
          await Provider.of<GoalProvider>(
            context,
            listen: false,
          ).requestWithdrawal(
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
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).fetchProfile();

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
          if (mounted) setState(() => isSubmitting = false);
        }
        return;
      }

      // Existing logic for other methods (Navigate to Withdrawal Screen)
      setState(() => isSubmitting = true);
      try {
        final response = await Provider.of<GoalProvider>(context, listen: false)
            .allocateOverflow(
              allocations: [],
              saveToBalanceAmount: widget.overflowAmount,
            );

        if (mounted && response['available_balance'] != null) {
          final newBalance = (response['available_balance'] is num)
              ? (response['available_balance'] as num).toDouble()
              : 0.0;
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setAvailableBalance(newBalance);
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
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              suffixText: 'max ${currencyFormat.format(remaining)}',
              suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
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
    final isNegative = remainingOverflow < 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNegative
                  ? (isDarkMode
                        ? Colors.red.shade900.withOpacity(0.4)
                        : Colors.red.shade50)
                  : (isDarkMode
                        ? Colors.teal.shade900.withOpacity(0.4)
                        : Colors.teal.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNegative
                    ? (isDarkMode ? Colors.red.shade400 : Colors.red.shade300)
                    : (isDarkMode
                          ? Colors.teal.shade400
                          : Colors.teal.shade300),
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
                          color: isNegative
                              ? (isDarkMode
                                    ? Colors.red.shade200
                                    : Colors.red.shade900)
                              : (isDarkMode
                                    ? Colors.teal.shade100
                                    : Colors.teal.shade900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(remainingOverflow),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isNegative
                            ? (isDarkMode
                                  ? Colors.red.shade300
                                  : Colors.red.shade700)
                            : (isDarkMode
                                  ? Colors.teal.shade200
                                  : Colors.teal.shade700),
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
            padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Total alokasi melebihi overflow!',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.red.shade300
                          : Colors.red.shade700,
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
            // Success Banner - Improved contrast
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.green.shade900.withOpacity(0.4)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.green.shade400
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: isDarkMode
                        ? Colors.green.shade300
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selamat! Semua goal telah tercapai! 🎉',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.green.shade100
                            : Colors.green.shade900,
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
                  color: isDarkMode
                      ? Colors.orange.shade900.withOpacity(0.4)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.orange.shade400
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: isDarkMode
                          ? Colors.orange.shade300
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terdapat goal lain yang belum selesai, namun tipenya berbeda (${sourceMethod == 'manual' ? "Digital" : "Tunai"}).\nDana ${sourceMethod == 'manual' ? "Tunai" : "Digital"} tidak bisa dialokasikan ke sana.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.orange.shade100
                              : Colors.orange.shade900,
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
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(overflowAmount),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.green.shade300
                    : Colors.green.shade700,
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
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.blue.shade600
                          : Colors.blue.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blue.shade800
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simpan ke Saldo Akun',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDarkMode
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gunakan untuk goal baru nanti',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: isDarkMode
                            ? Colors.blue.shade300
                            : Colors.blue.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            if (sourceMethod != 'manual') const SizedBox(height: 12),

            // Option 2: Withdraw to E-Wallet / Tarik Dana
            InkWell(
              onTap: () => onSubmit(false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? (sourceMethod == 'manual'
                            ? Colors.green.shade900.withOpacity(0.3)
                            : Colors.orange.shade900.withOpacity(0.3))
                      : (sourceMethod == 'manual'
                            ? Colors.green.shade50
                            : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? (sourceMethod == 'manual'
                              ? Colors.green.shade600
                              : Colors.orange.shade600)
                        : (sourceMethod == 'manual'
                              ? Colors.green.shade200
                              : Colors.orange.shade200),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? (sourceMethod == 'manual'
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800)
                            : (sourceMethod == 'manual'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        sourceMethod == 'manual'
                            ? Icons.money_rounded
                            : Icons.payments_outlined,
                        color: isDarkMode
                            ? (sourceMethod == 'manual'
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200)
                            : (sourceMethod == 'manual'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sourceMethod == 'manual'
                                ? 'Ambil Kembalian Tunai'
                                : 'Tarik Dana',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDarkMode
                                  ? (sourceMethod == 'manual'
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100)
                                  : (sourceMethod == 'manual'
                                        ? Colors.green.shade900
                                        : Colors.orange.shade900),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sourceMethod == 'manual'
                                ? 'Uang tunai tidak disetorkan'
                                : 'Transfer ke Dana, GoPay, OVO, dll',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? (sourceMethod == 'manual'
                                        ? Colors.green.shade300
                                        : Colors.orange.shade300)
                                  : (sourceMethod == 'manual'
                                        ? Colors.green.shade600
                                        : Colors.orange.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: isDarkMode
                          ? (sourceMethod == 'manual'
                                ? Colors.green.shade300
                                : Colors.orange.shade300)
                          : (sourceMethod == 'manual'
                                ? Colors.green.shade400
                                : Colors.orange.shade400),
                    ),
                  ],
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

/// Compact action button for quick actions
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final MaterialColor color;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDarkMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? color.shade900.withOpacity(0.3) : color.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? color.shade600 : color.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDarkMode ? color.shade800 : color.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDarkMode ? color.shade200 : color.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDarkMode ? color.shade100 : color.shade900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? color.shade300 : color.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDarkMode ? color.shade400 : color.shade400,
            ),
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
