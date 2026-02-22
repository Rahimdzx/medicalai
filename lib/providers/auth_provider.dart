import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/utils/error_handler.dart';

/// Authentication Provider with robust Firebase Auth/Firestore synchronization
/// 
/// Features:
/// - Safe null handling for user data
/// - Proper loading states
/// - Comprehensive error handling
/// - Role-based user creation
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isInitializing = true;
  String? _error;

  // ==================== Constructor & Init ====================

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
        _isLoading = false;
        _isInitializing = false;
      }
      
      notifyListeners();
    });
  }

  // ==================== Getters ====================

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _user != null && _userModel != null;
  String? get error => _error;
  String? get userRole => _userModel?.role;
  String? get userName => _userModel?.name;

  // ==================== User Data Fetching ====================

  /// Fetch user data from Firestore with retry logic
  Future<void> _fetchUserData(String uid, {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (doc.exists && doc.data() != null) {
          _userModel = UserModel.fromFirestore(doc);
          _error = null;
          _isLoading = false;
          _isInitializing = false;
          notifyListeners();
          return;
        } else if (attempt == retries - 1) {
          // Last attempt and no data - user document doesn't exist
          _error = 'User data not found. Please contact support.';
          _userModel = null;
        }
      } on FirebaseException catch (e) {
        if (attempt == retries - 1) {
          _error = ErrorHandler.getErrorMessage(e);
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } catch (e) {
        if (attempt == retries - 1) {
          _error = 'Failed to load user data. Please try again.';
        }
      }
    }
    
    _isLoading = false;
    _isInitializing = false;
    notifyListeners();
  }

  /// Force refresh user data from Firestore
  Future<void> refreshUserData() async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    await _fetchUserData(_user!.uid);
  }

  // ==================== Authentication Methods ====================

  /// Sign in with email and password
  Future<bool> signIn(String email, String password, {BuildContext? context}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 30));

      if (result.user != null) {
        // Wait for user data to be fetched
        await _fetchUserData(result.user!.uid);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _error = ErrorHandler.getFirebaseAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException {
      _error = 'Connection timed out. Please check your internet connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with full profile including role selection
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? specialty,
    double? price,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validate role
      if (!['patient', 'doctor', 'admin'].contains(role)) {
        _error = 'Invalid role selected';
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      // Create Firebase Auth user
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 30));

      if (credential.user == null) {
        _error = 'Failed to create account. Please try again.';
        _isLoading = false;
        notifyListeners();
        return _error;
      }

      // Create user model with safe defaults
      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        specialty: specialty?.trim(),
        createdAt: DateTime.now(),
      );

      // Save to Firestore with retry
      await _saveUserDataWithRetry(credential.user!.uid, userModel.toJson());

      // Create role-specific profile
      if (role == 'doctor') {
        await _createDoctorProfile(
          uid: credential.user!.uid,
          name: name.trim(),
          specialty: specialty?.trim() ?? 'General',
          price: price ?? 50.0,
        );
      }

      // Update local state
      _userModel = userModel;
      _isLoading = false;
      notifyListeners();

      return null; // Success - no error
    } on FirebaseAuthException catch (e) {
      _error = ErrorHandler.getFirebaseAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return _error;
    } on TimeoutException {
      _error = 'Connection timed out. Please check your internet connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  /// Save user data with retry logic
  Future<void> _saveUserDataWithRetry(String uid, Map<String, dynamic> data, {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(data)
            .timeout(const Duration(seconds: 10));
        return;
      } catch (e) {
        if (attempt == retries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
  }

  /// Create doctor profile in doctors collection
  Future<void> _createDoctorProfile({
    required String uid,
    required String name,
    required String specialty,
    required double price,
  }) async {
    final doctorData = {
      'userId': uid,
      'name': name,
      'nameEn': name,
      'nameAr': name,
      'specialty': specialty,
      'specialtyEn': specialty,
      'specialtyAr': _getArabicSpecialty(specialty),
      'price': price,
      'currency': 'USD',
      'rating': 5.0,
      'doctorNumber': uid.substring(0, 8).toUpperCase(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('doctors').doc(uid).set(doctorData);
  }

  // ==================== Password Management ====================

  /// Send password reset email
  Future<String?> sendPasswordResetEmail(String email, {BuildContext? context}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(const Duration(seconds: 15));

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _error = ErrorHandler.getFirebaseAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return _error;
    } on TimeoutException {
      _error = 'Connection timed out. Please try again.';
      _isLoading = false;
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Failed to send reset email. Please try again.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ==================== Profile Management ====================

  /// Update user profile
  Future<String?> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
    BuildContext? context,
  }) async {
    if (_user == null || _userModel == null) {
      return 'Not authenticated';
    }

    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updates['name'] = name.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (photoUrl != null) updates['photoUrl'] = photoUrl.trim();

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updates)
          .timeout(const Duration(seconds: 10));

      // Update local model
      _userModel = _userModel!.copyWith(
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _error = 'Failed to update profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  // ==================== Sign Out ====================

  /// Sign out user
  Future<void> signOut() async {
    try {
      // Update online status before signing out
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((_) {
          // Ignore errors during sign out cleanup
        });
      }

      await _auth.signOut();
      _user = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      // Even if cleanup fails, force sign out
      await _auth.signOut();
      _user = null;
      _userModel = null;
      notifyListeners();
    }
  }

  // ==================== Utility Methods ====================

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get Arabic specialty name (basic mapping)
  String _getArabicSpecialty(String specialty) {
    const mappings = {
      'General': 'عام',
      'Cardiology': 'قلب وأوعية دموية',
      'Dermatology': 'جلدية',
      'Neurology': 'أعصاب',
      'Pediatrics': 'أطفال',
      'Orthopedics': 'عظام',
      'Ophthalmology': 'عيون',
      'ENT': 'أنف وأذن وحنجرة',
    };
    return mappings[specialty] ?? specialty;
  }
}

/// Timeout exception for async operations
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
