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
                    final role = doc['role'] ?? 'patient';
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
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

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
                                onPressed: () => _showQRCode(context, doc.id, data['name']),
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
            Text(title, style: TextStyle(color: color)),
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
      await FirebaseFirestore.instance.collection('users').doc(doctorId).delete();
      await FirebaseFirestore.instance.collection('doctors').doc(doctorId).delete();
    }
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final specialtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Doctor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(controller: specialtyController, decoration: const InputDecoration(labelText: 'Specialty')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );

                await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'role': 'doctor',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance.collection('doctors').doc(cred.user!.uid).set({
                  'userId': cred.user!.uid,
                  'name': nameController.text.trim(),
                  'nameEn': nameController.text.trim(),
                  'nameAr': nameController.text.trim(),
                  'specialty': specialtyController.text.trim(),
                  'specialtyEn': specialtyController.text.trim(),
                  'specialtyAr': specialtyController.text.trim(),
                  'price': 50,
                  'currency': 'RUB',
                  'rating': 5.0,
                  'doctorNumber': cred.user!.uid.substring(0, 8).toUpperCase(),
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
