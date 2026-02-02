import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/badge_celebration_dialog.dart';
import '../../core/photo_storage_service.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/deadline_picker_field.dart';

/// Layar untuk menambahkan goal baru.
/// Pengguna dapat memasukkan nama, target jumlah, tipe goal, deadline, deskripsi, dan foto goal.
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'digital'; // Tipe default
  bool _isLoading = false;
  String? _goalPhotoPath;
  DateTime? _selectedDeadline;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayDateFormat = DateFormat('dd MMM yyyy');

  /// Memilih foto goal dari galeri atau kamera.
  Future<void> _pickGoalPhoto() async {
    try {
      final photoPath = await PhotoStorageService.pickAndSaveGoalPhoto(0);
      if (photoPath != null && mounted) {
        setState(() => _goalPhotoPath = photoPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto goal berhasil ditambahkan'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Memilih tanggal deadline menggunakan DatePicker.
  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    // Default deadline 30 hari dari sekarang jika belum dipilih
    final initialDate = _selectedDeadline ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)), // Maksimal 10 tahun
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              primary: Colors.green.shade700,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() => _selectedDeadline = picked);
    }
  }

  /// Menangani proses submit form tambah goal.
  /// Melakukan validasi input, pemanggilan API, dan pengecekan badge.
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Parse target amount dari format currency string ke double
      final target = double.parse(
        _targetCtrl.text.replaceAll(RegExp('[^0-9]'), ''),
      );
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);

      // Buat goal baru dan dapatkan ID goal baru
      final newGoalId = await goalProvider.createGoal(
        name: _nameCtrl.text,
        targetAmount: target,
        deadline: _selectedDeadline != null
            ? _dateFormat.format(_selectedDeadline!)
            : null,
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
        type: _selectedType,
      );

      // Setelah goal dibuat, pindahkan foto dari temp (ID 0) ke ID goal baru
      if (_goalPhotoPath != null && newGoalId != null) {
        await PhotoStorageService.moveGoalPhoto(0, newGoalId);
        // Refresh data goal untuk memastikan foto terambil.
        await goalProvider.fetchGoals();
      }

      // --- CEK BADGE BARU ---
      // Cek apakah pembuatan goal ini memicu perolehan badge baru.
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
        print('[AddGoalScreen] Badge check error: $e');
      }
      // -------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal berhasil dibuat!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat goal: ${e.toString()}'),
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
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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

            // Konten Utama Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Judul Halaman
                      Text(
                        'Buat Goal Baru 🎯',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tetapkan target tabungan Anda',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bagian Foto Goal
                      Center(
                        child: _GoalPhotoPicker(
                          photoPath: _goalPhotoPath,
                          onTap: _pickGoalPhoto,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Nama Goal
                      _InputField(
                        label: 'Nama Goal',
                        controller: _nameCtrl,
                        hint: 'Contoh: Laptop Baru, Liburan, dll',
                        icon: Icons.flag_rounded,
                        isDarkMode: isDarkMode,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama goal tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Input Target Jumlah
                      CurrencyInputField(
                        label: 'Target Jumlah',
                        controller: _targetCtrl,
                        isDarkMode: isDarkMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Target jumlah tidak boleh kosong';
                          }
                          final numericValue = value.replaceAll(
                            RegExp('[^0-9]'),
                            '',
                          );
                          if (numericValue.isEmpty ||
                              int.parse(numericValue) <= 0) {
                            return 'Target harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Dropdown Tipe Goal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipe Tabungan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDarkMode
                                  ? Colors.grey.shade800.withOpacity(0.3)
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              isExpanded: true, // Fix overflow text
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.category_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'digital',
                                  child: Text(
                                    'Tabungan Digital (E-Wallet/Bank)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'cash',
                                  child: Text(
                                    'Celengan Tunai (Uang Fisik)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedType = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Input Deadline (Optional)
                      DeadlinePickerField(
                        selectedDate: _selectedDeadline,
                        displayFormat: _displayDateFormat,
                        isDarkMode: isDarkMode,
                        onTap: _selectDeadline,
                        onClear: () => setState(() => _selectedDeadline = null),
                      ),
                      const SizedBox(height: 20),

                      // Input Deskripsi (Optional)
                      _InputField(
                        label: 'Deskripsi (Opsional)',
                        controller: _descCtrl,
                        hint: 'Tambahkan deskripsi goal Anda...',
                        icon: Icons.description_outlined,
                        isDarkMode: isDarkMode,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 32),

                      // Tombol Submit (Buat Goal)
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
                                      color: Colors.green.shade200.withOpacity(
                                        0.5,
                                      ),
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
                                    'Buat Goal',
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

class _GoalPhotoPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onTap;

  const _GoalPhotoPicker({
    Key? key,
    required this.photoPath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: !hasPhoto
              ? LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade200.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          image: hasPhoto
              ? DecorationImage(
                  image: FileImage(File(photoPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: !hasPhoto
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tambah Foto\nGoal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade500,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDarkMode;
  final String? prefixText;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _InputField({
    Key? key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDarkMode,
    this.prefixText,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: Icon(icon, color: Colors.lightGreen.shade700),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

/// Currency Input Field with proper placeholder behavior
/// - Unfocused + empty: Shows "Contoh: Rp 1.000.000"
/// - Focused: Shows "Rp " prefix with formatted value
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
              Icons.attach_money_rounded,
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
