import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/notifications/notification_screen.dart';
import '../main.dart';
import 'local_notification_service.dart'; // Import Local Notification Service

/// Layanan untuk mengelola Firebase Cloud Messaging (FCM) dan Push Notifications.
/// Mendukung penerimaan pesan di foreground, background, dan saat aplikasi ditutup.
class FcmService {
  // Pattern Singleton untuk memastikan hanya ada satu instance layanan FCM.
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Menginisialisasi layanan notifikasi untuk user tertentu.
  Future<void> initialize(int userId) async {
    // 1. Inisialisasi Layanan Notifikasi Lokal untuk menampilkan banner notifikasi di sistem.
    await LocalNotificationService.initialize();

    // 2. Meminta izin (Permission) notifikasi kepada user (terutama di iOS dan Android 13+).
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[FCM] User memberikan izin notifikasi');
    } else {
      print('[FCM] User menolak atau belum memberikan izin notifikasi');
      return;
    }

    // 3. Berlangganan (Subscribe) ke topik berdasarkan ID User.
    // Ini memungkinkan pengiriman notifikasi spesifik ke user tertentu dari server.
    await _fcm.subscribeToTopic('user_$userId');
    print('[FCM] Berlangganan ke topik: user_$userId');

    // 4. Menangani pesan saat aplikasi sedang terbuka (Foreground State).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🚀 Mendapat pesan baru saat di foreground!');

      if (message.notification != null) {
        // Menampilkan notifikasi sistem menggunakan LocalNotificationService.
        LocalNotificationService.showNotification(message);
      }
    });

    // 5. Menangani klik notifikasi saat aplikasi di background (Background State).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 Notifikasi diklik dari background!');
      // Arahkan user ke layar notifikasi.
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => NotificationScreen()),
      );
    });

    // 6. Menangani notifikasi saat aplikasi benar-benar tertutup (Terminated State).
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 Aplikasi dibuka dari kondisi tertutup melalui notifikasi!');
        // Beri jeda sedikit agar inisialisasi aplikasi selesai sebelum berpindah halaman.
        Future.delayed(const Duration(seconds: 1), () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => NotificationScreen()),
          );
        });
      }
    });
  }

  /// Berhenti berlangganan dari topik notifikasi user (saat logout).
  Future<void> unsubscribe(int userId) async {
    await _fcm.unsubscribeFromTopic('user_$userId');
    print('[FCM] Berhenti berlangganan dari topik: user_$userId');
  }
}
