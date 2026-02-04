import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/notifications/notification_screen.dart';

/// Widget header kustom untuk dashboard.
/// Menampilkan logo aplikasi, sapaan user, toggle tema, notifikasi, dan foto profil.
class DashboardHeader extends StatelessWidget {
  /// Data user yang sedang login.
  final dynamic user;
  
  /// Path foto profil lokal (nullable).
  final String? profilePhotoPath;

  const DashboardHeader({
    super.key,
    required this.user,
    this.profilePhotoPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sapaan User
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GoalMoney',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.lightGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hi, ${user?.name ?? "Saver"} 👋',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Aksi Kanan (Theme, Notif, Profile)
          _buildActions(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Row(
        children: [
          // Toggle Theme
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.grey,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          // Notifikasi
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.grey,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          // Foto Profil
          _buildProfilePhoto(),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final hasPhoto = profilePhotoPath != null && 
                     File(profilePhotoPath!).existsSync();
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.shade100, width: 2),
        color: Colors.blue.shade50,
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(profilePhotoPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasPhoto ? null : Icon(Icons.person, color: Colors.blue.shade300),
    );
  }
}
