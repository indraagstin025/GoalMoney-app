import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Layanan untuk mengelola notifikasi lokal (Local Notifications).
/// Digunakan untuk menampilkan notifikasi sistem saat aplikasi sedang berjalan di foreground
/// atau saat menerima data payload notifikasi dari FCM.
class LocalNotificationService {
  /// Instance plugin FlutterLocalNotifications.
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Menginisialisasi pengaturan notifikasi lokal untuk Android dan iOS.
  static Future<void> initialize() async {
    // Pengaturan inisialisasi Android (icon default).
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan inisialisasi iOS (meminta izin alert, badge, dan sound).
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Menangani aksi saat notifikasi diklik/ditap oleh user.
        print('[LocalNotification] Notifikasi diklik: ${response.payload}');
      },
    );

    // Membuat saluran notifikasi (Notification Channel) khusus untuk Android 8.0+.
    // Channel ini penting agar notifikasi memiliki prioritas tinggi dan suara.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID Channel
      'High Importance Notifications', // Nama Channel yang muncul di pengaturan
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print('[LocalNotification] Berhasil diinisialisasi');
  }

  /// Menampilkan notifikasi lokal berdasarkan pesan RemoteMessage dari FCM.
  static Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Detail pengaturan tampilan notifikasi untuk Android.
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    // Detail pengaturan tampilan notifikasi untuk iOS.
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Menampilkan notifikasi ke sistem bar.
    await _notificationsPlugin.show(
      notification.hashCode, // ID Unik Notifikasi
      notification.title ?? 'Notifikasi',
      notification.body ?? '',
      platformDetails,
      payload: message.data.toString(), // Data tambahan saat notifikasi diklik
    );

    print('[LocalNotification] Ditampilkan: ${notification.title}');
  }
}
