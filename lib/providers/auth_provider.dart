import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  User? _user;
  String _userRole = 'patient';
  bool _isLoading = true; // يبدأ التطبيق في حالة تحميل أثناء التحقق من الجلسة

  AuthProvider() {
    _init();
  }

  // Getters
  User? get user => _user;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  // تهيئة المزود ومراقبة حالة تسجيل الدخول
  void _init() {
    _auth.authStateChanges().listen(
      (user) async {
        _user = user;
        if (user != null) {
          // جلب دور المستخدم وتوكن الإشعارات عند اكتشاف مستخدم مسجل
          await _loadUserRoleSafe();
          await _updateFcmToken();
        } else {
          _userRole = 'patient';
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint("Auth State Error: $err");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // تسجيل الدخول
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // ملاحظة: لا نضع _isLoading = false هنا لأن authStateChanges ستتكفل بذلك تلقائياً
      return null; 
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'error';
    }
  }

  // تسجيل مستخدم جديد
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? specialization,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. إنشاء الحساب في Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. محاولة جلب توكن الإشعارات (مع وقت مستقطع لتجنب التعليق)
      String? fcmToken;
      try {
        fcmToken = await _fcm.getToken().timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint("Could not fetch FCM token: $e");
      }

      // 3. حفظ بيانات المستخدم الإضافية في Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone ?? '',
        'specialization': specialization ?? '',
        'fcmToken': fcmToken ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'error';
    }
  }

  // جلب دور المستخدم (طبيب أو مريض) من Firestore بشكل آمن
  Future<void> _loadUserRoleSafe() async {
    try {
      if (_user == null) return;
      
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        _userRole = doc.data()!['role'] ?? 'patient';
      }
    } catch (e) {
      debugPrint("Error loading user role: $e");
      _userRole = 'patient'; // القيمة الافتراضية عند الفشل
    }
  }

  // تحديث توكن الإشعارات لضمان وصول التنبيهات للهاتف الحالي
  Future<void> _updateFcmToken() async {
    try {
      if (_user == null) return;
      String? token = await _fcm.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'fcmToken': token,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  // إرسال إشعار للمريض (يستخدمه الطبيب عند بدء مكالمة)
  Future<void> notifyPatientOfCall({
    required String patientUid,
    required String channelName,
    required String token,
  }) async {
    try {
      if (patientUid.isEmpty) return;

      await _firestore.collection('users').doc(patientUid).update({
        'currentCall': {
          'channelName': channelName,
          'token': token,
          'callerName': _user?.displayName ?? _user?.email ?? "Doctor",
          'callerId': _user?.uid,
          'status': 'calling',
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
      debugPrint("Patient notified of call successfully.");
    } catch (e) {
      debugPrint("Error notifying patient of call: $e");
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signOut();
      _user = null;
      _userRole = 'patient';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
