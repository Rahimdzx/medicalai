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
  String? _photoUrl; // جديد
  String? _price;    // جديد
  bool _isLoading = false;

  User? get user => _user;
  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get photoUrl => _photoUrl; // جديد
  String? get price => _price;       // جديد
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
        _photoUrl = doc.data().toString().contains('photoUrl') ? doc.get('photoUrl') : ""; // جلب الصورة
        _price = doc.data().toString().contains('price') ? doc.get('price') : "0"; // جلب السعر
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = null;
    _userName = null;
    _photoUrl = null;
    _price = null;
    notifyListeners();
  }

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

      String uploadedPhotoUrl = "";
      if (imageFile != null) {
        Reference ref = _storage.ref().child('user_photos').child('${credential.user!.uid}.jpg');
        await ref.putFile(imageFile);
        uploadedPhotoUrl = await ref.getDownloadURL();
      }

      // تحديث ملف المستخدم الأساسي في Firebase Auth (مهم جداً للتعرف الفوري)
      await credential.user!.updateDisplayName(name);
      await credential.user!.updatePhotoURL(uploadedPhotoUrl);

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'specialization': specialization ?? "",
        'price': price ?? "0",
        'photoUrl': uploadedPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchUserData();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
