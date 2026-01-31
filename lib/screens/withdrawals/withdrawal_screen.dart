import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/validators.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/badge_celebration_dialog.dart';
import '../../widgets/currency_input_field.dart';
import '../../widgets/withdrawal_header.dart';
import '../../widgets/withdrawal_history_list.dart';

class WithdrawalScreen extends StatefulWidget {
  final double? prefilledAmount;
  final bool fromOverflow;

  const WithdrawalScreen({
    super.key,
    this.prefilledAmount,
    this.fromOverflow = false,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  final _accountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedMethod = 'dana';
  final Map<String, IconData> _methodIcons = {
    'dana': Icons.account_balance_wallet,
    'gopay': Icons.payment,
    'bank_transfer': Icons.account_balance,
    'ovo': Icons.wallet,
    'shopeepay': Icons.shopping_bag,
    'manual': Icons.money_rounded,
    'pospay': Icons.local_post_office_rounded,
  };

  bool _isLoading = false;
  double _totalSavings = 0;

  // Goal selection
  int? _selectedGoalId;
  double _selectedGoalBalance = 0;

  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.prefilledAmount != null
          ? widget.prefilledAmount!.toInt().toString()
          : '',
    );
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _fetchData() async {
    try {
      final provider = Provider.of<GoalProvider>(context, listen: false);
      await provider.fetchDashboardSummary();
      await provider.fetchGoals();

      if (provider.summary != null && mounted) {
        setState(() {
          final total = provider.summary!['total_saved'];
          _totalSavings = (total is num) ? total.toDouble() : 0.0;

          // Auto-select first goal if available
          if (provider.goals.isNotEmpty) {
            _selectedGoalId = provider.goals.first.id;
            _selectedGoalBalance = provider.goals.first.currentAmount;

            // Set method based on goal type
            if (provider.goals.first.type == 'cash') {
              _selectedMethod = 'manual';
            } else {
              _selectedMethod = 'dana';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if goal is selected OR explicitly null (Available Balance)
    // Actually _selectedGoalId being null is now valid for Balance.
    // However, we rely on the dropdown to set it.
    // If it's valid to be null, we remove this check OR adjust it.

    // BUT wait, init/fetch sets it to first goal.
    // So distinct null vs "not set" is tricky if "not set" is null.
    // But in our dropdown we explicitly set value: null.

    // Let's assume if it is null, it means Available Balance because we default select first goal if available.
    // If no goals available, it stays null?

    // Ideally we should have a flag or just trust the selection.

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(
        _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
      );

      // Validasi saldo goal yang dipilih
      if (amount > _selectedGoalBalance) {
        throw Exception('Saldo tidak mencukupi');
      }

      // Send withdrawal request to backend with goalId (nullable)
      await Provider.of<GoalProvider>(context, listen: false).requestWithdrawal(
        goalId: _selectedGoalId,
        amount: amount,
        method: _selectedMethod,
        accountNumber: _accountCtrl.text,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );

      if (!mounted) return;

      // Badge check moved to after processing logic

      if (!mounted) return;

      // Show processing dialog with countdown
      await _showProcessingDialog();

      if (!mounted) return;

      // After waiting, refresh history to trigger auto-approval check
      await Provider.of<GoalProvider>(
        context,
        listen: false,
      ).fetchWithdrawalHistory();
      await Provider.of<GoalProvider>(
        context,
        listen: false,
      ).fetchDashboardSummary();

      // Fetch Notifications so the new one appears immediately
      await Provider.of<GoalProvider>(
        context,
        listen: false,
      ).fetchNotifications();

      if (!mounted) return;

      // --- MOVED: Trigger Badge Check (After success) ---
      try {
        final badgeProvider = Provider.of<BadgeProvider>(
          context,
          listen: false,
        );
        // Check badges NOW that withdrawal is approved
        final newBadges = await badgeProvider.checkAndAwardBadges();

        if (newBadges.isNotEmpty && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => BadgeCelebrationDialog(newBadges: newBadges),
          );
        }
      } catch (e) {
        debugPrint('[WithdrawalScreen] Badge check error: $e');
      }
      // -------------------------------

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 40,
            ),
          ),
          title: const Text(
            'Penarikan Berhasil!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Penarikan sebesar ${_currencyFormat.format(amount)} telah diproses.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Kembali ke dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
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

  Future<void> _showProcessingDialog() async {
    int secondsRemaining = 5;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Start countdown timer
          Future.delayed(const Duration(seconds: 1), () {
            if (secondsRemaining > 0) {
              setDialogState(() => secondsRemaining--);
            }
          });

          // Auto-close when timer reaches 0
          if (secondsRemaining <= 0) {
            Future.microtask(() => Navigator.pop(ctx));
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade100.withOpacity(0.3),
                        Colors.green.shade50.withOpacity(0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Memproses Penarikan...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
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
            WithdrawalHeader(isDarkMode: isDarkMode),

            // Overflow Title Override (if from overflow)
            if (widget.fromOverflow)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Theme.of(context).cardTheme.color,
                child: const Center(
                  child: Text(
                    'Tarik Dana Overflow',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

            // Tab Bar
            Container(
              color: Theme.of(context).cardTheme.color,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.green.shade700,
                indicatorWeight: 3,
                labelColor: Colors.green.shade700,
                unselectedLabelColor: isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Request Penarikan'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Request Form
                  _buildRequestTab(isDarkMode),

                  // Tab 2: History
                  _buildHistoryTab(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header widget now extracted to WithdrawalHeader widget file

  Widget _buildRequestTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner (Overflow) or Total Savings (Normal)
            if (widget.fromOverflow)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dana dari goal yang telah selesai',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tabungan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(_totalSavings),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Goal Selection
            Text(
              'Pilih Sumber Dana',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Consumer2<GoalProvider, AuthProvider>(
              builder: (context, goalProvider, authProvider, _) {
                final goals = goalProvider.goals;
                final availableBalance =
                    authProvider.user?.availableBalance ?? 0;

                return DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value:
                      (goals.any((g) => g.id == _selectedGoalId) ||
                          _selectedGoalId == null)
                      ? _selectedGoalId
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Pilih sumber dana',
                    prefixIcon: Icon(
                      Icons.savings_outlined,
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
                  items: [
                    // Available Balance Option
                    DropdownMenuItem<int?>(
                      value: null, // null represents Available Balance
                      child: Text(
                        '📦 Saldo Akun (${_currencyFormat.format(availableBalance)})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Goal Options
                    ...goals
                        .fold<Map<int, dynamic>>({}, (map, goal) {
                          map[goal.id] = goal;
                          return map;
                        })
                        .values
                        .map((goal) {
                          return DropdownMenuItem<int?>(
                            value: goal.id,
                            child: Text(
                              '${goal.name} (${_currencyFormat.format(goal.currentAmount)})',
                            ),
                          );
                        })
                        .toList(),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedGoalId = val;
                      if (val == null) {
                        _selectedGoalBalance = availableBalance;
                        if (_selectedMethod == 'manual')
                          _selectedMethod = 'dana';
                      } else {
                        final selectedIndex = goals.indexWhere(
                          (g) => g.id == val,
                        );
                        if (selectedIndex != -1) {
                          final selectedGoal = goals[selectedIndex];
                          _selectedGoalBalance = selectedGoal.currentAmount;
                          if (selectedGoal.type == 'cash') {
                            _selectedMethod = 'manual';
                          } else if (_selectedMethod == 'manual') {
                            _selectedMethod = 'dana';
                          }
                        }
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Selected Goal Balance Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.green.shade900.withOpacity(0.3)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saldo Tersedia: ${_currencyFormat.format(_selectedGoalBalance)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Withdrawal Method
            Text(
              'Metode Penarikan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            // Method Dropdown filtered by Goal Type
            Builder(
              builder: (context) {
                // Calculate allowed methods
                final allowedMethods = _methodIcons.keys.where((m) {
                  if (_selectedGoalId == null) return m != 'manual';
                  try {
                    final goal = Provider.of<GoalProvider>(
                      context,
                      listen: false,
                    ).goals.firstWhere((g) => g.id == _selectedGoalId);
                    if (goal.type == 'cash') return m == 'manual';
                    return m != 'manual';
                  } catch (e) {
                    return true;
                  }
                }).toList();

                return DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: InputDecoration(
                    hintText: 'Pilih metode penarikan',
                    prefixIcon: Icon(
                      _methodIcons[_selectedMethod] ?? Icons.payment,
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
                  items: allowedMethods.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          Icon(_methodIcons[m], size: 20),
                          const SizedBox(width: 12),
                          Text(m.toUpperCase().replaceAll('_', ' ')),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                );
              },
            ),
            const SizedBox(height: 20),

            // Account Number
            Text(
              'Nomor Rekening / E-Wallet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountCtrl,
              decoration: InputDecoration(
                hintText: 'Masukkan nomor rekening atau e-wallet',
                prefixIcon: Icon(
                  Icons.credit_card_rounded,
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
              validator: (val) =>
                  val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 20),

            // Amount
            CurrencyInputField(
              label: 'Jumlah Penarikan',
              controller: _amountCtrl,
              isDarkMode: isDarkMode,
              enabled: !widget.fromOverflow, // Disable if from overflow
              validator: Validators.validateAmount,
            ),
            const SizedBox(height: 20),

            // Notes
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
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
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
                        child: CircularProgressIndicator(color: Colors.white),
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
                            color: Colors.green.shade200.withOpacity(0.5),
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
                          'Kirim Permintaan Penarikan',
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
    );
  }

  // History widget now extracted to WithdrawalHistoryList widget file
  Widget _buildHistoryTab(bool isDarkMode) {
    return WithdrawalHistoryList(isDarkMode: isDarkMode);
  }
}

// CurrencyInputField widget extracted to: lib/widgets/currency_input_field.dart
// WithdrawalHeader widget extracted to: lib/widgets/withdrawal_header.dart
// WithdrawalHistoryList widget extracted to: lib/widgets/withdrawal_history_list.dart
