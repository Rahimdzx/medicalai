import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/doctor_model.dart';
import 'doctor_profile_screen.dart';

class MyDoctorsScreen extends StatelessWidget {
  const MyDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final patientId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doctors'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: patientId == null
          ? const Center(child: Text('Please login to view your doctors'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientId', isEqualTo: patientId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No doctors yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Book an appointment to see your doctors here',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final appointments = snapshot.data!.docs;
                
                // Get unique doctors from appointments
                final doctorIds = appointments
                    .map((doc) => (doc.data() as Map<String, dynamic>)['doctorId'] as String)
                    .toSet()
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctorIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(doctorIds[index])
                          .get(),
                      builder: (context, doctorSnapshot) {
                        if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final doctor = DoctorModel.fromFirestore(doctorSnapshot.data!);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: doctor.photo != null
                                  ? NetworkImage(doctor.photo!)
                                  : null,
                              child: doctor.photo == null
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            title: Text(
                              'Dr. ${doctor.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctor.specialty),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    Text(' ${doctor.rating}'),
                                  ],
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorProfileScreen(doctor: doctor),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Book'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
