import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';
import '../../core/photo_storage_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;
  String? _goalPhotoPath;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> _pickGoalPhoto() async {
    try {
      final photoPath = await PhotoStorageService.pickAndSaveGoalPhoto(0);
      if (photoPath != null && mounted) {
        setState(() => _goalPhotoPath = photoPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto produk berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _submit() async {
    if (_nameCtrl.text.isEmpty || _targetCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final target = double.parse(
        _targetCtrl.text.replaceAll(RegExp('[^0-9]'), ''),
      );
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);

      // Create goal and get the new goal ID
      final newGoalId = await goalProvider.createGoal(
        name: _nameCtrl.text,
        targetAmount: target,
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      );

      print('[AddGoal] New goal ID returned: $newGoalId');

      // After goal is created, move the photo from goal_0 to the new goal ID
      if (_goalPhotoPath != null && newGoalId != null) {
        print('[AddGoal] Moving photo for goal $newGoalId');
        await PhotoStorageService.moveGoalPhoto(0, newGoalId);
        print('[AddGoal] Photo moved successfully');

        // Fetch goals again to reload photo paths
        await Future.delayed(const Duration(milliseconds: 300));
        await goalProvider.fetchGoals();
        print('[AddGoal] Goals refetched with new photo path');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print('[AddGoal] Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create goal')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Photo Preview
              GestureDetector(
                onTap: _pickGoalPhoto,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    image:
                        _goalPhotoPath != null &&
                            File(_goalPhotoPath!).existsSync()
                        ? DecorationImage(
                            image: FileImage(File(_goalPhotoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      _goalPhotoPath != null &&
                          File(_goalPhotoPath!).existsSync()
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambah Foto',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Goal Name (e.g. New Laptop)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetCtrl,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) return;
                  final numericValue = value.replaceAll(RegExp('[^0-9]'), '');
                  if (numericValue.isNotEmpty) {
                    final formatted = _currencyFormat.format(
                      int.parse(numericValue),
                    );
                    final cleanText = formatted.replaceAll('Rp ', '').trim();
                    _targetCtrl.value = TextEditingValue(
                      text: cleanText,
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: cleanText.length),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Create Goal'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
