import 'package:flutter/material.dart' hide Badge;
import '../../models/badge.dart';

/// Dialog perayaan saat pengguna mendapatkan badge baru.
/// Menampilkan satu per satu badge yang diperoleh dengan animasi yang menarik.
class BadgeCelebrationDialog extends StatefulWidget {
  final List<Badge> newBadges;

  const BadgeCelebrationDialog({super.key, required this.newBadges});

  @override
  State<BadgeCelebrationDialog> createState() => _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<BadgeCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller animasi untuk efek muncul (elastic)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _rotationAnimation = Tween<double>(
      begin: -0.2, // Mulai dari sedikit miring
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pindah ke badge berikutnya jika ada, atau tutup dialog jika sudah semua.
  void _nextBadge() {
    if (_currentIndex < widget.newBadges.length - 1) {
      _controller.reverse().then((_) {
        setState(() {
          _currentIndex++;
        });
        _controller.forward();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.newBadges[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efek Cahaya Belakang (Glow)
          Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Konten Utama dengan Animasi Skala dan Rotasi
          ScaleTransition(
            scale: _scaleAnimation,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: Container(
                width: 340,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2),
                      blurRadius: 60,
                      spreadRadius: -10,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teks Header Berkilau (Shiny header)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.amber, Colors.orange, Colors.yellow],
                      ).createShader(bounds),
                      child: const Text(
                        '✨ PENCAPAIAN BARU! ✨',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selamat!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Kontainer Ikon Badge dengan Efek Cincin (Orbit)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cincin Dekoratif
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.1),
                              width: 8,
                            ),
                          ),
                        ),
                        // Cahaya Dalam
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        // Ikon Utama dengan Gradien Emas
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFB900),
                                Color(0xFFFF8C00),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'badge_${badge.code}',
                              child: Text(
                                badge.icon,
                                style: const TextStyle(fontSize: 55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    // Nama Badge
                    Text(
                      badge.name,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Deskripsi Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        badge.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tombol Aksi (Lanjut atau Klaim)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextBadge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentIndex < widget.newBadges.length - 1
                              ? 'LIHAT BERIKUTNYA (${_currentIndex + 1}/${widget.newBadges.length})'
                              : 'KLAIM & LANJUTKAN',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
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
    );
  }
}

/// Fungsi helper untuk menampilkan dialog perayaan badge.
void showBadgeCelebration(BuildContext context, List<Badge> newBadges) {
  if (newBadges.isEmpty) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => BadgeCelebrationDialog(newBadges: newBadges),
  );
}
