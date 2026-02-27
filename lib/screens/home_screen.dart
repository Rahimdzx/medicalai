import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/doctor_service.dart';
import '../widgets/custom_app_bar.dart';
import 'doctor_profile_screen.dart';
import 'common/qr_share_scan_screen.dart';
import 'specialist_list_screen.dart';
import 'my_doctors_screen.dart';
import 'medical_tourism_screen.dart';
import 'patient_dashboard.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

/// Enhanced Home Screen (Patient Dashboard) with professional UI
/// 
/// Features:
/// - Professional gradient app bar
/// - Bottom navigation for main sections
/// - Quick action cards
/// - Back button handling
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _doctorIdController = TextEditingController();

  @override
  void dispose() {
    _doctorIdController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const _HomeContent(),
    const PatientDashboard(),
    const MyDoctorsScreen(),
    const _ProfileContent(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        // Show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.logout),
            content: Text('${l10n.logout} MedicalAI?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.yes),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.patientDashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.folder_outlined),
              activeIcon: const Icon(Icons.folder),
              label: l10n.myRecords,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outlined),
              activeIcon: const Icon(Icons.people),
              label: l10n.myDoctors,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Content Widget
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context);
    final userName = authProvider.userName ?? l10n.patient;

    return CustomScrollView(
      slivers: [
        // App Bar
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.welcomeBack,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.language, color: Colors.white),
                                onPressed: () => _showLanguageSelector(context, localeProvider),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () {
                                  // TODO: Show notifications
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Quick Actions Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quickActions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _ActionCard(
                      icon: Icons.qr_code_scanner,
                      title: l10n.scanQR,
                      subtitle: l10n.connectWithDoctor,
                      color: Colors.blue,
                      onTap: () => _showQrOptions(context),
                    ),
                    _ActionCard(
                      icon: Icons.search,
                      title: l10n.findDoctor,
                      subtitle: l10n.findSpecialist,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.medical_services,
                      title: l10n.myDoctors,
                      subtitle: l10n.viewYourDoctors,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyDoctorsScreen()),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.flight,
                      title: l10n.medicalTourism,
                      subtitle: l10n.medicalTourismDesc,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicalTourismScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Recent Activity
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recentActivity,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: View all activity
                      },
                      child: Text(l10n.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecentActivityPlaceholder(context),
              ],
            ),
          ),
        ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildRecentActivityPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.history, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                l10n.noRecentActivity,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrOptions(BuildContext context) {
    final doctorIdController = TextEditingController();
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.connectWithDoctor,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scanQrOrEnterId,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrShareScanScreen()),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.scanQR),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: doctorIdController,
                decoration: InputDecoration(
                  labelText: l10n.enterDoctorId,
                  hintText: l10n.doctorIdHint,
                  prefixIcon: const Icon(Icons.person_search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      if (doctorIdController.text.isNotEmpty) {
                        Navigator.pop(context);
                        final doctor = await DoctorService()
                            .getDoctorByNumber(doctorIdController.text.trim());
                        if (doctor != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorProfileScreen(doctor: doctor),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.doctorNotFound),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, LocaleProvider provider) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectLanguage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n.english),
              trailing: provider.locale.languageCode == 'en'
                  ? Icon(Icons.check, color: Colors.blue.shade700)
                  : null,
              onTap: () {
                provider.setLocale('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
              title: const Text('Русский'),
              trailing: provider.locale.languageCode == 'ru'
                  ? Icon(Icons.check, color: Colors.blue.shade700)
                  : null,
              onTap: () {
                provider.setLocale('ru');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: const Text('العربية'),
              trailing: provider.locale.languageCode == 'ar'
                  ? Icon(Icons.check, color: Colors.blue.shade700)
                  : null,
              onTap: () {
                provider.setLocale('ar');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Profile Content Widget
class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.profile,
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, size: 50, color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.userName ?? l10n.user,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (authProvider.userRole ?? l10n.patient).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings List
            _SettingsSection(
              title: l10n.account,
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  title: l10n.editProfile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: l10n.changePassword,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SettingsSection(
              title: l10n.preferences,
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _SettingsItem(
                  icon: Icons.language,
                  title: l10n.language,
                  trailing: Text(l10n.english),
                  onTap: () {
                    // TODO: Show language selector
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SettingsSection(
              title: l10n.support,
              items: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: l10n.helpCenter,
                  onTap: () {
                    // TODO: Navigate to help
                  },
                ),
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: l10n.about,
                  onTap: () {
                    // TODO: Show about dialog
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSignOutConfirmation(context),
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.signOut),
          ],
        ),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
    }
  }
}

/// Action Card Widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings Section Widget
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(entry.value.icon, color: Colors.blue.shade700),
                    title: Text(entry.value.title),
                    trailing: entry.value.trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: entry.value.onTap,
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 56, color: Colors.grey.shade200),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Settings Item
class _SettingsItem {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });
}
