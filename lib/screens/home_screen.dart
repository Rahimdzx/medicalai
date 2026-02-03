import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart'; // ✅ إضافة مزود اللغة
import 'russia_programs_screen.dart';

// ✅ تصحيح المسارات (تأكد من وجود هذه الملفات في المجلدات المذكورة)
import 'auth/login_screen.dart'; 
import 'common/qr_share_scan_screen.dart'; 
import 'specialist_list_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        // ✅ إضافة زر تغيير اللغة في جهة اليسار (أو اليمين حسب اتجاه اللغة)
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.language, color: Colors.blue),
          tooltip: l10n.selectLanguage,
          onSelected: (String code) {
            languageProvider.changeLanguage(Locale(code));
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'en',
              child: Text('🇺🇸 English'),
            ),
            const PopupMenuItem<String>(
              value: 'ar',
              child: Text('🇸🇦 العربية'),
            ),
            const PopupMenuItem<String>(
              value: 'ru',
              child: Text('🇷🇺 Русский'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(authProvider.user != null ? Icons.dashboard : Icons.person_outline),
            onPressed: () {
              if (authProvider.user != null) {
                // إذا كان مسجلاً، يمكن توجيهه للوحة التحكم الخاصة به
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const LoginScreen())
                );
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
                  // 1. زر مسح الـ QR
                  _buildMenuCard(
                    context,
                    title: l10n.scanQR,
                    icon: Icons.qr_code_scanner,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const GeneralQRScanner(title: "Scan QR"))
                    ),
                  ),
                  
                  // 2. قائمة الأطباء والاستشارات
                  _buildMenuCard(
                    context,
                    title: l10n.specialistConsultations,
                    icon: Icons.medical_information,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const SpecialistListScreen())
                    ),
                  ),
                  
                  // 3. السياحة العلاجية (روسيا)
                  _buildMenuCard(
                    context,
                    title: l10n.medicalTourism, 
                    icon: Icons.travel_explore,
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const RussiaProgramsScreen())
                    ),
                  ),
                  
                  // 4. السجلات الطبية (تحتاج تسجيل دخول)
                  _buildMenuCard(
                    context,
                    title: l10n.myRecords,
                    icon: Icons.assignment,
                    color: Colors.orange,
                    onTap: () {
                      if (authProvider.user == null) {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => const LoginScreen())
                         );
                      } else {
                        // توجيه للسجلات إذا كان مسجل دخول
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30)
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 22, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.welcome, // تأكد من وجود مفتاح welcome في ملف الترجمة
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ],
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
              child: Text(
                title, 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
