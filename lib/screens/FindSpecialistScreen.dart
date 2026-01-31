import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'doctor_profile_view.dart'; // تأكد من مطابقة اسم الملف لديك

class FindSpecialistScreen extends StatefulWidget {
  const FindSpecialistScreen({super.key});

  @override
  State<FindSpecialistScreen> createState() => _FindSpecialistScreenState();
}

class _FindSpecialistScreenState extends State<FindSpecialistScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("البحث عن طبيب مختص", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "ابحث باسم الطبيب أو التخصص...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // قائمة الأطباء لجلب البيانات الحية من Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'doctor') // جلب الأطباء فقط
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا يوجد أطباء مسجلين حالياً"));
                }

                // تصفية البحث محلياً
                var doctors = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? "").toString().toLowerCase();
                  String spec = (data['specialization'] ?? "").toString().toLowerCase();
                  return name.contains(searchQuery) || spec.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    var data = doctors[index].data() as Map<String, dynamic>;
                    String docId = doctors[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        // عرض الصورة المرفوعة من الطبيب
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: (data['photoUrl'] != null && data['photoUrl'] != "")
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          child: (data['photoUrl'] == null || data['photoUrl'] == "")
                              ? const Icon(Icons.person, color: Colors.blue)
                              : null,
                        ),
                        title: Text(
                          "د. ${data['name'] ?? 'بدون اسم'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['specialization'] ?? "تخصص عام"),
                            const SizedBox(height: 5),
                            // عرض السعر المحدث
                            Text(
                              "سعر الكشف: ${data['price'] ?? '--'} DA",
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // الانتقال لشاشة البروفايل التي سألت عنها
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorProfileView(doctorId: docId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
