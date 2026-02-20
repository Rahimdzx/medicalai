import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../chat/chat_screen.dart';

class BookingScreen extends StatefulWidget {
  final DoctorModel doctor;
  final DateTime date;
  final List<Map<String, dynamic>> availableSlots;

  const BookingScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.availableSlots,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _selectedSlot;
  String _selectedFormat = 'video';
  bool _legalConsentChecked = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    double finalPrice = widget.doctor.price;
    if (_selectedFormat == 'chat') finalPrice *= 0.7;
    if (_selectedFormat == 'audio') finalPrice *= 0.9;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.chooseTime, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (widget.availableSlots.isEmpty)
            const Center(child Text('No available slots')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableSlots.map((slot) {
              final time = slot['start'] as String;
              final isSelected = _selectedSlot == time;
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedSlot = time),
                selectedColor: Colors.blue.shade100,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(l10n.consultationFormat, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: _buildFormatOption('video', Icons.videocam, l10n.videoConsultation)),
              Expanded(child: _buildFormatOption('audio', Icons.phone, l10n.audioConsultation)),
              Expanded(child: _buildFormatOption('chat', Icons.chat, l10n.chatConsultation)),
            ],
          ),
          const SizedBox(height: 20),
          // Legal Consent Checkbox
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _legalConsentChecked,
                  onChanged: (value) => setState(() => _legalConsentChecked = value ?? false),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: l10n.paymentConsentPrefix,
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: l10n.serviceAgreement,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: l10n.privacyPolicy,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        TextSpan(text: ' ${l10n.and} '),
                        TextSpan(
                          text: l10n.dataConsent,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.total}:', style: const TextStyle(fontSize: 18)),
              Text(
                '\$${finalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedSlot == null || !_legalConsentChecked || _isLoading)
                  ? null
                  : () => _confirmBooking(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.pay, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String value, IconData icon, String label) {
    final isSelected = _selectedFormat == value;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.blue) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue : Colors.black)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(AuthProvider authProvider) async {
    setState(() => _isLoading = true);
    
    try {
      final appointment = await BookingService().createBooking(
        patientId: authProvider.user!.uid,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        date: widget.date.toIso8601String().split('T')[0],
        timeSlot: _selectedSlot!,
        format: _selectedFormat,
        price: widget.doctor.price * (_selectedFormat == 'chat' ? 0.7 : _selectedFormat == 'audio' ? 0.9 : 1.0),
        currency: widget.doctor.currency,
      );

      if (mounted) {
        Navigator.pop(context); // Close booking sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: appointment.chatId,
              receiverName: widget.doctor.name,
              appointmentId: appointment.id,
              isRadiology: widget.doctor.specialty.toLowerCase().contains('radio') ||
                  widget.doctor.specialtyAr.contains('أشعة'),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
