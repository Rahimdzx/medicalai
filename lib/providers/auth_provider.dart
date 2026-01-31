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

  // دالة تسجيل الدخول المصححة
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. تسجيل الدخول في Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (result.user != null) {
        _user = result.user;
        // 2. الانتظار الإجباري لجلب الدور قبل إخطار الواجهة
        await _loadUserRoleSafe();
        await _updateFcmToken();
      }

      _isLoading = false;
      notifyListeners(); // إرسال الإشارة للواجهة بعد اكتمال كل البيانات
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "error";
    }
  }

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

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'specialization': specialization,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': '',
        'experience': "0",
        'rating': 5.0,
      });

      _userRole = role; // تعيين الدور محلياً فوراً
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "error";
    }
  }

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

  Future<void> _updateFcmToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null && _user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({'fcmToken': token});
      }
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = 'patient';
    notifyListeners();
  }
}
