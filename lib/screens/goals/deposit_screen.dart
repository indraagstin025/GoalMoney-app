import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/validators.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/badge_celebration_dialog.dart';
import '../../widgets/overflow_allocation_dialog.dart';
import '../../widgets/deposit_form_skeleton.dart';

/// Layar untuk menambahkan tabungan (deposit) ke dalam goal.
/// Mendukung berbagai metode pembayaran dan menangani skenario goal tercapai atau overflow.
class DepositScreen extends StatefulWidget {
  final int goalId;
  final String goalName;

  const DepositScreen({Key? key, required this.goalId, required this.goalName})
    : super(key: key);

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedMethod = 'manual';
  // Daftar metode pembayaran yang tersedia
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
    'gopay': {'name': 'GoPay', 'icon': Icons.payment, 'color': Colors.green},
    'ovo': {'name': 'OVO', 'icon': Icons.wallet, 'color': Colors.purple},
    'shopeepay': {
      'name': 'ShopeePay',
      'icon': Icons.shopping_bag,
      'color': Colors.orange,
    },
    'pospay': {
      'name': 'POSPAY',
      'icon': Icons.local_post_office_rounded,
      'color': Colors.deepOrange,
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

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Simulasi inisialisasi singkat untuk menampilkan skeleton loading
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Memproses deposit tabungan.
  /// Memvalidasi input, mengirim request deposit, dan menangani respons (termasuk overflow).
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // PENGECEKAN REDUNDAN: Pastikan goal belum tercapai sebelum deposit
      final goal = Provider.of<GoalProvider>(
        context,
        listen: false,
      ).goals.firstWhere((g) => g.id == widget.goalId);

      if (goal.isCompleted) {
        throw Exception(
          'Goal ini sudah selesai dan tidak dapat menerima tabungan lagi.',
        );
      }

      final amount = double.parse(
        _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
      );

      // UPDATED: Sekarang menerima informasi overflow dari provider
      final result = await Provider.of<GoalProvider>(context, listen: false)
          .addTransaction(
            goalId: widget.goalId,
            amount: amount,
            method: _selectedMethod,
            description: _descCtrl.text.isNotEmpty
                ? _descCtrl.text
                : 'Deposit via ${_paymentMethods[_selectedMethod]!['name']}',
          );

      if (!mounted) return;

      // UPDATED: Cek apakah ada overflow (kelebihan bayar)
      if (result['overflow_amount'] != null && result['overflow_amount'] > 0) {
        // Goal tercapai dengan overflow
        Navigator.pop(context, true); // Tutup layar deposit terlebih dahulu

        // Tampilkan dialog alokasi overflow
        showOverflowAllocationDialog(
          context: context,
          overflowAmount: result['overflow_amount'].toDouble(),
          completedGoalName: widget.goalName,
          sourceMethod: _selectedMethod,
        );
      } else {
        // Deposit normal tanpa overflow
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

        // --- BARU: Pemicu Pengecekan Badge (Lencana) ---
        try {
          final badgeProvider = Provider.of<BadgeProvider>(
            context,
            listen: false,
          );
          final newBadges = await badgeProvider.checkAndAwardBadges();

          if (newBadges.isNotEmpty && mounted) {
            // Tampilkan dialog perayaan badge jika ada badge baru yang diraih
            // atau tampilkan dan kemudian pop. Terbaik untuk menampilkannya di konteks induk jika popping.
            // Tapi untuk sekarang, mari kita tampilkan lalu pop saat ditutup.
            if (mounted) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    BadgeCelebrationDialog(newBadges: newBadges),
              );
            }
          }
        } catch (badgeError) {
          print('[DepositScreen] Error triggering badge check: $badgeError');
        }
        // -------------------------------

        if (mounted) Navigator.pop(context, true);
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
            // Header Kustom
            const _CustomHeader(),

