import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  User? _user;
  String _userRole = 'patient';
  bool _isLoading = true;

  AuthProvider() {
    _init();
  }

  User? get user => _user;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  void _init() {
    _auth.authStateChanges().listen(
      (user) async {
        _isLoading = true;
        notifyListeners();

        _user = user;
        if (user != null) {
          await _loadUserRoleSafe();
          await _updateFcmToken(); 
        } else {
          _userRole = 'patient';
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// هذه هي الدالة التي كانت تنقصك وتسببت في فشل Build GitHub Action
  Future<void> notifyPatientOfCall({
    required String patientUid,
    required String channelName,
    required String token,
  }) async {
    try {
      if (patientUid.isEmpty) return;

      // تحديث بيانات المكالمة في مستند المريض ليتمكن من استقبالها
      await _firestore.collection('users').doc(patientUid).update({
        'currentCall': {
          'channelName': channelName,
          'token': token,
          'callerName': _user?.email ?? "Doctor",
          'callerId': _user?.uid,
          'status': 'calling',
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
      debugPrint("Patient notified of call successfully.");
    } catch (e) {
      debugPrint("Error notifying patient of call: $e");
    }
  }

  Future<void> _updateFcmToken() async {
    try {
      if (_user == null) return;
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'fcmToken': token,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  Future<void> _loadUserRoleSafe() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("Timeout"),
      );

      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'patient';
      }
    } catch (e) {
      debugPrint("Error loading user role: $e");
      _userRole = 'patient';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? specialization,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? fcmToken = await _fcm.getToken();

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'phone': phone ?? '',
        'specialization': specialization ?? '',
        'fcmToken': fcmToken ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.code;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = 'patient';
    notifyListeners();
  }
}
