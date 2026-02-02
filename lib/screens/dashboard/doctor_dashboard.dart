import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/colors.dart';
import '../../widgets/language_selector.dart';
import '../chat_screen.dart';
import '../video_call_screen.dart';
import '../doctor_appointments_screen.dart';

/// Professional Doctor Dashboard with statistics and appointments
/// Configured for Moscow Time (MSK) and Russian locale
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  // Moscow Time Zone offset (UTC+3)
  static const int moscowTimeOffset = 3;

  /// Get current Moscow time
  DateTime get moscowTime {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: moscowTimeOffset));
  }

  /// Format currency in Russian locale (e.g., 1 500,00 ₽)
  String formatRubPrice(double amount, String locale) {
    if (locale == 'ru') {
      final formatter = NumberFormat.currency(
        locale: 'ru_RU',
        symbol: '₽',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } else if (locale == 'ar') {
      final formatter = NumberFormat.currency(
        locale: 'ar_SA',
        symbol: 'ر.س',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    }
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Format date/time in Moscow time
  String formatMoscowDateTime(DateTime dateTime, String locale) {
    // Convert to Moscow time if needed
    final mskTime = dateTime.toUtc().add(const Duration(hours: moscowTimeOffset));

    if (locale == 'ru') {
      return DateFormat('d MMMM, HH:mm', 'ru_RU').format(mskTime);
    } else if (locale == 'ar') {
      return DateFormat('d MMMM, HH:mm', 'ar').format(mskTime);
    }
    return DateFormat('MMM d, HH:mm', 'en_US').format(mskTime);
  }

  /// Format time only in Moscow time
  String formatMoscowTime(DateTime dateTime, String locale) {
    final mskTime = dateTime.toUtc().add(const Duration(hours: moscowTimeOffset));
    return DateFormat('HH:mm').format(mskTime);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);
    final locale = languageProvider.languageCode;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            _buildAppBar(context, auth, l10n),

            // Statistics Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatisticsSection(context, auth, l10n, locale),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickActions(context, l10n),
              ),
            ),

            // Today's Schedule Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.todaySchedule,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.moscowTime}: ${formatMoscowTime(moscowTime, locale)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen()),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(l10n.viewAllAppointments),
                    ),
                  ],
                ),
              ),
            ),

            // Appointments List
            _buildAppointmentsList(context, auth, l10n, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Doctor Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                        ? NetworkImage(auth.photoUrl!)
                        : null,
                    child: auth.photoUrl == null || auth.photoUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Greeting
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.welcomeBack,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.userName ?? l10n.doctor,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Language Selector
        const LanguageSelector(isAppBarAction: true),
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        // Logout
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => auth.signOut(),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations l10n,
    String locale,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: auth.user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int dailyPatients = 0;
        int pendingConsultations = 0;
        int completedToday = 0;
        double totalEarnings = 0;

        if (snapshot.hasData) {
          final now = moscowTime;
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateField = data['date'];
            DateTime? appointmentDate;

            if (dateField is Timestamp) {
              appointmentDate = dateField.toDate();
            } else if (dateField is String) {
              appointmentDate = DateTime.tryParse(dateField);
            }

            if (appointmentDate != null) {
              // Convert to Moscow time for comparison
              final mskDate = appointmentDate.toUtc().add(const Duration(hours: moscowTimeOffset));

              if (mskDate.isAfter(todayStart) && mskDate.isBefore(todayEnd)) {
                dailyPatients++;

                final status = data['status'] as String? ?? 'pending';
                if (status == 'completed') {
                  completedToday++;
                  final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0;
                  totalEarnings += price;
                } else if (status == 'pending' || status == 'confirmed') {
                  pendingConsultations++;
                }
              }
            }
          }
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people_outline,
                    title: l10n.dailyPatients,
                    value: dailyPatients.toString(),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    title: l10n.pendingConsultations,
                    value: pendingConsultations.toString(),
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_outline,
                    title: l10n.completedToday,
                    value: completedToday.toString(),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: l10n.totalEarnings,
                    value: formatRubPrice(totalEarnings, locale),
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.video_call,
                label: l10n.startConsultation,
                color: AppColors.primary,
                onTap: () {
                  // TODO: Start video consultation
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.folder_open,
                label: l10n.viewPatientRecords,
                color: AppColors.secondary,
                onTap: () {
                  // TODO: View patient records
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.calendar_today,
                label: l10n.manageSchedule,
                color: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations l10n,
    String locale,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: auth.user?.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date', descending: false)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noScheduledAppointments,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildAppointmentCard(context, data, l10n, locale);
              },
              childCount: snapshot.data!.docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> data,
    AppLocalizations l10n,
    String locale,
  ) {
    final patientName = data['patientName'] as String? ?? 'Patient';
    final patientId = data['patientId'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final type = data['type'] as String? ?? 'video';
    final price = data['price']?.toString() ?? '0';

    // Parse date
    DateTime? appointmentDate;
    final dateField = data['date'];
    if (dateField is Timestamp) {
      appointmentDate = dateField.toDate();
    } else if (dateField is String) {
      appointmentDate = DateTime.tryParse(dateField);
    }

    // Get consultation type icon and label
    IconData typeIcon;
    String typeLabel;
    Color typeColor;

    switch (type) {
      case 'video':
        typeIcon = Icons.videocam;
        typeLabel = l10n.videoConsultation;
        typeColor = AppColors.primary;
        break;
      case 'chat':
        typeIcon = Icons.chat;
        typeLabel = l10n.chatConsultation;
        typeColor = AppColors.secondary;
        break;
      case 'in_person':
        typeIcon = Icons.person;
        typeLabel = l10n.inPersonVisit;
        typeColor = AppColors.warning;
        break;
      default:
        typeIcon = Icons.medical_services;
        typeLabel = l10n.consultations;
        typeColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show appointment details or start consultation
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Patient Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: typeColor.withValues(alpha: 0.1),
                      child: Text(
                        patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Patient Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.appointmentWith} $patientName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(typeIcon, size: 14, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'confirmed'
                            ? AppColors.successLight
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status == 'confirmed' ? l10n.appointmentConfirmed : l10n.pendingConsultations,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status == 'confirmed' ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date/Time
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 6),
                        Text(
                          appointmentDate != null
                              ? formatMoscowDateTime(appointmentDate, locale)
                              : '--',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    // Price
                    Text(
                      formatRubPrice(double.tryParse(price) ?? 0, locale),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    if (type == 'video')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  appointmentId: data['id'] ?? '',
                                  receiverName: patientName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.video_call, size: 18),
                          label: Text(l10n.startVideoCall),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (type == 'video') const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                appointmentId: data['id'] ?? '',
                                receiverName: patientName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: Text(l10n.chat),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
