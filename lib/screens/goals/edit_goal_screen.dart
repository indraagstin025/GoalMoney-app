import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/goal.dart';
import '../../providers/goal_provider.dart';
import '../../core/photo_storage_service.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _descCtrl;
  bool _isLoading = false;
  String? _goalPhotoPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.goal.name);
    _targetCtrl = TextEditingController(
      text: widget.goal.targetAmount.toString(),
    );
    _descCtrl = TextEditingController(text: widget.goal.description ?? '');
    _goalPhotoPath = widget.goal.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGoalPhoto() async {
    try {
      final photoPath = await PhotoStorageService.pickAndSaveGoalPhoto(
        widget.goal.id,
      );
      if (photoPath != null && mounted) {
        setState(() => _goalPhotoPath = photoPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto produk berhasil diubah')),
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
      final target = double.parse(_targetCtrl.text);
      await Provider.of<GoalProvider>(context, listen: false).updateGoal(
        id: widget.goal.id,
        name: _nameCtrl.text,
        targetAmount: target,
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update goal')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Goal')),
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
                              'Ubah Foto',
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
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Goal'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
