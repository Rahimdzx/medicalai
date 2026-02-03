import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/constants/colors.dart';

// ✅ تم تصحيح الاسم هنا ليصبح SignupScreen بدلاً من SignUpScreen
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _role = 'patient';
  String? _selectedSpecialization;
  File? _imageFile;

  // قائمة التخصصات الطبية
  final List<String> _medicalSpecialties = [
    "General / عام",
    "Cardiology / أمراض القلب",
    "Dermatology / الجلدية",
    "Pediatrics / طب الأطفال",
    "Neurology / المخ والأعصاب",
    "Orthopedics / العظام",
    "Dentistry / طب الأسنان",
    "Ophthalmology / العيون",
  ];

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

    // التحقق من اختيار التخصص للطبيب
    if (_role == 'doctor' && _selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a specialization")),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    final error = await authProvider.signUpWithLocale(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _role,
      phone: _phoneController.text.trim().isEmpty ? "0000000000" : _phoneController.text.trim(),
      locale: languageProvider.languageCode,
      // إذا كان طبيب نأخذ التخصص المختار، وإلا نرسل قيمة فارغة
      specialization: _role == 'doctor' ? (_selectedSpecialization ?? "General") : "", 
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
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.signUp),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        // ✅ زر تغيير اللغة في الـ AppBar
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.primary),
            tooltip: l10n.selectLanguage,
            onSelected: (String code) {
              langProvider.changeLanguage(code);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'en', child: Text('🇺🇸 English')),
              const PopupMenuItem<String>(value: 'ar', child: Text('🇸🇦 العربية')),
              const PopupMenuItem<String>(value: 'ru', child: Text('🇷🇺 Русский')),
            ],
          ),
        ],
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
                label: "Phone Number / رقم الهاتف", 
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              // اختيار الدور
              DropdownButtonFormField<String>(
                value: _role,
                items: [
                  DropdownMenuItem(value: 'patient', child: Text(l10n.patient ?? "Patient")),
                  DropdownMenuItem(value: 'doctor', child: Text(l10n.doctor ?? "Doctor")),
                ],
                onChanged: isLoading ? null : (v) {
                  setState(() {
                    _role = v!;
                    if (_role == 'patient') _selectedSpecialization = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Role / الدور",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              
              // حقول إضافية للطبيب
              if (_role == 'doctor') ...[
                const SizedBox(height: 16),
                // ✅ خانة اختيار التخصص
                DropdownButtonFormField<String>(
                  value: _selectedSpecialization,
                  hint: const Text("Select Specialization / اختر التخصص"),
                  items: _medicalSpecialties.map((String specialty) {
                    return DropdownMenuItem(
                      value: specialty,
                      child: Text(specialty),
                    );
                  }).toList(),
                  onChanged: isLoading ? null : (v) => setState(() => _selectedSpecialization = v),
                  decoration: InputDecoration(
                    labelText: "Medical Specialization",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                  ),
                  validator: (v) => v == null ? "Required" : null,
                ),
                
                const SizedBox(height: 16),
                // ✅ خانة السعر بالروبل
                _buildTextField(
                  controller: _priceController,
                  label: "Consultation Price (₽) / سعر الاستشارة",
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
