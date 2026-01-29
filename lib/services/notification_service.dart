import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // طلب إذن الإشعارات
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // إعداد الإشعارات المحلية
      await _initializeLocalNotifications();
      
      // الحصول على FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // الاستماع لتحديث الـ token
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // التعامل مع الإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // التعامل مع الإشعارات عند فتح التطبيق
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // التعامل مع النقر على الإشعار
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // التعامل مع النقر على الإشعار المحلي
        print('Notification tapped: ${details.payload}');
      },
    );

    // إنشاء قناة للإشعارات على Android
    const androidChannel = AndroidNotificationChannel(
      'medical_app_channel',
      'Medical App Notifications',
      description: 'Notifications for medical records and reminders',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // عرض إشعار محلي
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // يمكن التنقل لشاشة معينة بناءً على البيانات
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medical_app_channel',
      'Medical App Notifications',
      channelDescription: 'Notifications for medical records and reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // إرسال إشعار للمريض عند إضافة وصفة جديدة
  static Future<void> sendNewRecordNotification({
    required String patientEmail,
    required String diagnosis,
  }) async {
    // الحصول على FCM token للمريض
    final patientQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: patientEmail)
        .get();

    if (patientQuery.docs.isNotEmpty) {
      final patientData = patientQuery.docs.first.data();
      final fcmToken = patientData['fcmToken'];

      if (fcmToken != null) {
        // إضافة إشعار لقائمة الإشعارات في Firestore
        // سيتم إرساله عبر Cloud Functions
        await FirebaseFirestore.instance.collection('notifications').add({
          'token': fcmToken,
          'title': 'New Medical Record',
          'body': 'You have a new diagnosis: $diagnosis',
          'patientEmail': patientEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'sent': false,
        });
      }
    }
  }

  // جدولة تذكير بالدواء
  Future<void> scheduleMedicationReminder({
    required String medicationName,
    required DateTime reminderTime,
    required int id,
  }) async {
    // للتبسيط، نستخدم إشعار محلي
    // في الإنتاج، استخدم flutter_local_notifications مع scheduling
    await _showLocalNotification(
      title: 'Medication Reminder',
      body: 'Time to take $medicationName',
      payload: 'medication_$id',
    );
  }
}

// Background message handler - يجب أن يكون top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
