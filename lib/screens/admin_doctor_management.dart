import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDoctorManagement extends StatelessWidget {
  const AdminDoctorManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة الأطباء")),
      body: StreamBuilder<QuerySnapshot>(
        // جلب المستخدمين الذين دورهم "طبيب"
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا يوجد أطباء مسجلين حالياً"));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (data['photoUrl'] != null && data['photoUrl'] != "")
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: (data['photoUrl'] == null || data['photoUrl'] == "")
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(data['name'] ?? "بدون اسم"),
                  subtitle: Text(data['specialization'] ?? "لم يحدد التخصص"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الحذف
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, doc.id),
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

  // دالة تأكيد الحذف
  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف هذا الطبيب نهائياً؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
