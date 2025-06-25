// File: lib/services/firebase_api.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Call this in main after login to register token
  Future<void> initNotifications(String uid) async {
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': fcmToken,
      });
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final android = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final platform = NotificationDetails(android: android);
    _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platform,
    );
  }

  // Send notification to another user
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    final data = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
    };

    const serverKey = 'BLmXgfZR-9syjpfWC5fere5Nu6u6NKq_bZcZdQIf15pS1_uaDSxaRWMieoBw_6YEloOHra5Q45yEfpMcpu6Yvl4'; // replace with real key

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(data),
    );
  }
}
