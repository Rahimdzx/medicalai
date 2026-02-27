import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                int total = snapshot.data?.docs.length ?? 0;
                int doctors = 0;
                int patients = 0;

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final role = data['role'] as String? ?? 'patient';
                    if (role == 'doctor') doctors++;
                    if (role == 'patient') patients++;
                  }
                }

                return Row(
                  children: [
                    Expanded(child: _StatCard('Total Users', total.toString(), Colors.blue)),
                    Expanded(child: _StatCard('Doctors', doctors.toString(), Colors.teal)),
                    Expanded(child: _StatCard('Patients', patients.toString(), Colors.orange)),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            const Text('Doctors Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'doctor')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading doctors:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No doctors found'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                            child: data['photoUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(data['name'] ?? 'Unknown'),
                          subtitle: Text(data['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code, color: Colors.blue),
                                onPressed: () => _showQRCode(context, doc.id, data['name'] ?? 'Doctor'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDoctor(context, doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDoctorDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Doctor'),
      ),
    );
  }

  Widget _StatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context, String doctorId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR for $name'),
        content: SizedBox(
          width: 200,
          height: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: doctorId, size: 200),
              const Text('Scan to book', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _deleteDoctor(BuildContext context, String doctorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this doctor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(doctorId).delete();
        await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting doctor: $e')),
          );
        }
      }
    }
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final specialtyController = TextEditingController();
    final phoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Doctor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Specialty',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate inputs
                      if (nameController.text.trim().isEmpty ||
                          emailController.text.trim().isEmpty ||
                          passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all required fields')),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'role': 'doctor',
                          'createdAt': FieldValue.serverTimestamp(),
                          'isOnline': false,
                        });

                        await FirebaseFirestore.instance.collection('doctors').doc(cred.user!.uid).set({
                          'userId': cred.user!.uid,
                          'name': nameController.text.trim(),
                          'nameEn': nameController.text.trim(),
                          'nameAr': nameController.text.trim(),
                          'specialty': specialtyController.text.trim().isNotEmpty
                              ? specialtyController.text.trim()
                              : 'General',
                          'specialtyEn': specialtyController.text.trim().isNotEmpty
                              ? specialtyController.text.trim()
                              : 'General',
                          'specialtyAr': specialtyController.text.trim().isNotEmpty
                              ? specialtyController.text.trim()
                              : 'عام',
                          'price': 50,
                          'currency': 'RUB',
                          'rating': 5.0,
                          'doctorNumber': cred.user!.uid.substring(0, 8).toUpperCase(),
                          'isActive': true,
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Doctor added successfully')),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => isLoading = false);
                        String errorMsg = 'Error creating doctor';
                        if (e.code == 'email-already-in-use') {
                          errorMsg = 'Email is already registered';
                        } else if (e.code == 'invalid-email') {
                          errorMsg = 'Invalid email address';
                        } else if (e.code == 'weak-password') {
                          errorMsg = 'Password is too weak';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg)),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
