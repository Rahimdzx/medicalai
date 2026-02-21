import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
      } else {
        _userModel = null;
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

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String? get userRole => _userModel?.role;
  String? get userName => _userModel?.name;

  // Login
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with locale and additional fields
  Future<String?> signUpWithLocale({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String locale,
    required String specialization,
    required String price,
    dynamic imageFile,
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
          'specialty': specialization,
          'specialtyEn': specialization,
          'specialtyAr': specialization,
          'price': double.tryParse(price) ?? 50,
          'currency': 'USD',
          'rating': 5.0,
          'doctorNumber': credential.user!.uid.substring(0, 8).toUpperCase(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _error = null;
      return null; // Success - no error
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      return _error;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register (legacy method)
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
          'specialty': 'General',
          'specialtyEn': 'General',
          'specialtyAr': 'عام',
          'price': 50,
          'currency': 'USD',
          'rating': 5.0,
          'doctorNumber': credential.user!.uid.substring(0, 8).toUpperCase(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Forgot Password
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
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

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
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
        return 'Password is too weak';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
