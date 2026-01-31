import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'onboarding_screen.dart';

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

  Future<void> _checkNavigation() async {
    // 1. Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 2. Check SharedPreferences for Onboarding
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
       // Is First Time -> Go to Onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
    } else {
        // Not First Time -> Go to Normal Auth Flow
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.checkLoginStatus(); 

        if (!mounted) return;

        if (authProvider.isAuthenticated) {
           Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
           );
        } else {
           Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
           );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container (same as Withdrawal Navbar)
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
                    color: Colors.green.shade200,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            // Text Logo
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
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
