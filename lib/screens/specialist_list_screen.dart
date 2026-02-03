import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart'; // تأكد من مسار ملف الألوان
import 'doctor_booking_screen.dart'; // تأكد من أنك تملك ملف الحجز الذي أنشأناه سابقاً

class SpecialistListScreen extends StatelessWidget {
  const SpecialistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // خلفية رمادية فاتحة عصرية
      appBar: AppBar(
        title: const Text("Select Specialist", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // البحث عن المستخدمين الذين دورهم 'doctor'
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor') 
            .snapshots(),
        builder: (context, snapshot) {
          // 1. حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. حالة الخطأ
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. حالة عدم وجود أطباء
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("No doctors found", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  // نصيحة للمطور للتأكد من البيانات
                  const Text("(Check Firestore: role = 'doctor')", style: TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ),
            );
          }

          var doctors = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var doc = doctors[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // الحصول على التصميم (لون + أيقونة) بناءً على التخصص
              var uiData = _getSpecialtyUI(data['specialization']);

              return GestureDetector(
                onTap: () {
                  // عند الضغط، نذهب لصفحة الحجز ونأخذ معنا رقم الطبيب (ID)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorBookingScreen(doctorId: doc.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // حواف دائرية ناعمة
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // === الأيقونة الملونة (بديل الصور) ===
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: uiData['color'].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          uiData['icon'],
                          color: uiData['color'],
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // === المعلومات ===
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'Doctor Name',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              data['specialization'] ?? 'General Specialist',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            // السعر والتقييم
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "\$ ${data['price'] ?? '50'}",
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.star, color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                const Text("4.9", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
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

  // دالة لتحديد الألوان والأيقونات حسب التخصص
  Map<String, dynamic> _getSpecialtyUI(String? specialization) {
    String s = (specialization ?? "").toLowerCase();
    
    if (s.contains('dentist')) {
      return {'icon': Icons.favorite_border, 'color': Colors.teal}; // أسنان
    } else if (s.contains('urolo')) { 
      return {'icon': Icons.water_drop_outlined, 'color': Colors.blue}; // مسالك
    } else if (s.contains('gyneco')) { 
      return {'icon': Icons.pregnant_woman, 'color': Colors.pinkAccent}; // نسائية
    } else if (s.contains('onco')) { 
      return {'icon': Icons.health_and_safety_outlined, 'color': Colors.purple}; // أورام
    } else if (s.contains('heart') || s.contains('cardio')) {
      return {'icon': Icons.favorite, 'color': Colors.redAccent}; // قلب
    } else if (s.contains('eye') || s.contains('opht')) {
      return {'icon': Icons.visibility, 'color': Colors.orange}; // عيون
    }
    
    // الافتراضي (عام)
    return {'icon': Icons.medical_services_outlined, 'color': AppColors.primary};
  }
}
