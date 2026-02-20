import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isRTL = localeProvider.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
            tooltip: l10n.logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.overview,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildStatsOverview(),
              const SizedBox(height: 25),
              Text(
                l10n.managementOptions,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildAdminOption(
                      context,
                      l10n.doctorManagement,
                      l10n.manageDoctorsDesc,
                      Icons.medical_services,
                      Colors.teal,
                      () => _showDoctorManagement(context),
                    ),
                    _buildAdminOption(
                      context,
                      l10n.patientManagement,
                      l10n.managePatientsDesc,
                      Icons.person,
                      Colors.orange,
                      () {},
                    ),
                    _buildAdminOption(
                      context,
                      l10n.allAppointments,
                      l10n.viewAllAppointments,
                      Icons.calendar_today,
                      Colors.red,
                      () => _showAllAppointments(context),
                    ),
                    _buildAdminOption(
                      context,
                      l10n.legalDocuments,
                      l10n.editLegalDocs,
                      Icons.gavel,
                      Colors.purple,
                      () => _showLegalDocumentsEditor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDoctorDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addDoctor),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        int totalUsers = snapshot.data?.docs.length ?? 0;
        int doctors = 0;
        int patients = 0;
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final role = doc['role'] ?? 'patient';
            if (role == 'doctor') doctors++;
            if (role == 'patient') patients++;
          }
        }

        return Row(
          children: [
            Expanded(child: _StatCard(l10n.totalUsers, totalUsers.toString(), Icons.people, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(l10n.doctors, doctors.toString(), Icons.medical_services, Colors.teal)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(l10n.patients, patients.toString(), Icons.person, Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _buildAdminOption(
    BuildContext context, 
    String title, 
    String subtitle,
    IconData icon, 
    Color color, 
    VoidCallback onTap
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showDoctorManagement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: true,
        builder: (context, scrollController) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.doctorManagement),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'doctor')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                controller: scrollController,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: data['photoUrl'] != null
                          ? NetworkImage(data['photoUrl'])
                          : null,
                      child: data['photoUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(data['name'] ?? 'Unknown'),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.blue),
                          onPressed: () => _showDoctorQR(context, doc.id, data['name']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDoctor(context, doc.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDoctorQR(BuildContext context, String doctorId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code for $name'),
        content: SizedBox(
          width: 200,
          height: 250,
          child: Column(
            children: [
              QrImageView(
                data: doctorId,
                size: 200,
                version: QrVersions.auto,
              ),
              const SizedBox(height: 10),
              const Text('Scan to book appointment', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDoctor(BuildContext context, String doctorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this doctor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(doctorId).delete();
      await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
    }
  }

  void _showAddDoctorDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final specialtyController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addDoctor),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.fullName),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: l10n.password),
                obscureText: true,
              ),
              TextField(
                controller: specialtyController,
                decoration: InputDecoration(labelText: l10n.specialty),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: l10n.price),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Create auth user
                final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );

                // Create user document
                await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'role': 'doctor',
                  'specialization': specialtyController.text.trim(),
                  'price': double.tryParse(priceController.text) ?? 0,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Create doctor profile
                await FirebaseFirestore.instance.collection('doctors').doc(cred.user!.uid).set({
                  'userId': cred.user!.uid,
                  'name': nameController.text.trim(),
                  'nameEn': nameController.text.trim(),
                  'nameAr': nameController.text.trim(),
                  'specialty': specialtyController.text.trim(),
                  'specialtyEn': specialtyController.text.trim(),
                  'specialtyAr': specialtyController.text.trim(),
                  'price': double.tryParse(priceController.text) ?? 0,
                  'currency': 'USD',
                  'rating': 5.0,
                  'doctorNumber': cred.user!.uid.substring(0, 8).toUpperCase(),
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAllAppointments(BuildContext context) {
    // Implementation for viewing all appointments
  }

  void _showLegalDocumentsEditor(BuildContext context) {
    // Implementation for editing legal documents
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
