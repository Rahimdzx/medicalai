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

  // دالة رفع الصورة (محدثة لتعيد رابط الصورة بدقة)
  Future<String> _uploadUserImage(File imageFile, String uid) async {
    try {
      Reference ref = _storage.ref().child('user_photos').child('$uid.jpg');
      // وضعنا metadata لضمان التعرف على نوع الملف كصورة
      UploadTask uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
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
    File? imageFile, 
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. إنشاء الحساب
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. رفع الصورة فور نجاح إنشاء الحساب
      String photoUrl = '';
      if (imageFile != null) {
        photoUrl = await _uploadUserImage(imageFile, result.user!.uid);
      }

      // 3. حفظ البيانات في Firestore
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
      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      return e.message; // رسالة خطأ واضحة للمستخدم
    } catch (e) {
      return "حدث خطأ غير متوقع: ${e.toString()}";
    } finally {
      // هذا السطر يضمن توقف دائرة التحميل مهما كانت النتيجة
      _isLoading = false;
      notifyListeners();
    }
  }

  // دالة تسجيل الدخول محسنة
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserRoleSafe();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserRoleSafe() async {
    if (_user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'patient';
      }
    } catch (e) {
      debugPrint("Error loading role: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = 'patient';
    notifyListeners();
  }
}
