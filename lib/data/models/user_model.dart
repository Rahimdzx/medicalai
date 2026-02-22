import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User model representing application users (patients, doctors, admins)
/// 
/// This model ensures safe null handling and provides default values
/// to prevent "role" errors and other null-related issues.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin', 'doctor', or 'patient'
  final String locale;
  final String? specialty; // for doctors
  final String? photoUrl;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'patient', // ✅ Default to patient for safety
    this.locale = 'en',
    this.specialty,
    this.photoUrl,
    DateTime? createdAt,
    this.isOnline = false,
    this.lastSeen,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory constructor from Firestore document
  /// Provides safe null handling with default values
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return UserModel(
      uid: doc.id,
      name: _safeString(data['name'], 'User'),
      email: _safeString(data['email'], ''),
      phone: _safeString(data['phone'], ''),
      role: _safeString(data['role'], 'patient'), // ✅ Safe role default
      locale: _safeString(data['locale'], 'en'),
      specialty: _safeNullableString(data['specialty']),
      photoUrl: _safeNullableString(data['photoUrl']),
      createdAt: _safeTimestamp(data['createdAt']),
      isOnline: data['isOnline'] ?? false,
      lastSeen: _safeNullableTimestamp(data['lastSeen']),
    );
  }

  /// Factory constructor from Firebase Auth user + Firestore data
  /// Use this when you have both Auth user and Firestore document data
  factory UserModel.fromFirebase(User firebaseUser, Map<String, dynamic>? data) {
    return UserModel(
      uid: firebaseUser.uid,
      name: _safeString(data?['name'], firebaseUser.displayName ?? 'User'),
      email: _safeString(data?['email'], firebaseUser.email ?? ''),
      phone: _safeString(data?['phone'], ''),
      role: _safeString(data?['role'], 'patient'), // ✅ Safe role default
      locale: _safeString(data?['locale'], 'en'),
      specialty: _safeNullableString(data?['specialty']),
      photoUrl: _safeNullableString(data?['photoUrl']) ?? firebaseUser.photoURL,
      createdAt: _safeTimestamp(data?['createdAt']),
      isOnline: data?['isOnline'] ?? false,
      lastSeen: _safeNullableTimestamp(data?['lastSeen']),
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? locale,
    String? specialty,
    String? photoUrl,
    DateTime? createdAt,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      locale: locale ?? this.locale,
      specialty: specialty ?? this.specialty,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Convert to Map for Firestore (excludes uid as it's the document ID)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'locale': locale,
      if (specialty != null) 'specialty': specialty,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
    };
  }

  /// Convert to JSON for Firestore with server timestamp
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'locale': locale,
      if (specialty != null) 'specialty': specialty,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  // ==================== Helper Methods ====================

  /// Safely extract string with fallback
  static String _safeString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty ? fallback : value;
    return value.toString();
  }

  /// Safely extract nullable string
  static String? _safeNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// Safely extract timestamp
  static DateTime _safeTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Safely extract nullable timestamp
  static DateTime? _safeNullableTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  // ==================== Convenience Getters ====================

  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';

  /// Get display name with fallback
  String get displayName => name.isNotEmpty ? name : 'User';

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
