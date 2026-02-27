import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
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

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);
    final locale = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectDate)),
      body: Column(
        children: [
          // Doctor Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.doctor.photo != null
                      ? NetworkImage(widget.doctor.photo!)
                      : null,
                  child: widget.doctor.photo == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${widget.doctor.getLocalizedName(locale)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.doctor.getLocalizedSpecialty(locale),
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(' ${widget.doctor.rating}'),
                          const SizedBox(width: 16),
                          Text(
                            '₽${widget.doctor.price}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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

          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!authProvider.isAuthenticated) {
                _showAuthRequiredDialog(context);
                return;
              }
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // Call after setState completes
              Future.microtask(() => _showTimeSlots(selectedDay));
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
            ),
          ),

          // Book Appointment Button
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('Book button pressed! Date: $_selectedDay');
                    _showTimeSlots(_selectedDay!);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(l10n.scheduleAppointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Select a date to book appointment',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),

          // Legal Links
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLegalLink(l10n.serviceAgreement, 'offer'),
                _buildLegalLink(l10n.privacyPolicy, 'privacy'),
                _buildLegalLink(l10n.dataConsent, 'dataConsent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String text, String docType) {
    return TextButton(
      onPressed: () {
        final l10n = AppLocalizations.of(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            expand: true,
            builder: (_, controller) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(text,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: const [
                        Text('Legal document content here...')
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Text(text,
          style: const TextStyle(decoration: TextDecoration.underline)),
    );
  }

  void _showAuthRequiredDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.registrationRequired),
        content: Text(l10n.pleaseLoginToBook),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }

  void _showTimeSlots(DateTime date) async {
    debugPrint('Loading slots for doctor: ${widget.doctor.id}, date: $date');
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final slots = await DoctorService().getAvailableSlots(
        widget.doctor.id,
        date.toIso8601String().split('T')[0],
      );
      
      debugPrint('Found ${slots.length} slots');
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: BookingScreen(
                  doctor: widget.doctor,
                  date: date,
                  availableSlots: slots,
                ),
              ),
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading slots: $e');
      debugPrint(stackTrace.toString());
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Even on error, show default slots
      final defaultSlots = [
        {'start': '09:00', 'end': '09:30', 'booked': false},
        {'start': '10:00', 'end': '10:30', 'booked': false},
        {'start': '11:00', 'end': '11:30', 'booked': false},
        {'start': '14:00', 'end': '14:30', 'booked': false},
        {'start': '15:00', 'end': '15:30', 'booked': false},
        {'start': '16:00', 'end': '16:30', 'booked': false},
      ];
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: BookingScreen(
                  doctor: widget.doctor,
                  date: date,
                  availableSlots: defaultSlots,
                ),
              ),
            ),
          );
        },
      );
      }
    }
  }
}
