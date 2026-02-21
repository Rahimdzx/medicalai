import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/doctor_model.dart';
import '../providers/auth_provider.dart';

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
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dateStr = widget.date.toIso8601String().split('T')[0];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Appointment - $dateStr',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Dr. ${widget.doctor.name}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (widget.availableSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No available slots for this date')),
            )
          else ...[
            const Text('Available Time Slots:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableSlots.map((slot) {
                final slotStr = '${slot['start']} - ${slot['end']}';
                final isSelected = _selectedSlot == slotStr;
                return ChoiceChip(
                  label: Text(slotStr),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSlot = selected ? slotStr : null);
                  },
                  selectedColor: Colors.blue.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSlot == null || _isBooking
                    ? null
                    : () => _bookAppointment(authProvider),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _bookAppointment(AuthProvider authProvider) async {
    setState(() => _isBooking = true);

    try {
      final dateStr = widget.date.toIso8601String().split('T')[0];

      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'patientId': authProvider.user!.uid,
        'patientName': authProvider.userName ?? 'Patient',
        'date': dateStr,
        'timeSlot': _selectedSlot,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}
