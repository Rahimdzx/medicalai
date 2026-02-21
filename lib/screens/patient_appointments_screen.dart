import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'video_call_screen.dart';
import 'chat_screen.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب معرف المريض الحالي
    final patientId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("My Appointments / Мои записи", style: TextStyle(fontSize: 18)),
            Text("مواعيدي المحجوزة", style: TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب المواعيد التي قام هذا المريض بحجزها
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
              child: Text(
                "You haven't booked any appointments\nУ вас нет записей\nلم تقم بحجز أي مواعيد بعد",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var appointmentDoc = snapshot.data!.docs[index];
              var appointment = appointmentDoc.data() as Map<String, dynamic>;
              var docId = appointmentDoc.id; // نفس الـ ID المستخدم عند الطبيب

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(appointment['status']).withOpacity(0.2),
                    child: Icon(Icons.medical_services, color: _getStatusColor(appointment['status'])),
                  ),
                  title: Text(
                    "Doctor: ${appointment['doctorName'] ?? 'General Doctor'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Status: ${appointment['status']}"),
                      Text("Date: ${appointment['appointmentDate'] ?? 'Not set'}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الدردشة لإرسال التقارير (متاح دائماً للمريض)
                      IconButton(
                        icon: const Icon(Icons.chat_outlined, color: Colors.orange, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: '${appointment['patientId']}_${appointment['doctorId']}',
                                appointmentId: docId,
                                receiverName: appointment['doctorName'] ?? 'Doctor',
                                isRadiology: false,
                              ),
                            ),
                          );
                        },
                      ),

                      // زر الفيديو يظهر للمريض فقط إذا وافق الطبيب (confirmed)
                      if (appointment['status'] == 'confirmed')
                        IconButton(
                          icon: const Icon(Icons.videocam, color: Colors.blue, size: 30),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoCallScreen(
                                  channelName: docId, // نفس الغرفة
                                  token: "",
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'pending') return Colors.orange;
    if (status == 'confirmed') return Colors.green;
    return Colors.grey;
  }
}
