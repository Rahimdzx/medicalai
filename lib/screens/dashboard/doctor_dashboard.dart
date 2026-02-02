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

/// لوحة تحكم الطبيب الاحترافية مع الإحصائيات والمواعيد
/// مهيئة لتوقيت موسكو (MSK) واللغات العربية، الروسية، والإنجليزية
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  // Moscow Time Zone offset (UTC+3)
  static const int moscowTimeOffset = 3;

  /// الحصول على توقيت موسكو الحالي
  DateTime get moscowTime {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: moscowTimeOffset));
  }

  /// تنسيق السعر بناءً على اللغة (الروبل لروسيا، الريال للعربي، الدولار للإنكليزي)
  String formatCurrency(double amount, String locale) {
    if (locale == 'ru') {
      return NumberFormat.currency(
        locale: 'ru_RU',
        symbol: '₽',
        decimalDigits: 0,
      ).format(amount);
    } else if (locale == 'ar') {
      return NumberFormat.currency(
        locale: 'ar_SA',
        symbol: 'ر.س',
        decimalDigits: 0,
      ).format(amount);
    }
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }

  /// تنسيق التاريخ والوقت لتوقيت موسكو
  String formatMoscowDateTime(DateTime dateTime, String locale) {
    final mskTime = dateTime.toUtc().add(const Duration(hours: moscowTimeOffset));
    String pattern = locale == 'en' ? 'MMM d, HH:mm' : 'd MMMM, HH:mm';
    return DateFormat(pattern, locale).format(mskTime);
  }

  String formatMoscowTime(DateTime dateTime) {
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
            _buildAppBar(context, auth, l10n),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatisticsSection(context, auth, l10n, locale),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickActions(context, l10n),
              ),
            ),

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
                          '${l10n.moscowTime}: ${formatMoscowTime(moscowTime)}',
                          style: const TextStyle(
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
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                      ? NetworkImage(auth.photoUrl!)
                      : null,
                  child: auth.photoUrl == null || auth.photoUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcomeBack,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
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
      actions: [
        const LanguageSelector(isAppBarAction: true),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => auth.signOut(),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AuthProvider auth, AppLocalizations l10n, String locale) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: auth.user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int dailyPatients = 0;
        int pending = 0;
        int completed = 0;
        double earnings = 0;

        if (snapshot.hasData) {
          final now = moscowTime;
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();

            if (date != null) {
              final mskDate = date.toUtc().add(const Duration(hours: moscowTimeOffset));
              if (mskDate.isAfter(todayStart) && mskDate.isBefore(todayEnd)) {
                dailyPatients++;
                final status = data['status'] ?? 'pending';
                if (status == 'completed') {
                  completed++;
                  earnings += double.tryParse(data['price']?.toString() ?? '0') ?? 0;
                } else if (status == 'pending' || status == 'confirmed') {
                  pending++;
                }
              }
            }
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(l10n.dailyPatients, dailyPatients.toString(), Icons.people, AppColors.primary),
            _buildStatCard(l10n.pendingConsultations, pending.toString(), Icons.pending, AppColors.warning),
            _buildStatCard(l10n.completedToday, completed.toString(), Icons.check_circle, AppColors.success),
            _buildStatCard(l10n.totalEarnings, formatCurrency(earnings, locale), Icons.payments, AppColors.secondary),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _buildActionBtn(l10n.startConsultation, Icons.video_call, AppColors.primary, () {}),
        const SizedBox(width: 12),
        _buildActionBtn(l10n.viewPatientRecords, Icons.folder_shared, AppColors.secondary, () {}),
        const SizedBox(width: 12),
        _buildActionBtn(l10n.manageSchedule, Icons.event_note, AppColors.warning, () {}),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, AuthProvider auth, AppLocalizations l10n, String locale) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: auth.user?.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date', descending: false)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.noScheduledAppointments)),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAppointmentCard(context, docs[index].data() as Map<String, dynamic>, l10n, locale),
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> data, AppLocalizations l10n, String locale) {
    final name = data['patientName'] ?? 'Patient';
    final date = (data['date'] as Timestamp?)?.toDate();
    final type = data['type'] ?? 'video';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(name[0])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(type == 'video' ? l10n.videoConsultation : l10n.chatConsultation, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
              Text(formatCurrency(double.tryParse(data['price']?.toString() ?? '0') ?? 0, locale), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(date != null ? formatMoscowDateTime(date, locale) : '--:--', style: const TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.video_call, color: AppColors.primary),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.secondary),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
