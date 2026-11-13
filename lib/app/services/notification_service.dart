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

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// FCM topic subscription.
///
/// A rider or partner may hold both roles, so they subscribe to both topics and
/// the role gate decides how to route each payload.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging}) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  static const String partnerTopic = 'dairy_partner';
  static const String driverTopic = 'dairy_driver';

  Future<String?> deviceToken() async {
    if (kIsWeb) return null;
    return _messaging.getToken();
  }

  Future<void> subscribeAll() async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic(partnerTopic);
    await _messaging.subscribeToTopic(driverTopic);
  }

  Stream<RemoteMessage> get onMessage {
    if (kIsWeb) return const Stream<RemoteMessage>.empty();
    return FirebaseMessaging.onMessage;
  }

  Stream<RemoteMessage> get onMessageOpenedApp {
    if (kIsWeb) return const Stream<RemoteMessage>.empty();
    return FirebaseMessaging.onMessageOpenedApp;
  }

  /// The payload key the API uses to tell the app which shell to open.
  static const String payloadRole = 'role';
  static const String payloadRunId = 'runId';

  static String? roleFrom(RemoteMessage message) => message.data[payloadRole];

  static String? runIdFrom(RemoteMessage message) => message.data[payloadRunId];
}