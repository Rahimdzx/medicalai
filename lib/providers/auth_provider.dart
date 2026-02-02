import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Auth error messages localized for Russian, Arabic, and English
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
    'operation-not-allowed': {
      'en': 'This operation is not allowed',
      'ar': 'هذه العملية غير مسموح بها',
      'ru': 'Эта операция не разрешена',
    },
    'network-request-failed': {
      'en': 'Network error. Please check your connection',
      'ar': 'خطأ في الشبكة. يرجى التحقق من اتصالك',
      'ru': 'Ошибка сети. Проверьте подключение к интернету',
    },
    'requires-recent-login': {
      'en': 'Please log in again to continue',
      'ar': 'يرجى تسجيل الدخول مرة أخرى للمتابعة',
      'ru': 'Пожалуйста, войдите снова для продолжения',
    },
    'account-exists-with-different-credential': {
      'en': 'Account exists with different sign-in method',
      'ar': 'الحساب موجود بطريقة تسجيل دخول مختلفة',
      'ru': 'Аккаунт существует с другим методом входа',
    },
    'expired-action-code': {
      'en': 'The action code has expired',
      'ar': 'انتهت صلاحية رمز الإجراء',
      'ru': 'Срок действия кода истёк',
    },
    'invalid-action-code': {
      'en': 'The action code is invalid',
      'ar': 'رمز الإجراء غير صالح',
      'ru': 'Недействительный код',
    },
  };

  static const Map<String, String> _defaultError = {
    'en': 'An error occurred. Please try again',
    'ar': 'حدث خطأ. حاول مرة أخرى',
    'ru': 'Произошла ошибка. Попробуйте снова',
  };

  /// Get localized error message for Firebase Auth error codes
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

  /// Sign in with localized error messages for Russian market
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
      // Handle network and other errors
      if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        return AuthErrorMessages.getLocalizedMessage('network-request-failed', locale);
      }
      return AuthErrorMessages.getLocalizedMessage('unknown', locale);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with localized error messages for Russian market
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
        Reference ref = _storage.ref().child('user_photos').child('${credential.user!.uid}.jpg');
        await ref.putFile(imageFile);
        uploadedPhotoUrl = await ref.getDownloadURL();
      }

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
      return AuthErrorMessages.getLocalizedMessage(e.code, locale);
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        return AuthErrorMessages.getLocalizedMessage('network-request-failed', locale);
      }
      return AuthErrorMessages.getLocalizedMessage('unknown', locale);
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
