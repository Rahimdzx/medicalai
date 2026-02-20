import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  final String userId;
  final String name;
  final String nameEn;
  final String nameAr;
  final String? photo;
  final String specialty;
  final String specialtyEn;
  final String specialtyAr;
  final double price;
  final String currency;
  final double rating;
  final String doctorNumber;
  final String? qrCodeUrl;
  final String description;
  final bool isActive;
  final List<String> allowedFileTypes;
  final DateTime createdAt;

  DoctorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.nameEn,
    required this.nameAr,
    this.photo,
    required this.specialty,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.price,
    required this.currency,
    required this.rating,
    required this.doctorNumber,
    this.qrCodeUrl,
    required this.description,
    required this.isActive,
    required this.allowedFileTypes,
    required this.createdAt,
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      nameAr: data['nameAr'] ?? '',
      photo: data['photo'],
      specialty: data['specialty'] ?? '',
      specialtyEn: data['specialtyEn'] ?? '',
      specialtyAr: data['specialtyAr'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      rating: (data['rating'] ?? 0).toDouble(),
      doctorNumber: data['doctorNumber'] ?? '',
      qrCodeUrl: data['qrCodeUrl'],
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      allowedFileTypes: List<String>.from(data['allowedFileTypes'] ?? ['image', 'pdf']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String getLocalizedName(String locale) {
    switch (locale) {
      case 'ar': return nameAr;
      case 'ru': return name;
      default: return nameEn;
    }
  }

  String getLocalizedSpecialty(String locale) {
    switch (locale) {
      case 'ar': return specialtyAr;
      case 'ru': return specialty;
      default: return specialtyEn;
    }
  }
}
