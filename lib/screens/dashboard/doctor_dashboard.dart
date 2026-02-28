import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/doctor_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../schedule_management_screen.dart';
import '../doctor_appointments_screen.dart';
import '../chat_list_screen.dart';
import '../doctor_profile_view.dart';
import '../auth/login_screen.dart';

/// Enhanced Doctor Dashboard with comprehensive features
/// 
/// Features:
/// - Real-time statistics cards
/// - Today's schedule with Moscow time
/// - Quick actions with working buttons
/// - Language toggle
/// - QR code generation
class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update time every minute
    Future.delayed(const Duration(seconds: 1), _updateTime);
    
    // Ensure doctor profile exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDoctorProfile();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() => _currentTime = DateTime.now());
      Future.delayed(const Duration(minutes: 1), _updateTime);
    }
  }

  Future<void> _ensureDoctorProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      await authProvider.ensureDoctorProfileExists(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context);
    final userName = authProvider.userName ?? 'Doctor';

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.exitApp),
            content: Text(l10n.exitAppConfirmation),
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
                child: Text(l10n.exit),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _selectedIndex == 0 ? l10n.doctorDashboard : l10n.profile,
          subtitle: _selectedIndex == 0 ? '${l10n.welcomeBack}, Dr. $userName' : null,
          showBackButton: false,
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade600],
          ),
          foregroundColor: Colors.white,
          actions: [
            // Language toggle
            IconButton(
              icon: Text(
                localeProvider.locale.languageCode.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _showLanguageSelector(context, localeProvider),
              tooltip: l10n.changeLanguage,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.notificationsComingSoon)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showSignOutConfirmation(context),
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardContent(context, authProvider),
            _buildProfileScreen(authProvider),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade600,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: l10n.dashboard,
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

  Widget _buildDashboardContent(BuildContext context, AuthProvider authProvider) {
    final doctorId = authProvider.user?.uid;
    final l10n = AppLocalizations.of(context);
    
    if (doctorId == null) {
      return Center(child: Text(l10n.notAuthenticated));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moscow Time Display
          _buildTimeDisplay(l10n),
          const SizedBox(height: 16),

          // Statistics Cards
          _buildStatsSection(authProvider, l10n),
          const SizedBox(height: 24),

          // Quick Actions
          _buildSectionTitle(l10n.quickActions),
          const SizedBox(height: 12),
          _buildQuickActions(context, l10n),
          const SizedBox(height: 24),

          // Today's Schedule
          _buildSectionTitle(l10n.todaySchedule),
          const SizedBox(height: 12),
          _buildTodaySchedule(authProvider, l10n),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(AppLocalizations l10n) {
    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final dateStr = DateFormat('EEEE, MMM d').format(_currentTime);

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moscowTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$timeStr - $dateStr',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(AuthProvider authProvider, AppLocalizations l10n) {
    final doctorId = authProvider.user?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        final appointments = snapshot.data?.docs ?? [];
        
        // Calculate stats
        final totalAppointments = appointments.length;
        
        final todayAppointments = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] as String?;
          return date == today;
        }).length;

        final completedToday = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] as String?;
          final status = data['status'] as String?;
          return date == today && status == 'completed';
        }).length;

        final pendingConsultations = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          return status == 'pending';
        }).length;

        // Calculate total earnings
        double totalEarnings = 0;
        for (var doc in appointments) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'completed') {
            totalEarnings += (data['price'] as num?)?.toDouble() ?? 0;
          }
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_today,
                    title: l10n.today,
                    value: todayAppointments.toString(),
                    color: Colors.blue,
                    subtitle: l10n.appointments,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions,
                    title: l10n.pending,
                    value: pendingConsultations.toString(),
                    color: Colors.orange,
                    subtitle: l10n.consultations,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    title: l10n.completed,
                    value: completedToday.toString(),
                    color: Colors.green,
                    subtitle: l10n.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.attach_money,
                    title: l10n.earnings,
                    value: '${totalEarnings.toStringAsFixed(0)}₽',
                    color: Colors.purple,
                    subtitle: l10n.total,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code,
                title: l10n.myQRCode,
                subtitle: l10n.shareWithPatients,
                color: Colors.purple,
                onTap: () => _showQRCode(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.calendar_today,
                title: l10n.schedule,
                subtitle: l10n.manageAvailability,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScheduleManagementScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.people,
                title: l10n.appointments,
                subtitle: l10n.viewAllBookings,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAppointmentsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.chat,
                title: l10n.messages,
                subtitle: l10n.patientChats,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatListScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(AuthProvider authProvider, AppLocalizations l10n) {
    final doctorId = authProvider.user?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: today)
          .orderBy('timeSlot')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.calendar_today,
            message: l10n.noScheduledAppointments,
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _AppointmentCard(
              patientName: data['patientName'] ?? 'Unknown Patient',
              date: data['date'] ?? 'No date',
              time: data['timeSlot'] ?? 'No time',
              status: data['status'] ?? 'pending',
              onTap: () {
                // Navigate to appointment details
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen(AuthProvider authProvider) {
    final doctorId = authProvider.user?.uid;
    final l10n = AppLocalizations.of(context);
    
    if (doctorId == null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        message: l10n.notAuthenticated,
      );
    }

    return FutureBuilder<DoctorModel?>(
      future: DoctorService().getDoctorById(doctorId),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state - with better error handling
        if (snapshot.hasError) {
          final errorMsg = snapshot.error.toString();
          
          // Check for permission error
          if (errorMsg.contains('permission-denied')) {
            return _buildProfilePermissionError(authProvider);
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    errorMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // No data - try to create profile
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildCreateProfilePrompt(doctorId, authProvider);
        }

        return DoctorProfileView(doctor: snapshot.data!);
      },
    );
  }

  Widget _buildProfilePermissionError(AuthProvider authProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.orange[300]),
          const SizedBox(height: 16),
          const Text(
            'Permission Denied',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Unable to access your profile. This might be because:\n\n'
              '1. Your account was just created\n'
              '2. Database permissions need to be updated\n\n'
              'Please try signing out and back in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => authProvider.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProfilePrompt(String doctorId, AuthProvider authProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add, size: 64, color: Colors.blue[300]),
          const SizedBox(height: 16),
          const Text(
            'Doctor Profile Not Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your doctor profile needs to be set up. Click the button below to create it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final success = await authProvider.ensureDoctorProfileExists(doctorId);
              
              if (mounted) {
                Navigator.pop(context); // Close loading dialog
                
                if (success) {
                  setState(() {}); // Refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to create profile. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Profile'),
          ),
        ],
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
              title: Text(l10n.russian),
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
              title: Text(l10n.arabic),
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

  void _showQRCode(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = authProvider.user?.uid ?? '';
    final doctorName = authProvider.userName ?? '';
    final l10n = AppLocalizations.of(context);

    // Create structured QR data
    final qrData = jsonEncode({
      'type': 'doctor',
      'doctorId': doctorId,
      'doctorName': doctorName,
      'version': '1.0',
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.yourQRCode),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: qrData,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shareQRWithPatients,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Doctor ID: ${doctorId.substring(0, doctorId.length > 8 ? 8 : doctorId.length)}...',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.shareFeatureComingSoon)),
              );
            },
            icon: const Icon(Icons.share),
            label: Text(l10n.share),
          ),
        ],
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

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Appointment Card Widget
class _AppointmentCard extends StatelessWidget {
  final String patientName;
  final String date;
  final String time;
  final String status;
  final VoidCallback? onTap;

  const _AppointmentCard({
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 20,
            child: const Icon(Icons.person, color: Colors.blue, size: 20),
          ),
          title: Text(
            patientName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            time,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
