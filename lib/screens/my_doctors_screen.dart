import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/doctor_model.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'doctor_profile_screen.dart';

class MyDoctorsScreen extends StatelessWidget {
  const MyDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDoctors),
      ),
      body: userId == null
          ? _buildNotLoggedIn(context, l10n)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context, l10n);
                }

                // Get unique doctors from appointments
                final doctorIds = snapshot.data!.docs
                    .map((doc) => doc['doctorId'] as String)
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
                        final appointment = snapshot.data!.docs
                            .firstWhere((doc) => doc['doctorId'] == doctor.id);

                        return _DoctorCard(
                          doctor: doctor,
                          appointmentData: appointment.data() as Map<String, dynamic>,
                          appointmentId: appointment.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.registrationRequired,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loginRequiredMessage,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            l10n.noConsultationsYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first consultation with a specialist',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: Text(l10n.findSpecialist),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final Map<String, dynamic> appointmentData;
  final String appointmentId;

  const _DoctorCard({
    required this.doctor,
    required this.appointmentData,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = appointmentData['status'] ?? 'confirmed';
    final isPaid = appointmentData['isPaid'] ?? false;
    final date = appointmentData['date'] ?? '';
    final timeSlot = appointmentData['timeSlot'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfileScreen(doctor: doctor),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: doctor.photo != null ? NetworkImage(doctor.photo!) : null,
                    child: doctor.photo == null ? const Icon(Icons.person, size: 32) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            Text(' ${doctor.rating}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment: $date',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Time: $timeSlot',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  _buildStatusChip(status, isPaid),
                ],
              ),
              if (isPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(context),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Open Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isPaid) {
    Color color;
    String text;

    switch (status) {
      case 'confirmed':
        color = isPaid ? Colors.green : Colors.orange;
        text = isPaid ? 'Paid' : 'Pending';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    // Create or get existing chat
    final chatId = '${appointmentData['patientId']}_${doctor.id}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          receiverName: 'Dr. ${doctor.name}',
          appointmentId: appointmentId,
          isRadiology: doctor.specialty.toLowerCase().contains('radiology') ||
              doctor.specialty.toLowerCase().contains('أشعة') ||
              doctor.specialty.toLowerCase().contains('рентген'),
        ),
      ),
    );
  }
}