            // Konten Utama
            Expanded(
              child: _isInitializing
                  ? const DepositFormSkeleton()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // Judul
                            Text(
                              'Tambah Tabungan 💰',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
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

                            // Field Nominal
                            CurrencyInputField(
                              label: 'Nominal Tabungan',
                              controller: _amountCtrl,
                              isDarkMode: isDarkMode,
                              validator: Validators.validateAmount,
                            ),
                            const SizedBox(height: 20),

                            // Pilihan Sumber Dana
                            Text(
                              'Sumber Dana',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final goals = Provider.of<GoalProvider>(
                                  context,
                                ).goals;

                                // Safety check: jika goals sedang direfresh atau kosong
                                if (goals.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                // Cari goal dengan aman
                                final goalIndex = goals.indexWhere(
                                  (g) => g.id == widget.goalId,
                                );
                                if (goalIndex == -1) {
                                  // Jika goal tidak ditemukan (misal dihapus atau sesi berubah)
                                  return const Center(
                                    child: Text('Goal tidak ditemukan'),
                                  );
                                }

                                final goal = goals[goalIndex];
                                print(
                                  'DEBUG: DepositScreen Goal: ${goal.name}, Type: ${goal.type}, ID: ${goal.id}',
                                );
                                final isCashGoal = goal.type == 'cash';

                                // Filter metode pembayaran yang sesuai
                                final allowedMethods = _paymentMethods.entries
                                    .where((entry) {
                                      if (isCashGoal) {
                                        return entry.key == 'manual';
                                      } else {
                                        // Goal digital: izinkan semua KECUALI manual
                                        return entry.key != 'manual';
                                      }
                                    })
                                    .where((entry) {
                                      // Cek saldo jika sumber dana adalah 'balance'
                                      if (entry.key == 'balance') {
                                        final user = Provider.of<AuthProvider>(
                                          context,
                                        ).user;
                                        return user != null &&
                                            user.availableBalance > 0;
                                      }
                                      return true;
                                    })
                                    .toList();

                                // Pastikan metode yang dipilih valid
                                // Kita tidak bisa update state di sini, jadi kita pilih nilai tampilan
                                String displaySelected = _selectedMethod;
                                bool isValid = allowedMethods.any(
                                  (e) => e.key == _selectedMethod,
                                );

                                if (!isValid && allowedMethods.isNotEmpty) {
                                  displaySelected = allowedMethods.first.key;
                                  // Jadwalkan update state untuk mensinkronkan variabel
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_selectedMethod != displaySelected) {
                                      setState(
                                        () => _selectedMethod = displaySelected,
                                      );
                                    }
                                  });
                                }

                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: displaySelected,
                                  decoration: InputDecoration(
                                    hintText: 'Pilih sumber dana',
                                    prefixIcon: Icon(
                                      _paymentMethods[displaySelected]?['icon'] ??
                                          Icons.payment,
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
                                      final user = Provider.of<AuthProvider>(
                                        context,
                                      ).user;
                                      if (user != null) {
                                        name +=
                                            ' (${_currencyFormat.format(user.availableBalance)})';
                                      }
                                    }

                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  (entry.value['color']
                                                          as Color)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              entry.value['icon'],
                                              color: entry.value['color'],
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedMethod = val!),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Field Catatan (Opsional)
                            Text(
                              'Catatan (Opsional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
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

                            // Tombol Simpan Tabungan
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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

/// Header kustom sederhana.
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
          // Logo GoalMoney
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

          // Tombol Kembali
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Input field khusus mata uang dengan format Rupiah otomatis.
class CurrencyInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isDarkMode;
  final String? Function(String?)? validator;

  const CurrencyInputField({
    Key? key,
    required this.label,
    required this.controller,
    required this.isDarkMode,
    this.validator,
  }) : super(key: key);

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _formatCurrency(String value) {
    if (value.isEmpty) return;

    final numericValue = value.replaceAll(RegExp('[^0-9]'), '');
    if (numericValue.isNotEmpty) {
      final formatted = _currencyFormat.format(int.parse(numericValue));
      final cleanText = formatted.replaceAll('Rp ', '').trim();
      widget.controller.value = TextEditingValue(
        text: cleanText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: cleanText.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    final showPrefix = _isFocused || hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: showPrefix ? '' : 'Contoh: Rp 1.000.000',
            hintStyle: TextStyle(
              color: widget.isDarkMode
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            prefixText: showPrefix ? 'Rp ' : null,
            prefixStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.payments_rounded,
              color: _isFocused ? Colors.lightGreen.shade700 : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode
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
            fillColor: widget.isDarkMode
                ? Colors.grey.shade800.withOpacity(0.3)
                : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          onChanged: _formatCurrency,
          validator: widget.validator,
        ),
      ],
    );
  }
}
