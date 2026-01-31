import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'qr_scanner_screen.dart';
import 'russia_programs_screen.dart';
import 'doctor_search_screen.dart'; // تأكد من استيراد الشاشة الجديدة
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          // إذا كان المستخدم مسجل دخول، يظهر أيقونة لوحة التحكم، وإلا يظهر أيقونة الدخول
          IconButton(
            icon: Icon(authProvider.user != null ? Icons.dashboard : Icons.person_outline),
            onPressed: () {
              if (authProvider.user != null) {
                // العودة للـ home في main.dart سيوجهه تلقائياً للوحة التحكم المناسبة
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(l10n),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  // 1. زر مسح QR
                  _buildMenuCard(
                    context,
                    title: l10n.scanQR,
                    icon: Icons.qr_code_scanner,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
                  ),
                  
                  // 2. زر استشارات الخبراء (معدل ليفتح قائمة الأطباء)
                  _buildMenuCard(
                    context,
                    title: l10n.specialistConsultations,
                    icon: Icons.medical_information,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const DoctorSearchScreen())
                      );
                    },
                  ),
                  
                  // 3. زر السياحة العلاجية
                  _buildMenuCard(
                    context,
                    title: "Medical Tourism", 
                    icon: Icons.travel_explore,
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RussiaProgramsScreen())),
                  ),
                  
                  // 4. زر سجلاتي الطبية (معدل للتحقق من تسجيل الدخول)
                  _buildMenuCard(
                    context,
                    title: l10n.myRecords,
                    icon: Icons.assignment,
                    color: Colors.orange,
                    onTap: () {
                      if (authProvider.user == null) {
                        _showLoginRequiredDialog(context, l10n);
                      } else {
                        // إذا كان مسجل دخول، يذهب للـ Dashboard
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            "${l10n.appTitle}\nExpert Medical Services",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.error),
        content: const Text("Login Required to view records\nيجب تسجيل الدخول لعرض السجلات"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            }, 
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }
}
