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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "You haven't booked any appointments\nУ вас нет записей\nلم تقم بحجز أي مواعيد بعد",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
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
              var status = appointment['status'] ?? 'pending';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    // Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status).withOpacity(0.2),
                        child: Icon(Icons.medical_services, color: _getStatusColor(status)),
                      ),
                      title: Text(
                        "Doctor: ${appointment['doctorName'] ?? 'General Doctor'}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text("Date: ${appointment['date'] ?? 'Not set'}"),
                          Text("Time: ${appointment['timeSlot'] ?? 'Not set'}"),
                          if (status == 'pending') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Waiting for doctor approval',
                                    style: TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (status == 'confirmed') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'You can now chat with doctor',
                                    style: TextStyle(fontSize: 12, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر الدردشة - متاح دائماً لكن يُفضل استخدامه بعد التأكيد
                          IconButton(
                            icon: Icon(
                              Icons.chat_outlined,
                              color: status == 'confirmed' ? Colors.green : Colors.orange,
                              size: 28,
                            ),
                            tooltip: status == 'confirmed' 
                                ? 'Chat with doctor' 
                                : 'Chat (waiting for approval)',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: docId,
                                    appointmentId: docId,
                                    receiverName: appointment['doctorName'] ?? 'Doctor',
                                  ),
                                ),
                              );
                            },
                          ),

                          // زر الفيديو يظهر فقط بعد تأكيد الموعد
                          if (status == 'confirmed')
                            IconButton(
                              icon: const Icon(Icons.videocam, color: Colors.blue, size: 30),
                              tooltip: 'Start video call',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoCallScreen(
                                      channelName: docId,
                                      token: "",
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval / В ожидании / في انتظار الموافقة';
      case 'confirmed':
        return 'Confirmed / Подтверждено / تم التأكيد';
      case 'rejected':
        return 'Rejected / Отклонено / مرفوض';
      case 'completed':
        return 'Completed / Завершено / مكتمل';
      default:
        return 'Unknown / Неизвестно / غير معروف';
    }
  }
}
