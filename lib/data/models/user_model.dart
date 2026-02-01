import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the medical app
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'patient', 'doctor', 'admin'
  final String? phone;
  final String? photoUrl;
  final String? specialization; // For doctors
  final String? price; // Consultation price for doctors
  final String? bio;
  final double? rating;
  final int? reviewCount;
  final int? yearsExperience;
  final List<String>? education;
  final List<String>? workingHours;
  final bool isOnline;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;
  final Map<String, dynamic>? settings;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.photoUrl,
    this.specialization,
    this.price,
    this.bio,
    this.rating,
    this.reviewCount,
    this.yearsExperience,
    this.education,
    this.workingHours,
    this.isOnline = false,
    this.isVerified = false,
    this.isActive = true,
    this.lastSeen,
    required this.createdAt,
    this.updatedAt,
    this.fcmToken,
    this.settings,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'patient',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      specialization: data['specialization'],
      price: data['price'],
      bio: data['bio'],
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] as int?,
      yearsExperience: data['yearsExperience'] as int?,
      education: (data['education'] as List?)?.cast<String>(),
      workingHours: (data['workingHours'] as List?)?.cast<String>(),
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      specialization: map['specialization'],
      price: map['price'],
      bio: map['bio'],
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: map['reviewCount'] as int?,
      yearsExperience: map['yearsExperience'] as int?,
      education: (map['education'] as List?)?.cast<String>(),
      workingHours: (map['workingHours'] as List?)?.cast<String>(),
      isOnline: map['isOnline'] ?? false,
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      lastSeen: map['lastSeen'] is Timestamp
          ? (map['lastSeen'] as Timestamp).toDate()
          : map['lastSeen'] as DateTime?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime? ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] as DateTime?,
      fcmToken: map['fcmToken'],
      settings: map['settings'] as Map<String, dynamic>?,
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'specialization': specialization,
      'price': price,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'yearsExperience': yearsExperience,
      'education': education,
      'workingHours': workingHours,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fcmToken': fcmToken,
      'settings': settings,
    };
  }

  /// Copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? photoUrl,
    String? specialization,
    String? price,
    String? bio,
    double? rating,
    int? reviewCount,
    int? yearsExperience,
    List<String>? education,
    List<String>? workingHours,
    bool? isOnline,
    bool? isVerified,
    bool? isActive,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      specialization: specialization ?? this.specialization,
      price: price ?? this.price,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      education: education ?? this.education,
      workingHours: workingHours ?? this.workingHours,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      settings: settings ?? this.settings,
    );
  }

  /// Check if user is a doctor
  bool get isDoctor => role == 'doctor';

  /// Check if user is a patient
  bool get isPatient => role == 'patient';

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  /// Get display rating string
  String get ratingDisplay => rating?.toStringAsFixed(1) ?? '0.0';

  /// Get initials from name
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role)';
}
