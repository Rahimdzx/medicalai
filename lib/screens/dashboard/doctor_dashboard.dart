import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ تصحيح المسارات للوصول للمجلدات الصحيحة
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/colors.dart';

// ✅ تأكد أن هذا الملف موجود في هذا المسار ويحتوي على GeneralQRScanner و QRDisplayScreen
import '../common/qr_share_scan_screen.dart'; 

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  
  String formatCurrency(double amount, String locale) {
    if (locale == 'ru') return '${amount.toStringAsFixed(0)} ₽';
    if (locale == 'ar') return '${amount.toStringAsFixed(0)} ر.س';
    return '\$${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                            ? NetworkImage(auth.photoUrl!)
                            : null,
                        child: (auth.photoUrl == null || auth.photoUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.welcomeBack, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(auth.userName ?? "Dr. Unknown", 
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorProfileScreen()));
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // إحصائيات سريعة
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                           _StatItem(label: "Patients", value: "12"),
                           _StatItem(label: "Appts", value: "5"),
                           _StatItem(label: "Rating", value: "4.9"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // أزرار QR
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code, 
                            label: "My QR Code", 
                            color: Colors.blue,
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => QRDisplayScreen(
                                  data: auth.user?.uid ?? "error",
                                  title: auth.userName ?? "Doctor",
                                  description: "Scan to connect"
                               )));
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code_scanner, 
                            label: "Scan Patient", 
                            color: Colors.orange,
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneralQRScanner(title: "Scan Patient")));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});
  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _nameController = TextEditingController();
  final _feesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.userName ?? "";
    _feesController.text = auth.price ?? "0";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Settings")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
           const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
           const SizedBox(height: 20),
           TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
           const SizedBox(height: 15),
           TextField(controller: _feesController, decoration: const InputDecoration(labelText: "Consultation Fees")),
           const SizedBox(height: 30),
           ElevatedButton(
             onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.updateDoctorProfile(
                    name: _nameController.text,
                    specialization: "General",
                    fees: double.tryParse(_feesController.text) ?? 0,
                );
                if(mounted) Navigator.pop(context);
             },
             child: const Text("Save Changes"),
           )
        ],
      ),
    );
  }
}
