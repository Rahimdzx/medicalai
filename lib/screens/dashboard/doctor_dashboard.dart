import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/doctor_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../schedule_management_screen.dart';
import '../doctor_appointments_screen.dart';
import '../doctor_profile_screen.dart';
import '../auth/login_screen.dart';

/// Enhanced Doctor Dashboard with comprehensive features
/// 
/// Features:
/// - Real-time statistics cards
/// - Today's schedule with Moscow time
/// - Quick actions
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
  }

  void _updateTime() {
    if (mounted) {
      setState(() => _currentTime = DateTime.now());
      Future.delayed(const Duration(minutes: 1), _updateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userName = authProvider.userName ?? 'Doctor';

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _selectedIndex == 0 ? 'Dashboard' : 'Profile',
          subtitle: _selectedIndex == 0 ? 'Welcome back, Dr. $userName' : null,
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
              tooltip: 'Change Language',
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, AuthProvider authProvider) {
    final doctorId = authProvider.user?.uid;
    
    if (doctorId == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moscow Time Display
          _buildTimeDisplay(),
          const SizedBox(height: 16),

          // Statistics Cards
          _buildStatsSection(authProvider),
          const SizedBox(height: 24),

          // Quick Actions
          _buildSectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // Today's Schedule
          _buildSectionTitle("Today's Appointments"),
          const SizedBox(height: 12),
          _buildTodaySchedule(authProvider),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
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
                  'Moscow Time (MSK)',
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

  Widget _buildStatsSection(AuthProvider authProvider) {
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
                    title: 'Today',
                    value: todayAppointments.toString(),
                    color: Colors.blue,
                    subtitle: 'Appointments',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions,
                    title: 'Pending',
                    value: pendingConsultations.toString(),
                    color: Colors.orange,
                    subtitle: 'Consultations',
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
                    title: 'Completed',
                    value: completedToday.toString(),
                    color: Colors.green,
                    subtitle: 'Today',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.attach_money,
                    title: 'Earnings',
                    value: '${totalEarnings.toStringAsFixed(0)}₽',
                    color: Colors.purple,
                    subtitle: 'Total',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code,
                title: 'My QR Code',
                subtitle: 'Share with patients',
                color: Colors.purple,
                onTap: () => _showQRCode(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.calendar_today,
                title: 'Schedule',
                subtitle: 'Manage availability',
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
                title: 'Appointments',
                subtitle: 'View all bookings',
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
                title: 'Messages',
                subtitle: 'Patient chats',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAppointmentsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(AuthProvider authProvider) {
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
            message: 'No appointments scheduled for today',
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
    
    if (doctorId == null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        message: 'User not authenticated',
      );
    }

    return FutureBuilder<DoctorModel?>(
      future: DoctorService().getDoctorById(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState(
            icon: Icons.person_off,
            message: 'Failed to load profile',
          );
        }

        return DoctorProfileScreen(doctor: snapshot.data!);
      },
    );
  }

  void _showLanguageSelector(BuildContext context, LocaleProvider provider) {
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
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

  void _showQRCode(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = authProvider.user?.uid ?? '';
    final doctorName = authProvider.userName ?? '';

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
        title: const Row(
          children: [
            Icon(Icons.qr_code, color: Colors.blue),
            SizedBox(width: 8),
            Text('Your QR Code'),
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
            const Text(
              'Share this QR code with your patients\nto connect instantly',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
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
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
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
