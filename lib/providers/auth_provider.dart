import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _userName;
  String? _userRole;
  bool _isLoading = false;

  User? get user => _user;
  String? get userName => _userName;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        fetchUserData();
      }
      notifyListeners();
    });
  }

  Future<void> fetchUserData() async {
    if (_user == null) return;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userRole = doc.get('role');
        _userName = doc.get('name');
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // دالة تسجيل الدخول (تم تعديل الاسم لـ signIn ليطابق شاشة Login)
  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData();
      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // دالة تسجيل الخروج (تم تعديل الاسم لـ signOut ليطابق شاشات الـ Dashboards)
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = null;
    _userName = null;
    notifyListeners();
  }

  // دالة إنشاء حساب (معدلة لتدعم رفع الصور والسعر وتطابق شاشة SignUp)
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    String? specialization,
    String? price,
    File? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String photoUrl = "";
      if (imageFile != null) {
        Reference ref = _storage.ref().child('user_photos').child('${credential.user!.uid}.jpg');
        await ref.putFile(imageFile);
        photoUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'specialization': specialization ?? "",
        'price': price ?? "0",
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
