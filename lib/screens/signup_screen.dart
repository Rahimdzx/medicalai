import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _role = 'patient';
  String? _selectedSpecialization;
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final error = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _role,
      phone: _phoneController.text.trim(),
      specialization: _selectedSpecialization ?? "",
      price: _priceController.text.trim(),
      imageFile: _imageFile,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      // إذا نجح التسجيل، نغلق الشاشة فوراً لتجنب بقاء الدائرة
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // نراقب حالة التحميل من البروفايدر
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("إنشاء حساب جديد")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // اختيار الصورة
              GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[50],
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "الاسم الكامل", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "مطلوب" : null,
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder()),
                validator: (v) => !v!.contains("@") ? "ايميل غير صالح" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder()),
                validator: (v) => v!.length < 6 ? "قصيرة جداً" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'patient', child: Text("مريض")),
                  DropdownMenuItem(value: 'doctor', child: Text("طبيب")),
                ],
                onChanged: (v) => setState(() => _role = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              
              if (_role == 'doctor') ...[
                const SizedBox(height: 15),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "سعر الكشف", border: OutlineInputBorder()),
                ),
              ],

              const SizedBox(height: 30),
              
              // الزر الذي يتغير شكله عند التحميل
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("تسجيل الحساب", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
