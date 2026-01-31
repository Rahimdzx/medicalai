import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_doctor_management.dart'; // تأكد من إنشاء هذا الملف كما في الرد السابق

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم المدير"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
            tooltip: "تسجيل الخروج",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "الإحصائيات العامة",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildStatCard("إجمالي المستخدمين", Icons.people, Colors.blue),
              const SizedBox(height: 25),
              const Text(
                "خيارات الإدارة",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildAdminOption(
                      context,
                      "إدارة الأطباء",
                      "حذف، تعديل، أو قبول الأطباء الجدد",
                      Icons.medical_services,
                      Colors.teal,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDoctorManagement()),
                      ),
                    ),
                    _buildAdminOption(
                      context,
                      "إدارة المرضى",
                      "عرض وحذف حسابات المرضى",
                      Icons.person,
                      Colors.orange,
                      () {
                        // يمكنك إضافة شاشة إدارة المرضى هنا لاحقاً
                      },
                    ),
                    _buildAdminOption(
                      context,
                      "جميع المواعيد",
                      "مراقبة المواعيد الجارية والسابقة",
                      Icons.calendar_today,
                      Colors.red,
                      () {},
                    ),
                    _buildAdminOption(
                      context,
                      "إعدادات التطبيق",
                      "تعديل نصوص التطبيق والأسعار العامة",
                      Icons.settings,
                      Colors.grey,
                      () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت عرض الإحصائيات (مربوط بـ Firestore لحظياً)
  Widget _buildStatCard(String title, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("$count", style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(icon, color: Colors.white.withOpacity(0.4), size: 60),
            ],
          ),
        );
      },
    );
  }

  // ودجت خيارات القائمة
  Widget _buildAdminOption(
    BuildContext context, 
    String title, 
    String subtitle,
    IconData icon, 
    Color color, 
    VoidCallback onTap
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
