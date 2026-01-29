import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/validators.dart';
import '../../widgets/overflow_allocation_dialog.dart';

class DepositScreen extends StatefulWidget {
  final int goalId;
  final String goalName;

  const DepositScreen({
    Key? key,
    required this.goalId,
    required this.goalName,
  }) : super(key: key);

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedMethod = 'manual';
  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'manual': {
      'name': 'Manual Cash',
      'icon': Icons.money_rounded,
      'color': Colors.green,
    },
    'balance': {
      'name': 'Saldo Akun',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.orange,
    },
    'dana': {
      'name': 'DANA',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
    },
    'gopay': {
      'name': 'GoPay',
      'icon': Icons.payment,
      'color': Colors.green,
    },
    'ovo': {
      'name': 'OVO',
      'icon': Icons.wallet,
      'color': Colors.purple,
    },
    'shopeepay': {
      'name': 'ShopeePay',
      'icon': Icons.shopping_bag,
      'color': Colors.orange,
    },
    'bank_transfer': {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'color': Colors.indigo,
    },
  };

  bool _isLoading = false;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(
        _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
      );

      // UPDATED: Now receives overflow info
      final result = await Provider.of<GoalProvider>(context, listen: false).addTransaction(
        goalId: widget.goalId,
        amount: amount,
        method: _selectedMethod,
        description: _descCtrl.text.isNotEmpty
            ? _descCtrl.text
            : 'Deposit via ${_paymentMethods[_selectedMethod]!['name']}',
      );

      if (!mounted) return;

      // UPDATED: Check for overflow
      if (result['overflow_amount'] != null && result['overflow_amount'] > 0) {
        // Goal completed with overflow
        Navigator.pop(context, true); // Close deposit screen first

        // Show overflow allocation dialog
        showOverflowAllocationDialog(
          context: context,
          overflowAmount: result['overflow_amount'].toDouble(),
          completedGoalName: widget.goalName,
          sourceMethod: _selectedMethod,
        );
      } else {
        // Normal deposit without overflow
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['goal_completed'] == true
                  ? '🎉 Goal tercapai! Tabungan berhasil!'
                  : 'Berhasil menabung! 💰',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            const _CustomHeader(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Tambah Tabungan 💰',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Goal: ${widget.goalName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Amount Field
                      Text(
                        'Nominal Tabungan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountCtrl,
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixText: 'Rp ',
                          prefixIcon: Icon(
                            Icons.payments_rounded,
                            color: Colors.lightGreen.shade700,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.lightGreen.shade700,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.3)
                              : Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        validator: Validators.validateAmount,
                      ),
                      const SizedBox(height: 20),

                      // Payment Method Selection
                      Text(
                        'Sumber Dana',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Get goal to determine type
                          final goal = Provider.of<GoalProvider>(context)
                              .goals
                              .firstWhere((g) => g.id == widget.goalId);
                          print('DEBUG: DepositScreen Goal: ${goal.name}, Type: ${goal.type}, ID: ${goal.id}');
                          final isCashGoal = goal.type == 'cash';
                          
                          // Filter methods
                          final allowedMethods = _paymentMethods.entries.where((entry) {
                            if (isCashGoal) {
                              return entry.key == 'manual';
                            } else {
                              // Digital goal: allow everything EXCEPT manual
                              return entry.key != 'manual';
                            }
                          }).where((entry) {
                            // Balance check (for digital)
                            if (entry.key == 'balance') {
                              final user = Provider.of<AuthProvider>(context).user;
                              return user != null && user.availableBalance > 0;
                            }
                            return true;
                          }).toList();
                          
                          // Ensure selected method is valid
                          // We can't update state here, so we select a display value
                          String displaySelected = _selectedMethod;
                          bool isValid = allowedMethods.any((e) => e.key == _selectedMethod);
                          
                          if (!isValid && allowedMethods.isNotEmpty) {
                            displaySelected = allowedMethods.first.key;
                            // Schedule state update to sync variable (optional but good for consistency)
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_selectedMethod != displaySelected) {
                                setState(() => _selectedMethod = displaySelected);
                              }
                            });
                          }

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: displaySelected,
                            decoration: InputDecoration(
                              hintText: 'Pilih sumber dana',
                              prefixIcon: Icon(
                                _paymentMethods[displaySelected]?['icon'] ?? Icons.payment,
                                color: Colors.lightGreen.shade700,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.lightGreen.shade700,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.grey.shade800.withOpacity(0.3)
                                  : Colors.grey.shade50,
                            ),
                            items: allowedMethods.map((entry) {
                               String name = entry.value['name'];
                               if (entry.key == 'balance') {
                                 final user = Provider.of<AuthProvider>(context).user;
                                 if (user != null) {
                                   name += ' (${_currencyFormat.format(user.availableBalance)})';
                                 }
                               }
                              
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (entry.value['color'] as Color)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        entry.value['icon'],
                                        color: entry.value['color'],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedMethod = val!),
                          );
                        }
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      Text(
                        'Catatan (Opsional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: InputDecoration(
                          hintText: 'Misal: Sisa uang jajan',
                          prefixIcon: Icon(
                            Icons.note_outlined,
                            color: Colors.lightGreen.shade700,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.lightGreen.shade700,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.3)
                              : Colors.grey.shade50,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade700,
                                      Colors.green.shade500,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade700,
                                      Colors.green.shade500,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade200
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Simpan Tabungan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomHeader extends StatelessWidget {
  const _CustomHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GoalMoney Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'GoalMoney',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.lightGreen,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
