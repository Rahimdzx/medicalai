import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserData(user.uid);
        await _saveCredentials(user.uid);
      } else {
        _userModel = null;
        await _clearCredentials();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _saveCredentials(String uid) async {
    try {
      await _secureStorage.write(key: 'user_id', value: uid);
      await _secureStorage.write(key: 'auth_time', value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> _clearCredentials() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  /// Check for saved credentials and attempt auto-login
  Future<bool> tryAutoLogin() async {
    try {
      final savedUserId = await _secureStorage.read(key: 'user_id');
      final authTime = await _secureStorage.read(key: 'auth_time');

      if (savedUserId == null || authTime == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if session is still valid (30 days)
      final lastAuth = DateTime.parse(authTime);
      final sessionValid = DateTime.now().difference(lastAuth).inDays < 30;

      if (!sessionValid) {
        await _clearCredentials();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if current user is already authenticated
      if (_auth.currentUser != null) {
        _user = _auth.currentUser;
        await _fetchUserData(_user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Session expired or user logged out
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Auto-login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String? get userRole => _userModel?.role;
  String? get userName => _userModel?.name;

  // Login
  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (rememberMe) {
        await _secureStorage.write(key: 'saved_email', value: email);
      }
      
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get saved email for login form
  Future<String?> getSavedEmail() async {
    return await _secureStorage.read(key: 'saved_email');
  }

  // Register
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'patient',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(credential.user!.uid).set(
        userModel.toMap(),
      );

      // Create doctor profile if role is doctor
      if (role == 'doctor') {
        await _firestore.collection('doctors').doc(credential.user!.uid).set({
          'userId': credential.user!.uid,
          'name': name,
          'nameEn': name,
          'nameAr': name,
          'specialty': 'General Practice',
          'specialtyEn': 'General Practice',
          'specialtyAr': 'ممارس عام',
          'price': 1000,
          'currency': 'RUB',
          'rating': 5.0,
          'doctorNumber': credential.user!.uid.substring(0, 8).toUpperCase(),
          'isActive': true,
          'description': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Update Profile
  Future<void> updateProfile({String? name, String? phone, String? photoUrl}) async {
    if (_user == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore.collection('users').doc(_user!.uid).update(updates);

    // Update doctor profile name if applicable
    if (name != null && _userModel?.role == 'doctor') {
      await _firestore.collection('doctors').doc(_user!.uid).update({
        'name': name,
        'nameEn': name,
      });
    }

    if (_userModel != null) {
      _userModel = UserModel(
        uid: _userModel!.uid,
        name: name ?? _userModel!.name,
        email: _userModel!.email,
        phone: phone ?? _userModel!.phone,
        role: _userModel!.role,
        photoUrl: photoUrl ?? _userModel!.photoUrl,
        createdAt: _userModel!.createdAt,
      );
      notifyListeners();
    }
  }

  // Change Password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_user == null || _user!.email == null) return false;

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);

      // Change password
      await _user!.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearCredentials();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'An error occurred';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
