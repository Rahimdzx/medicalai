import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String _userRole = 'patient';
  bool _isLoading = false;

  User? get user => _user;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        await _loadUserRoleSafe();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // دالة رفع الصورة من الجهاز إلى Firebase Storage
  Future<String> _uploadUserImage(File imageFile, String uid) async {
    try {
      Reference ref = _storage.ref().child('user_photos').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String specialization,
    required String price,
    File? imageFile, // ملف الصورة من جهاز المستخدم
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String photoUrl = '';
      if (imageFile != null) {
        photoUrl = await _uploadUserImage(imageFile, result.user!.uid);
      }

      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'specialization': specialization,
        'price': price,
        'photoUrl': photoUrl,
        'rating': 5.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _userRole = role;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserRoleSafe();
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "error";
    }
  }

  Future<void> _loadUserRoleSafe() async {
    if (_user == null) return;
    final doc = await _firestore.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      _userRole = doc.data()?['role'] ?? 'patient';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = 'patient';
    notifyListeners();
  }
}
