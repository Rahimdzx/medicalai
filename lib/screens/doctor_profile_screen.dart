import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/doctor_model.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/doctor_service.dart';
import 'auth/login_screen.dart';
import 'booking_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, bool> _availableDates = {};
  bool _isLoadingCalendar = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    // Load doctor's availability for the next 90 days
    final now = DateTime.now();

    for (var i = 0; i < 90; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];

      try {
        final schedule = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctor.id)
            .collection('schedule')
            .doc(dateStr)
            .get();

        if (schedule.exists) {
          final data = schedule.data() as Map<String, dynamic>;
          final isOpen = data['isOpen'] ?? false;
          final slots = data['slots'] as List<dynamic>? ?? [];
          final hasAvailableSlots = slots.any((slot) => slot['booked'] != true);

          setState(() {
            _availableDates[DateTime(date.year, date.month, date.day)] = isOpen && hasAvailableSlots;
          });
        }
      } catch (e) {
        debugPrint('Error loading availability: $e');
      }
    }

    setState(() => _isLoadingCalendar = false);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);
    final locale = localeProvider.locale.languageCode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Header
          SliverAppBar(
            expandedHeight: 200,
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'doctor_${widget.doctor.id}',
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: widget.doctor.photo != null
                                ? NetworkImage(widget.doctor.photo!)
                                : null,
                            child: widget.doctor.photo == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Dr. ${widget.doctor.getLocalizedName(locale)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.doctor.getLocalizedSpecialty(locale),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                        Text(
                                          ' ${widget.doctor.rating}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${widget.doctor.price.toStringAsFixed(0)} ${widget.doctor.currency}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),

          // About Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.doctor.description.isNotEmpty
                        ? widget.doctor.description
                        : 'Experienced specialist providing high-quality medical consultations.',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // Calendar Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectDate,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingCalendar)
                        const Center(child: CircularProgressIndicator())
                      else
                        TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 90)),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          enabledDayPredicate: (day) {
                            final normalizedDay = DateTime(day.year, day.month, day.day);
                            return _availableDates[normalizedDay] ?? false;
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!authProvider.isAuthenticated) {
                              _showAuthRequiredDialog(context);
                              return;
                            }
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _showTimeSlots(selectedDay);
                          },
                          onFormatChanged: (format) =>
                              setState(() => _calendarFormat = format),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Colors.blue.shade200,
                              shape: BoxShape.circle,
                            ),
                            disabledTextStyle: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(l10n.available, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(l10n.unavailable, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Legal Links Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildLegalLink(l10n.serviceAgreement, _getOfferText()),
                      const Divider(),
                      _buildLegalLink(l10n.privacyPolicy, _getPrivacyText()),
                      const Divider(),
                      _buildLegalLink(l10n.dataConsent, _getDataConsentText()),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, String content) {
    return InkWell(
      onTap: () => _showLegalDocument(title, content),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLegalDocument(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(
                    content,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOfferText() {
    return '''SERVICE AGREEMENT (OFFER)

1. GENERAL PROVISIONS

1.1. This Service Agreement constitutes a public offer and defines the terms of providing medical consultation services through the Medical App platform.

1.2. By using the services, the Patient confirms acceptance of this Agreement.

2. SUBJECT OF THE AGREEMENT

2.1. The Service Provider provides the Patient with access to medical consultations with licensed healthcare professionals.

2.2. Services include online video consultations, text-based medical consultations, second opinion services, and medical documentation review.

3. PAYMENT TERMS

3.1. Service fees are displayed before booking confirmation.
3.2. A service fee of 2.5% is added to the consultation fee.
3.3. Payment is processed securely through our payment partners.

4. REFUND POLICY

4.1. Full refund available if cancelled 24 hours before appointment.
4.2. 50% refund if cancelled within 24 hours.
4.3. No refund for no-show or late cancellation.

5. CONTACT

For questions about this agreement, please contact support@medicalapp.com''';}

  String _getPrivacyText() {
    return '''PRIVACY POLICY

1. INTRODUCTION

This Privacy Policy describes how we collect, use, and protect your personal information when you use our Medical App.

2. INFORMATION WE COLLECT

We collect personal information including name, contact details, date of birth, medical history, and payment information.

3. HOW WE USE YOUR INFORMATION

We use your information to provide medical consultation services, process payments, improve our services, and communicate about appointments.

4. DATA SECURITY

We implement industry-standard security measures including encryption, secure authentication, and access controls.

5. YOUR RIGHTS

You have the right to access, correct, or delete your personal data, and to export your data.

6. CONTACT

For privacy-related questions, contact privacy@medicalapp.com''';}

  String _getDataConsentText() {
    return '''PERSONAL DATA PROCESSING CONSENT

1. CONSENT

By using the Medical App, you consent to the processing of your personal data in accordance with applicable data protection laws.

2. SCOPE OF PROCESSING

We process personal identification information, contact details, medical history, and payment information.

3. PURPOSE

Your data is used to provide medical services, maintain records, process payments, and ensure quality.

4. YOUR RIGHTS

You have the right to withdraw consent, access your data, request corrections, and lodge complaints.

5. CONTACT

For questions about data processing, contact dpo@medicalapp.com''';}

  void _showAuthRequiredDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.registrationRequired),
        content: Text(l10n.loginRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }

  void _showTimeSlots(DateTime date) async {
    final slots = await DoctorService().getAvailableSlots(
      widget.doctor.id,
      date.toIso8601String().split('T')[0],
    );

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => BookingScreen(
          doctor: widget.doctor,
          date: date,
          availableSlots: slots,
        ),
      );
    }
  }
}
