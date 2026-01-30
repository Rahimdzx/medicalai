import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // المتحكمات (Controllers)
  final _patientNameController = TextEditingController(); // تم إضافة الاسم
  final _patientEmailController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 1. البحث عن المريض بالبريد الإلكتروني
      final patientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _patientEmailController.text.trim().toLowerCase())
          .where('role', isEqualTo: 'patient')
          .get();

      String patientId;

      if (patientQuery.docs.isEmpty) {
        // إذا لم يوجد المريض، نسأل الطبيب هل يريد إنشاء سجل مؤقت؟
        final shouldCreate = await _showPatientNotFoundDialog();
        if (!shouldCreate) {
          setState(() => _isLoading = false);
          return;
        }
        
        // إنشاء مستخدم مريض جديد (Placeholder)
        final newPatientDoc = await FirebaseFirestore.instance.collection('users').add({
          'name': _patientNameController.text.trim(),
          'email': _patientEmailController.text.trim().toLowerCase(),
          'role': 'patient',
          'createdAt': FieldValue.serverTimestamp(),
          'createdByDoctor': authProvider.user!.uid,
          'isPlaceholder': true,
        });
        patientId = newPatientDoc.id;
      } else {
        patientId = patientQuery.docs.first.id;
      }

      // 2. حفظ السجل الطبي (Record)
      // التاريخ بتنسيق نصي للعرض السريع في البطاقة
      String formattedDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

      await FirebaseFirestore.instance.collection('records').add({
        'patientId': patientId,
        'patientEmail': _patientEmailController.text.trim().toLowerCase(),
        'patientName': _patientNameController.text.trim(),
        'doctorId': authProvider.user!.uid,
        'doctorEmail': authProvider.user!.email,
        'diagnosis': _diagnosisController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'date': formattedDate, 
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recordAdded), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showPatientNotFoundDialog() async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.patientNotFound),
        content: Text(l10n.createPatientQuestion ?? 'Patient not found. Create a new patient record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.create ?? 'Create')),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newRecord)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقل اسم المريض
              TextFormField(
                controller: _patientNameController,
                decoration: InputDecoration(
                  labelText: l10n.patientName ?? 'Patient Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // حقل البريد الإلكتروني
              TextFormField(
                controller: _patientEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.patientEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  hintText: 'patient@example.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.pleaseEnterEmail;
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // حقل التشخيص
              TextFormField(
                controller: _diagnosisController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.diagnosis,
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.isEmpty) ? l10n.pleaseEnterDiagnosis : null,
              ),
              const SizedBox(height: 16),
              
              // حقل الوصفة الطبية
              TextFormField(
                controller: _prescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.prescription,
                  prefixIcon: const Icon(Icons.medication_outlined),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.isEmpty) ? l10n.pleaseEnterPrescription : null,
              ),
              const SizedBox(height: 16),
              
              // حقل الملاحظات
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // أزرار التحكم
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveRecord,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
