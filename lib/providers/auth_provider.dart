import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _auth.authStateChanges().listen(
      (user) async {
        _user = user;
        if (user != null) {
          await _loadUserRoleSafe();
        } else {
          _userRole = 'patient';
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadUserRoleSafe() async {
    try {
      // تم تعديل الـ timeout ليرمي خطأ بدلاً من إرجاع null لتجنب تعارض الأنواع
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception("Timeout");
        },
      );

      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'patient';
      }
    } catch (e) {
      print("Error loading user role: $e");
      _userRole = 'patient';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? specialization,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'phone': phone ?? '',
        'specialization': specialization ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = 'patient';
    notifyListeners();
  }
}
