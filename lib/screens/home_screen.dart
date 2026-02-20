import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/doctor_service.dart';
import '../doctor/doctor_profile_screen.dart';
import '../qr/qr_scan_screen.dart';
import 'specialist_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _doctorIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade800, Colors.blue.shade500],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.language, color: Colors.white),
                              onPressed: () => _showLanguageSelector(context, localeProvider),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white),
                              onPressed: () => authProvider.signOut(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          l10n.welcome,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          authProvider.userName ?? 'Patient',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildListDelegate([
                  _buildMenuCard(
                    icon: Icons.qr_code_scanner,
                    title: l10n.scanQr,
                    color: Colors.blue,
                    onTap: () => _showQrOptions(context),
                  ),
                  _buildMenuCard(
                    icon: Icons.medical_services,
                    title: l10n.myDoctors,
                    color: Colors.green,
                    onTap: () {
                      // Navigate to my consultations
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.search,
                    title: l10n.findSpecialist,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    icon: Icons.flight,
                    title: l10n.medicalTourism,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.scanQr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
              },
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.scanQr),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 20),
            const Divider(),
            TextField(
              controller: _doctorIdController,
              decoration: InputDecoration(
                labelText: l10n.enterDoctorId,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    if (_doctorIdController.text.isNotEmpty) {
                      Navigator.pop(context);
                      final doctor = await DoctorService()
                          .getDoctorByNumber(_doctorIdController.text.trim());
                      if (doctor != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, LocaleProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              onTap: () {
                provider.setLocale('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇷🇺'),
              title: const Text('Русский'),
              onTap: () {
                provider.setLocale('ru');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦'),
              title: const Text('العربية'),
              onTap: () {
                provider.setLocale('ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
