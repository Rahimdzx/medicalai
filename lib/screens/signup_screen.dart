import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart'; // لاستدعاء اللغة الحالية
import '../core/constants/colors.dart';

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
  // ignore: unused_field
  String? _selectedSpecialization;
  File? _imageFile;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    // 👇 استخدام الدالة الصحيحة مع تمرير اللغة
    final error = await authProvider.signUpWithLocale(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _role,
      phone: _phoneController.text.trim().isEmpty ? "0000000000" : _phoneController.text.trim(), // قيمة افتراضية إذا كان فارغاً
      locale: languageProvider.languageCode, // لغة المستخدم الحالية (en, ar, ru)
      specialization: _role == 'doctor' ? "General" : "", // تخصص افتراضي
      price: _role == 'doctor' ? _priceController.text.trim() : "0",
      imageFile: _imageFile,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error), 
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // العودة لشاشة تسجيل الدخول أو الشاشة الرئيسية
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.signUp),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // اختيار الصورة الشخصية
              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null 
                            ? const Icon(Icons.person, size: 60, color: AppColors.primary) 
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              _buildTextField(
                controller: _nameController,
                label: l10n.fullName,
                icon: Icons.person_outline,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: l10n.email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                validator: (v) => !v!.contains("@") ? "Email invalid" : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordController,
                label: l10n.password,
                icon: Icons.lock_outline,
                obscureText: true,
                enabled: !isLoading,
                validator: (v) => v!.length < 6 ? "Short password" : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: l10n.phoneNumber ?? "Phone Number",
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              // اختيار الدور (مريض/طبيب)
              DropdownButtonFormField<String>(
                value: _role,
                items: [
                  DropdownMenuItem(value: 'patient', child: Text(l10n.patient ?? "Patient")),
                  DropdownMenuItem(value: 'doctor', child: Text(l10n.doctor ?? "Doctor")),
                ],
                onChanged: isLoading ? null : (v) => setState(() => _role = v!),
                decoration: InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              
              if (_role == 'doctor') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _priceController,
                  label: "Consultation Price",
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  enabled: !isLoading,
                ),
              ],

              const SizedBox(height: 40),
              
              // زر التسجيل
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(l10n.signUp, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
      validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
    );
  }
}
