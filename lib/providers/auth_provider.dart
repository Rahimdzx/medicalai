import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _userRole = 'patient'; // default patient
  bool _isLoading = true;

  AuthProvider() {
    _init();
  }

  User? get user => _user;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  // INIT with protection
  void _init() {
    try {
      _auth.authStateChanges().listen(
        (user) async {
          print("Auth state changed: $user");
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
          print("Auth stream error: $err");
          _isLoading = false;
          _user = null;
          _userRole = 'patient';
          notifyListeners();
        },
      );
    } catch (e) {
      print("AuthProvider init error: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  // Firestore call with timeout + fallback
  Future<void> _loadUserRoleSafe() async {
    try {
      final doc =
          await _firestore.collection('users').doc(_user!.uid).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("Firestore timeout, using default role patient");
          return null;
        },
      );

      if (doc != null && doc.exists) {
        _userRole = doc.data()?['role'] ?? 'patient';
      } else {
        _userRole = 'patient';
      }
    } catch (e) {
      print("Error loading user role: $e");
      _userRole = 'patient';
    }
  }

  // SIGN IN
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      print("SignIn error: ${e.code}");
      return e.code;
    }
  }

  // SIGN UP
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
      print("SignUp error: ${e.code}");
      return e.code;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userRole = 'patient';
      notifyListeners();
    } catch (e) {
      print("SignOut error: $e");
    }
  }
}
