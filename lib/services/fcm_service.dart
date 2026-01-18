import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/notifications/notification_screen.dart';
import '../main.dart';
import 'local_notification_service.dart'; // Import Local Notification Service

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize(int userId) async {
    // Initialize Local Notifications first
    await LocalNotificationService.initialize();
    
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[FCM] User granted permission');
    } else {
      print('[FCM] User declined or has not accepted permission');
      return;
    }

    // 2. Subscribe to topic based on User ID
    await _fcm.subscribeToTopic('user_$userId');
    print('[FCM] Subscribed to topic: user_$userId');

    // 3. Handle Foreground Messages - Show System Notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🚀 Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        
        // Show SYSTEM notification in notification bar
        LocalNotificationService.showNotification(message);
      }
    });

    // 4. Handle Background Notification Click (App in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 Notification clicked from background!');
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => NotificationScreen())
      );
    });

    // 5. Handle Terminated State (App closed)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 App opened from terminated state by notification!');
        // Delay to allow app initialization
        Future.delayed(const Duration(seconds: 1), () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => NotificationScreen())
          );
        });
      }
    });
  }

  Future<void> unsubscribe(int userId) async {
    await _fcm.unsubscribeFromTopic('user_$userId');
    print('[FCM] Unsubscribed from topic: user_$userId');
  }
}
