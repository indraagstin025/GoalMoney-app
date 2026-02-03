import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/validators.dart';
import '../../widgets/password_skeleton.dart';

/// Layar untuk mengubah password pengguna.
/// Memerlukan verifikasi password lama sebelum menetapkan password baru.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  /// Menangani proses submit ubah password.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak cocok'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updatePassword(_oldPassCtrl.text, _newPassCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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
            _buildHeader(context, isDarkMode),

            // Content
            Expanded(
              child: _isInitializing
                  ? const PasswordSkeleton()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ubah Password 🔐',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gunakan password yang kuat untuk keamanan akun Anda',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Password Lama
                            _buildPasswordField(
                              label: 'Password Saat Ini',
                              controller: _oldPassCtrl,
                              obscureText: _obscureOld,
                              onToggle: () =>
                                  setState(() => _obscureOld = !_obscureOld),
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 20),

                            // Password Baru
                            _buildPasswordField(
                              label: 'Password Baru',
                              controller: _newPassCtrl,
                              obscureText: _obscureNew,
                              onToggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              isDarkMode: isDarkMode,
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 20),

                            // Konfirmasi Password
                            _buildPasswordField(
                              label: 'Konfirmasi Password Baru',
                              controller: _confirmPassCtrl,
                              obscureText: _obscureConfirm,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 40),

                            // Submit Button
                            _buildSubmitButton(),
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

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Keamanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required bool isDarkMode,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade700),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDarkMode
                ? Colors.grey.shade800.withOpacity(0.3)
                : Colors.grey.shade50,
          ),
          validator:
              validator ??
              (value) => value == null || value.isEmpty
                  ? 'Field ini wajib diisi'
                  : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: _isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
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
                  colors: [Colors.green.shade700, Colors.green.shade500],
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
                  'Perbarui Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }
}
