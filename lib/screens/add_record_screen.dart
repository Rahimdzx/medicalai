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
  
  final _patientNameController = TextEditingController();
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
      final patientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _patientEmailController.text.trim().toLowerCase())
          .where('role', isEqualTo: 'patient')
          .get();

      String patientId;

      if (patientQuery.docs.isEmpty) {
        final shouldCreate = await _showPatientNotFoundDialog();
        if (!shouldCreate) {
          setState(() => _isLoading = false);
          return;
        }
        
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
        content: const Text('Patient not found. Create a new patient record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
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
              // تم تعديل labelText هنا ليتجنب الخطأ
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name', 
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
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
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _diagnosisController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.diagnosis,
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter diagnosis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _prescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.prescription,
                  prefixIcon: const Icon(Icons.medication_outlined),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter prescription' : null,
              ),
              const SizedBox(height: 16),
              
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
