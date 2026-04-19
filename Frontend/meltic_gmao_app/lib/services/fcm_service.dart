import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'app_session.dart';
import 'api_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejo de notificaciones en segundo plano
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _localNotifications => FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Solo inicializar si es Android y existen google-services.json (si no, fallará silenciosamente)
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await Firebase.initializeApp();
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Configuración local notifications (Android)
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(initializationSettings);

      // Permisos
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      }

      // Foreground message handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    } catch (e) {
      print("FCM Bypass: Firebase no configurado o error de init: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'meltic_alerts', 'Alertas Mèltic',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFFD32F2F),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Alerta Mèltic',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }

  Future<void> registerToken() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null && AppSession.instance.isLoggedIn) {
        print("Registrando token FCM: $token");
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/fcm/token'),
          headers: AppSession.instance.authHeaders,
          body: json.encode({
            'usuarioId': AppSession.instance.userId,
            'token': token
          }),
        );
      }
    } catch (e) {
      print("Error registrando token: $e");
    }
  }
}
