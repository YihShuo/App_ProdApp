/*import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print(message.notification?.title);
    print(message.notification?.body);
  }
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
bool isFlutterLocalNotificationsInitialized = false;

class FirebaseApi {
  final firebaseMessaging = FirebaseMessaging.instance;

  handleMessage(RemoteMessage? message) {
    if (message == null) {
      return;
    }
    if (kDebugMode) {
      print(message.notification?.title);
    }
  }

  Future<void> initLocalNotification() async {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_notification")
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: (NotificationResponse notificationResponse) {
        if (kDebugMode) {
          print('notificationResponse ${notificationResponse.payload}');
        }
      }
    );
  }

  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    isFlutterLocalNotificationsInitialized = true;
  }

  initPushNotification() {
    firebaseMessaging.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(showFlutterNotification);
  }

  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        payload: jsonEncode(message.toMap()),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_notification',
          ),
        ),
      );
    }
  }

  initNotification() async {
    await firebaseMessaging.requestPermission();
    final fcmToken = await firebaseMessaging.getToken();
    final sp = await SharedPreferences.getInstance();
    sp.setString('firebaseToken', fcmToken!);
    if (kDebugMode) {
      print('Token : $fcmToken');
    }
    await setupFlutterNotifications();
    initLocalNotification();
    initPushNotification();
  }
}
 */