import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../core/validators.dart';

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
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'manual', 'name': 'Manual Cash', 'asset': null, 'icon': Icons.money},
    {'id': 'dana', 'name': 'DANA', 'asset': 'assets/images/dana.png', 'icon': Icons.account_balance_wallet},
    {'id': 'gopay', 'name': 'GoPay', 'asset': 'assets/images/gopay.png', 'icon': Icons.account_balance_wallet},
    {'id': 'ovo', 'name': 'OVO', 'asset': 'assets/images/ovo.png', 'icon': Icons.account_balance_wallet},
    {'id': 'shopeepay', 'name': 'ShopeePay', 'asset': 'assets/images/shopeepay.png', 'icon': Icons.account_balance_wallet},
    {'id': 'bank_transfer', 'name': 'Bank Transfer', 'asset': 'assets/images/bank_transfer.png', 'icon': Icons.account_balance},
  ];

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(
        _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
      );

      await Provider.of<GoalProvider>(context, listen: false).addTransaction(
        goalId: widget.goalId,
        amount: amount,
        method: _selectedMethod,
        description:
            _descCtrl.text.isNotEmpty
                ? _descCtrl.text
                : 'Deposit via ${_paymentMethods.firstWhere((m) => m['id'] == _selectedMethod)['name']}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil menabung! 💰'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh goal list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menabung: ${widget.goalName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Amount Input
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nominal Tabungan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 16),

              // Method Selection
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Sumber Dana',
                  border: OutlineInputBorder(),
                ),
                items:
                    _paymentMethods.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['id'] as String,
                        child: Row(
                          children: [
                            if (m['asset'] != null)
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 8),
                                child: Image.asset(
                                  m['asset'],
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      m['icon'],
                                      color: Colors.blue,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  m['icon'],
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                            Text(m['name']),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Misal: Sisa uang jajan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan Tabungan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
