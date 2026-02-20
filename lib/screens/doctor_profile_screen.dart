import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/doctor_service.dart';
import '../auth/login_screen.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
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
                  backgroundImage: widget.doctor.photo != null ? NetworkImage(widget.doctor.photo!) : null,
                  child: widget.doctor.photo == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${widget.doctor.getLocalizedName(locale)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            '\$${widget.doctor.price}',
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
              _showTimeSlots(selectedDay);
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
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

          // Legal Links
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        // Show legal document modal
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
                  Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: const [Text('Legal document content here...')],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Text(text, style: const TextStyle(decoration: TextDecoration.underline)),
    );
  }

  void _showAuthRequiredDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
        builder: (context) => BookingScreen(
          doctor: widget.doctor,
          date: date,
          availableSlots: slots,
        ),
      );
    }
  }
}
