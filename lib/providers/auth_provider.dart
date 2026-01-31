import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  User? _user;
  String _userRole = 'patient';
  bool _isLoading = true;

  AuthProvider() {
    _init();
  }

  // Getters
  User? get user => _user;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  void _init() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        await _loadUserRoleSafe();
        await _updateFcmToken();
      } else {
        _userRole = 'patient';
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  /// --- دالة التسجيل (SignUp) التي كانت مفقودة ---
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String specialization,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. إنشاء الحساب في Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. حفظ بيانات المستخدم الإضافية في Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'specialization': specialization,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': '', // رابط الصورة الافتراضي فارغ
        'experience': "0",
        'rating': 5.0,
      });

      _isLoading = false;
      notifyListeners();
      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code; // إرجاع كود الخطأ (مثل email-already-in-use)
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "error";
    }
  }

  /// --- دالة تسجيل الدخول ---
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    }
  }

  /// --- تحديث بيانات الطبيب مع رفع الصورة ---
  Future<void> updateDoctorProfile({
    required String name,
    required String specialization,
    required double fees,
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      String? photoUrl;

      // رفع الصورة إلى Firebase Storage إذا وجدت
      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('doctors/${_user!.uid}.jpg');
        await ref.putFile(imageFile);
        photoUrl = await ref.getDownloadURL();
      }

      // تحديث البيانات في Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name,
        'specialization': specialization,
        'fees': fees,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      // تحديث البيانات في Firebase Auth Profile
      await _user!.updateDisplayName(name);
      if (photoUrl != null) await _user!.updatePhotoURL(photoUrl);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// --- جلب دور المستخدم (طبيب أم مريض) ---
  Future<void> _loadUserRoleSafe() async {
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'patient';
      }
    } catch (e) {
      _userRole = 'patient';
    }
  }

  /// --- تحديث توكن الإشعارات ---
  Future<void> _updateFcmToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      debugPrint("FCM Token Error: $e");
    }
  }

  /// --- تسجيل الخروج ---
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = 'patient';
    notifyListeners();
  }
}
