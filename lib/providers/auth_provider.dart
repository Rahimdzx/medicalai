import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// رسائل خطأ Firebase مترجمة (روسي، عربي، إنجليزي)
class AuthErrorMessages {
  static const Map<String, Map<String, String>> _messages = {
    'user-not-found': {
      'en': 'No account found with this email',
      'ar': 'لا يوجد حساب بهذا البريد الإلكتروني',
      'ru': 'Аккаунт с этим email не найден',
    },
    'wrong-password': {
      'en': 'Incorrect password',
      'ar': 'كلمة المرور غير صحيحة',
      'ru': 'Неверный пароль',
    },
    'invalid-credential': {
      'en': 'Invalid email or password',
      'ar': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      'ru': 'Неверный email или пароль',
    },
    'email-already-in-use': {
      'en': 'This email is already registered',
      'ar': 'هذا البريد الإلكتروني مسجل بالفعل',
      'ru': 'Этот email уже зарегистрирован',
    },
    'weak-password': {
      'en': 'Password is too weak',
      'ar': 'كلمة المرور ضعيفة جداً',
      'ru': 'Слишком слабый пароль',
    },
    'invalid-email': {
      'en': 'Invalid email address',
      'ar': 'عنوان البريد الإلكتروني غير صالح',
      'ru': 'Недействительный email адрес',
    },
    'user-disabled': {
      'en': 'This account has been disabled',
      'ar': 'تم تعطيل هذا الحساب',
      'ru': 'Этот аккаунт отключен',
    },
    'too-many-requests': {
      'en': 'Too many attempts. Please try again later',
      'ar': 'محاولات كثيرة جداً. حاول مرة أخرى لاحقاً',
      'ru': 'Слишком много попыток. Попробуйте позже',
    },
    'network-request-failed': {
      'en': 'Network error. Please check your connection',
      'ar': 'خطأ في الشبكة. يرجى التحقق من اتصالك',
      'ru': 'Ошибка сети. Проверьте подключение к интернету',
    },
  };

  static const Map<String, String> _defaultError = {
    'en': 'An error occurred. Please try again',
    'ar': 'حدث خطأ. حاول مرة أخرى',
    'ru': 'Произошла ошибка. Попробуйте снова',
  };

  static String getLocalizedMessage(String code, String locale) {
    final messages = _messages[code];
    if (messages != null) {
      return messages[locale] ?? messages['en'] ?? _defaultError['en']!;
    }
    return _defaultError[locale] ?? _defaultError['en']!;
  }
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _userName;
  String? _userRole;
  String? _photoUrl;
  String? _price;
  bool _isLoading = false;

  User? get user => _user;
  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get photoUrl => _photoUrl;
  String? get price => _price;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        fetchUserData();
      } else {
        // تصفية البيانات عند الخروج
        _userName = null;
        _userRole = null;
        _photoUrl = null;
        _price = null;
      }
      notifyListeners();
    });
  }

  Future<void> fetchUserData() async {
    if (_user == null) return;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _userRole = data['role'];
          _userName = data['name'];
          _photoUrl = data['photoUrl'] ?? "";
          _price = data['price']?.toString() ?? "0";
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // تسجيل الدخول العادي
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

  // تسجيل الدخول مع رسائل مترجمة
  Future<String?> signInWithLocale(String email, String password, String locale) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData();
      return null;
    } on FirebaseAuthException catch (e) {
      return AuthErrorMessages.getLocalizedMessage(e.code, locale);
    } catch (e) {
      return AuthErrorMessages.getLocalizedMessage('network-request-failed', locale);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // إنشاء حساب جديد
  Future<String?> signUpWithLocale({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String locale,
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
        try {
          Reference ref = _storage.ref().child('user_photos').child('${credential.user!.uid}.jpg');
          await ref.putFile(imageFile);
          uploadedPhotoUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint("Error uploading image: $e");
        }
      }

      await credential.user!.updateDisplayName(name);
      if (uploadedPhotoUrl.isNotEmpty) {
        await credential.user!.updatePhotoURL(uploadedPhotoUrl);
      }

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
      return AuthErrorMessages.getLocalizedMessage(e.code, locale);
    } catch (e) {
      return AuthErrorMessages.getLocalizedMessage('network-request-failed', locale);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // 👇 هذه هي الدالة التي كانت ناقصة وتسبب الخطأ، تمت إضافتها
  // ==========================================================
  Future<void> updateDoctorProfile({
    required String name,
    required String specialization,
    required double fees,
    File? imageFile,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      String currentPhotoUrl = _photoUrl ?? "";

      // 1. رفع الصورة الجديدة إذا وجدت
      if (imageFile != null) {
        Reference ref = _storage.ref().child('user_photos').child('${_user!.uid}.jpg');
        await ref.putFile(imageFile);
        currentPhotoUrl = await ref.getDownloadURL();
      }

      // 2. تحديث الاسم والصورة في Auth
      await _user!.updateDisplayName(name);
      if (currentPhotoUrl.isNotEmpty) {
        await _user!.updatePhotoURL(currentPhotoUrl);
      }

      // 3. تحديث البيانات في Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name,
        'specialization': specialization,
        'price': fees, // أو fees.toString() حسب نوع الحقل لديك
        'photoUrl': currentPhotoUrl,
      });

      // 4. تحديث البيانات محلياً
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;
      await fetchUserData(); // إعادة جلب البيانات لتحديث الواجهة

    } catch (e) {
      throw e; // رمي الخطأ ليظهر في الواجهة
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
