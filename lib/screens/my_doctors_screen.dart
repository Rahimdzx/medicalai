import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/doctor_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widgets.dart';
import 'doctor_profile_screen.dart';

/// My Doctors Screen with professional UI and back button
/// 
/// Features:
/// - Back button navigation
/// - Loading states
/// - Empty state handling
/// - Error handling with retry
class MyDoctorsScreen extends StatelessWidget {
  const MyDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final patientId = authProvider.user?.uid;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Doctors',
        showBackButton: true,
      ),
      body: patientId == null
          ? const ErrorState(
              message: 'Please login to view your doctors',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientId', isEqualTo: patientId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return ErrorState(
                    message: 'Failed to load your doctors. Please try again.',
                    onRetry: () {
                      // Trigger rebuild by invalidating the stream
                      (context as Element).markNeedsBuild();
                    },
                  );
                }

                // Empty state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.medical_services,
                    title: 'No doctors yet',
                    message: 'Book an appointment to see your doctors here',
                    actionLabel: 'Find Doctors',
                    onAction: () => Navigator.pop(context),
                  );
                }

                final appointments = snapshot.data!.docs;
                
                // Get unique doctors from appointments
                final doctorIds = appointments
                    .map((doc) => (doc.data() as Map<String, dynamic>)['doctorId'] as String?)
                    .where((id) => id != null)
                    .toSet()
                    .toList();

                if (doctorIds.isEmpty) {
                  return const EmptyState(
                    icon: Icons.medical_services,
                    title: 'No doctors found',
                    message: 'Your appointments don\'t have valid doctor information',
                  );
                }

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
                        // Loading state for individual doctor
                        if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                          return const CardSkeletonLoading();
                        }

                        // Skip if doctor not found
                        if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        try {
                          final doctor = DoctorModel.fromFirestore(doctorSnapshot.data!);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorProfileScreen(doctor: doctor),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Doctor Avatar
                                    Hero(
                                      tag: 'doctor_${doctor.id}',
                                      child: CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Colors.green.shade100,
                                        backgroundImage: doctor.photo != null
                                            ? NetworkImage(doctor.photo!)
                                            : null,
                                        child: doctor.photo == null
                                            ? Icon(Icons.person, size: 32, color: Colors.green.shade700)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Doctor Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dr. ${doctor.name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            doctor.specialty,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${doctor.rating}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(Icons.attach_money, size: 16, color: Colors.green.shade700),
                                              Text(
                                                '${doctor.price}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Action Button
                                    ElevatedButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DoctorProfileScreen(doctor: doctor),
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: const Text('View'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          // Handle parsing errors gracefully
                          return const SizedBox.shrink();
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
