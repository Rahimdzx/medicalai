import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // وحدات التحكم بالنصوص
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _scheduleController;
  String? _selectedSpecialty;

  File? _imageFile;
  bool _isLoading = false;
  String? _currentPhotoUrl;

  // قائمة التخصصات التي ناقشناها
  final List<String> _specialties = [
    'Urologist / Уролог',
    'Gynecologist / Гинеколог',
    'Oncologist / Онколог',
    'Therapist / Терапевт',
    'Neurologist / Невролог',
    'Plastic Surgeon / Пластический хирург'
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    // تحميل البيانات الحالية من Firestore
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _scheduleController = TextEditingController();
    _loadCurrentData(user!.uid);
  }

  void _loadCurrentData(String uid) async {
    var doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? '';
        _priceController.text = doc['price'] ?? '';
        _scheduleController.text = doc['schedule'] ?? '';
        _selectedSpecialty = doc['specialization'];
        _currentPhotoUrl = doc['photoUrl'];
      });
    }
  }

  // اختيار صورة من الهاتف
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // رفع الصورة وحفظ البيانات
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final uid = Provider.of<AuthProvider>(context, listen: false).user!.uid;

    try {
      String? photoUrl = _currentPhotoUrl;

      // 1. رفع الصورة إلى Firebase Storage إذا تم اختيار صورة جديدة
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('doctor_photos')
            .child('$uid.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      // 2. تحديث البيانات في Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text,
        'price': _priceController.text,
        'schedule': _scheduleController.text,
        'specialization': _selectedSpecialty,
        'photoUrl': photoUrl,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Success / Успешно")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile / Редактировать")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // اختيار الصورة
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (_currentPhotoUrl != null
                                ? NetworkImage(_currentPhotoUrl!)
                                : null),
                        child: (_imageFile == null && _currentPhotoUrl == null)
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // الاسم
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: "Full Name / Полное имя"),
                    ),
                    const SizedBox(height: 15),

                    // قائمة التخصصات
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialty,
                      decoration: const InputDecoration(
                          labelText: "Specialty / Специальность"),
                      items: _specialties
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSpecialty = val),
                    ),
                    const SizedBox(height: 15),

                    // السعر
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                          labelText: "Consultation Fee / Цена (USD)"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),

                    // المواعيد
                    TextFormField(
                      controller: _scheduleController,
                      decoration: const InputDecoration(
                          labelText: "Schedule / График (ex: Mon-Fri 9-5)"),
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Save Changes / Сохранить"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
