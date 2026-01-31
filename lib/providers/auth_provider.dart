import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _userName;
  String? _userRole;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  String? get userName => _userName;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // مراقبة حالة تسجيل الدخول تلقائياً عند تشغيل التطبيق
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        fetchUserData();
      }
      notifyListeners();
    });
  }

  // جلب بيانات المستخدم الإضافية من Firestore
  Future<void> fetchUserData() async {
    if (_user == null) return;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userName = doc.get('name');
        _userRole = doc.get('role');
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData();
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // إنشاء حساب جديد
  Future<bool> signUp(String email, String password, String name, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // حفظ البيانات الإضافية في Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'role': role, // مريض أو طبيب
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _userName = null;
    _userRole = null;
    notifyListeners();
  }
}
