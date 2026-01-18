import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../core/validators.dart';
import '../../models/goal.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String _selectedMethod = 'dana';
  final List<String> _methods = ['dana', 'gopay', 'bank_transfer', 'ovo', 'shopeepay'];
  
  bool _isLoading = false;
  double _totalSavings = 0;
  
  // Goal selection
  int? _selectedGoalId;
  double _selectedGoalBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    try {
      print('[WithdrawalScreen] Fetching data...');
      final provider = Provider.of<GoalProvider>(context, listen: false);
      await provider.fetchDashboardSummary();
      await provider.fetchGoals();
      
      if (provider.summary != null && mounted) {
        print('[WithdrawalScreen] Summary: ${provider.summary}');
        setState(() {
          final total = provider.summary!['total_saved'];
          _totalSavings = (total is num) ? total.toDouble() : 0.0;
          
          // Auto-select first goal if available
          if (provider.goals.isNotEmpty) {
            _selectedGoalId = provider.goals.first.id;
            _selectedGoalBalance = provider.goals.first.currentAmount;
          }
        });
      }
    } catch (e) {
      print('[WithdrawalScreen] Error loading data: $e');
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedGoalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih goal terlebih dahulu'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      
      // Validasi saldo goal yang dipilih
      if (amount > _selectedGoalBalance) {
        throw Exception('Saldo goal tidak mencukupi');
      }

      // Send withdrawal request to backend with goalId
      await Provider.of<GoalProvider>(context, listen: false).requestWithdrawal(
        goalId: _selectedGoalId!,
        amount: amount,
        method: _selectedMethod,
        accountNumber: _accountCtrl.text,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );
      
      if (!mounted) return;
      
      // Show processing dialog with countdown
      await _showProcessingDialog();
      
      if (!mounted) return;
      
      // After waiting, refresh history to trigger auto-approval check
      await Provider.of<GoalProvider>(context, listen: false).fetchWithdrawalHistory();
      await Provider.of<GoalProvider>(context, listen: false).fetchDashboardSummary();
      
      if (!mounted) return;
      
      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text('Penarikan Berhasil!'),
          content: Text('Penarikan sebesar Rp ${_formatcurrency(amount)} telah diproses.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Kembali ke dashboard
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showProcessingDialog() async {
    int secondsRemaining = 30;
    
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 24),
                const Text(
                  'Memproses Penarikan...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Harap tunggu ${secondsRemaining} detik',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (30 - secondsRemaining) / 30,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tarik Saldo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Request'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Request Form
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Saldo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.blue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Tabungan', style: TextStyle(color: Colors.grey)),
                              Text(
                                'Rp ${_formatcurrency(_totalSavings)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Goal Selection Dropdown
                    Consumer<GoalProvider>(
                      builder: (context, goalProvider, _) {
                        final goals = goalProvider.goals;
                        return DropdownButtonFormField<int>(
                          value: _selectedGoalId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Goal untuk Ditarik',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.savings),
                          ),
                          items: goals.map((goal) {
                            return DropdownMenuItem(
                              value: goal.id,
                              child: Text('${goal.name} (Rp ${_formatcurrency(goal.currentAmount)})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGoalId = val;
                              // Update selected goal balance
                              final selectedGoal = goals.firstWhere((g) => g.id == val);
                              _selectedGoalBalance = selectedGoal.currentAmount;
                            });
                          },
                          validator: (val) => val == null ? 'Pilih goal' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Selected Goal Balance Info
                    if (_selectedGoalId != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo Goal: Rp ${_formatcurrency(_selectedGoalBalance)}',
                              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Form Input - Method Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Metode Penarikan',
                        border: OutlineInputBorder(),
                      ),
                      items: _methods.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.toUpperCase().replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedMethod = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _accountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Rekening / E-Wallet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Penarikan',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading 
                            ? const CircularProgressIndicator() 
                            : const Text('Kirim Permintaan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab 2: History
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder(
      future: Provider.of<GoalProvider>(context, listen: false).fetchWithdrawalHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Consumer<GoalProvider>(
          builder: (context, provider, child) {
            final withdrawals = provider.withdrawals;
            
            if (withdrawals.isEmpty) {
              return const Center(child: Text('Belum ada riwayat penarikan'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: withdrawals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = withdrawals[index];
                Color statusColor;
                switch (item.status) {
                  case 'approved': statusColor = Colors.green; break;
                  case 'rejected': statusColor = Colors.red; break;
                  default: statusColor = Colors.orange;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'Rp ${_formatcurrency(item.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Method: ${item.method.toUpperCase().replaceAll('_', ' ')}'),
                        Text(
                          'Tanggal: ${item.createdAt}', // Assuming formatted date string
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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
  
  String _formatcurrency(double amount) {
    // Simple formatter, use intl package in production
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }
}
