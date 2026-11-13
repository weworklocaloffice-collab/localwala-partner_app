/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Payload routing happens in-app; the OS notification is raised by
  // `LocalNotificationService.showNotification` when the app is foregrounded.
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Routes notification taps. Set from `main.dart` so the service can open a
  /// screen without a BuildContext - it has none of its own.
  static void Function(String? payload)? onTap;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onTap?.call(response.payload);
      },
    );

    const AndroidNotificationChannel jhatkaChannel = AndroidNotificationChannel(
      'jhatka_partner',
      'Jhatka alerts',
      description: 'New orders, stock and compliance alerts',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(jhatkaChannel);
  }

  static Future<void> showNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    final bool isJhatka = message.data['vertical'] == 'jhatka';
    await _plugin.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: notification.title ?? '',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          isJhatka ? 'jhatka_partner' : 'dairy_delivery',
          isJhatka ? 'Jhatka alerts' : 'Dairy delivery',
          channelDescription: isJhatka
              ? 'New orders, stock and compliance alerts'
              : 'Run assignment and stop alerts',
          importance: isJhatka ? Importance.max : Importance.defaultImportance,
          priority: isJhatka ? Priority.high : Priority.defaultPriority,
          category: AndroidNotificationCategory.message,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // The data map is what routes a tap. Without it every notification tap
      // could only reopen the app shell.
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }
}
