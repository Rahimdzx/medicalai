import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'video_call_screen.dart'; 
import 'chat_screen.dart'; // تأكد من إنشاء هذا الملف كما في الرد السابق

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب معرف الطبيب الحالي
    final doctorId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("Appointments / Записи", style: TextStyle(fontSize: 18)),
            Text("المواعيد المستلمة", style: TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // مراقبة المواعيد الخاصة بالطبيب الحالي وترتيبها حسب الأحدث
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No appointments yet\nЗаписей пока нет\nلا توجد مواعيد حالياً",
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
              var docId = appointmentDoc.id; // معرف المستند الفريد (Channel Name)

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(appointment['status']).withOpacity(0.2),
                    child: Icon(Icons.person, color: _getStatusColor(appointment['status'])),
                  ),
                  title: Text(
                    appointment['patientName'] ?? 'Unknown Patient',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Status: ${appointment['status']}"),
                      Text("Price: ${appointment['price'] ?? '50'} USD"),
                    ],
                  ),
                  // قسم الأزرار الجانبية
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. زر الدردشة (متاح دائماً للتواصل مع المريض)
                      IconButton(
                        icon: const Icon(Icons.chat_outlined, color: Colors.orange, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                appointmentId: docId,
                                receiverName: appointment['patientName'] ?? 'Patient',
                              ),
                            ),
                          );
                        },
                      ),

                      // 2. زر الفيديو (يظهر فقط بعد تأكيد الموعد)
                      if (appointment['status'] == 'confirmed')
                        IconButton(
                          icon: const Icon(Icons.videocam, color: Colors.blue, size: 30),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoCallScreen(
                                  channelName: docId,
                                  token: "", // وضع الاختبار
                                ),
                              ),
                            );
                          },
                        ),

                      // 3. زر التأكيد (يظهر فقط إذا كان الموعد معلقاً)
                      if (appointment['status'] == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                          onPressed: () => _confirmAppointment(context, docId),
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

  // دالة لتحديد لون الحالة
  Color _getStatusColor(String? status) {
    if (status == 'pending') return Colors.orange;
    if (status == 'confirmed') return Colors.green;
    return Colors.grey;
  }

  // دالة تحديث حالة الموعد في Firestore
  Future<void> _confirmAppointment(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id).update({
        'status': 'confirmed'
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Confirmed / Подтверждено / تم التأكيد")),
        );
      }
    } catch (e) {
      debugPrint("Error updating appointment: $e");
    }
  }
}
