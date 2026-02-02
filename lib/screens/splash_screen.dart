import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'onboarding_screen.dart';

/// Layar Splash Screen yang muncul saat aplikasi pertama kali dibuka.
/// Berfungsi untuk memuat logo dan melakukan pengecekan status login serta onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  /// Mengecek status navigasi awal:
  /// 1. Apakah user baru pertama kali install? -> Onboarding
  /// 2. Apakah user sudah login? -> Dashboard
  /// 3. Apakah user belum login? -> Login Screen
  Future<void> _checkNavigation() async {
    // 1. Tunggu 3 detik agar logo terlihat (simulasi loading)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 2. Cek SharedPreferences untuk status Onboarding
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding =
        prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      // Jika baru pertama kali, arahkan ke Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      // Jika sudah pernah onboarding, cek status login
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkLoginStatus();

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        // Jika token valid, masuk ke Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // Jika token tidak ada/expired, masuk ke Login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.green.shade200,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            // Nama Aplikasi
            const Text(
              'GoalMoney',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.lightGreen,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Slogan
            Text(
              'Wujudkan Impianmu',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            // Indikator Loading
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.lightGreen : Colors.green.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
