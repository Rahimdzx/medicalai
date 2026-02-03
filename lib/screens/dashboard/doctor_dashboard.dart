import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Imports for your project structure
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart'; // تأكد أن هذا الملف موجود كما في الكود السابق
import '../../l10n/app_localizations.dart';
import 'common/qr_share_scan_screen.dart'; // الملف الجديد الذي أنشأناه للـ QR

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specController = TextEditingController();
  final _feesController = TextEditingController();
  final _aboutController = TextEditingController();
  
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ملء البيانات الموجودة مسبقاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      // ملاحظة: هنا نفترض أن AuthProvider لديه دالة لجلب تفاصيل الطبيب الإضافية
      // إذا لم تكن موجودة، اعتمد على user.displayName
      _nameController.text = user?.displayName ?? "";
      // _specController.text = auth.doctorData['specialization'] ?? ""; 
      // _feesController.text = auth.doctorData['fees']?.toString() ?? "";
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specController.dispose();
    _feesController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      await auth.updateDoctorProfile(
        name: _nameController.text,
        specialization: _specController.text,
        fees: double.tryParse(_feesController.text) ?? 0.0,
        imageFile: _image,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileUpdatedSuccess ?? "Profile Updated Successfully"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context); // للترجمة
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.profileSettings ?? "Profile Settings"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // === 1. صورة البروفايل ===
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (user?.photoURL != null
                                      ? NetworkImage(user!.photoURL!) as ImageProvider
                                      : null),
                              child: (_image == null && user?.photoURL == null)
                                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.secondary,
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // === 2. قسم QR Code (الجديد) ===
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQRButton(
                              context,
                              icon: Icons.qr_code,
                              label: l10n.myQrCode ?? "My QR",
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) {
                                  return QRDisplayScreen(
                                    data: user?.uid ?? "NoID",
                                    title: user?.displayName ?? "Doctor",
                                    description: l10n.shareQrDescription ?? "Share this code with patients",
                                  );
                                }));
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildQRButton(
                              context,
                              icon: Icons.qr_code_scanner,
                              label: l10n.scanPatient ?? "Scan Patient",
                              color: AppColors.secondary,
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) {
                                  return const GeneralQRScanner(title: "Scan Patient QR");
                                }));
                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Scanned: $result")),
                                  );
                                  // TODO: Navigate to Patient Details using the result ID
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // === 3. حقول الإدخال ===
                    _buildTextField(
                      controller: _nameController,
                      label: l10n.fullName ?? "Full Name",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _specController,
                      label: l10n.specialization ?? "Specialization",
                      icon: Icons.medical_services_outlined,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _feesController,
                      label: l10n.consultationFee ?? "Consultation Fee",
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _aboutController,
                      label: l10n.aboutDoctor ?? "About Me",
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 40),

                    // === 4. زر الحفظ ===
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _saveProfile,
                        child: Text(
                          l10n.saveChanges ?? "Save Changes",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper Widget for TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondaryLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? "Required field" : null,
    );
  }

  // Helper Widget for QR Buttons
  Widget _buildQRButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
