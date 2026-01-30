import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

class DoctorProfileView extends StatelessWidget {
  final String doctorId;
  const DoctorProfileView({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordDetails),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // جلب بيانات الطبيب من Firestore باستخدام المعرف (ID)
        future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.userNotFound));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // القسم العلوي: الصورة والاسم والتخصص
                Center(
                  child: Column(
                    children: [
                      // عرض صورة الطبيب أو أيقونة افتراضية إذا لم تتوفر الصورة
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: (data['photoUrl'] != null && data['photoUrl'] != "")
                            ? NetworkImage(data['photoUrl'])
                            : null,
                        child: (data['photoUrl'] == null || data['photoUrl'] == "")
                            ? const Icon(Icons.person, size: 60, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Dr. ${data['name'] ?? ''}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      // عرض التخصص
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['specialization'] ?? l10n.doctor,
                          style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // تفاصيل الكشفية والمواعيد
                _infoRow(
                  Icons.payments_outlined, 
                  "Consultation Fee / Стоимость", 
                  "${data['price'] ?? '50'} USD",
                  Colors.green
                ),
                const Divider(height: 30),
                _infoRow(
                  Icons.calendar_month_outlined, 
                  "Schedule / График работы", 
                  data['schedule'] ?? "Available Now / Доступно сейчас",
                  Colors.blue
                ),
                const Divider(height: 30),
                _infoRow(
                  Icons.language_outlined, 
                  "Languages / Языки", 
                  "English, Russian, Arabic",
                  Colors.orange
                ),

                const SizedBox(height: 50),

                // زر الحجز (يتطلب تسجيل دخول)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // هنا نوجه المستخدم لصفحة تسجيل الدخول لإتمام عملية الحجز والدفع
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: Text(
                      "${l10n.login} & Book Now", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ودجت مخصصة لعرض صفوف المعلومات بشكل منسق
  Widget _infoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 2),
              Text(
                value, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ],
          ),
        ),
      ],
    );
  }
}
