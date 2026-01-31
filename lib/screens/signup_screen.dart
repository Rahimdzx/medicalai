import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
  
  String _role = 'patient';
  String? _selectedSpecialization;
  bool _isLoading = false;

  final List<String> _specializations = [
    "General Practice (ممارس عام)",
    "Cardiology (قلب)",
    "Dermatology (جلدية)",
    "Pediatrics (أطفال)",
    "Orthopedics (عظام)",
    "Neurology (مخ وأعصاب)",
    "Psychiatry (طب نفسي)",
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'doctor' && _selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء اختيار التخصص")));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _role,
      phone: _phoneController.text.trim(),
      specialization: _selectedSpecialization ?? "",
    );

    setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primaryColor = const Color(0xFF007BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.signUp, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("أنشئ حسابك الطبي", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              Text("انضم إلى آلاف المستخدمين والأطباء اليوم", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),

              _buildFieldTitle("المعلومات الأساسية"),
              _buildInputContainer(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.person_outline), border: InputBorder.none),
                  validator: (val) => val == null || val.isEmpty ? l10n.pleaseEnterName : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputContainer(
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined), border: InputBorder.none),
                  validator: (val) => val == null || !val.contains('@') ? l10n.invalidEmail : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputContainer(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock_outline), border: InputBorder.none),
                  validator: (val) => val == null || val.length < 6 ? l10n.passwordTooShort : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputContainer(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phoneOptional, prefixIcon: const Icon(Icons.phone_android), border: InputBorder.none),
                ),
              ),
              
              const SizedBox(height: 24),
              _buildFieldTitle("نوع الحساب"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _role,
                    items: [
                      DropdownMenuItem(value: 'patient', child: Text(l10n.patient)),
                      DropdownMenuItem(value: 'doctor', child: Text(l10n.doctor)),
                    ],
                    onChanged: (val) => setState(() => _role = val!),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),

              if (_role == 'doctor') ...[
                const SizedBox(height: 24),
                _buildFieldTitle("التخصص الطبي"),
                _buildInputContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSpecialization,
                      hint: const Text("اختر تخصصك"),
                      items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedSpecialization = val),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.medical_services_outlined), border: InputBorder.none),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(l10n.signUp, style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }
}
