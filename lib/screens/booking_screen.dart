import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final dateStr = widget.date.toIso8601String().split('T')[0];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.scheduleAppointment,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${widget.doctor.name}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.availableSlots.isEmpty)
                        _buildEmptySlotsState()
                      else ...[
                        Row(
                          children: [
                            Text(
                              l10n.selectTime,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '₽${widget.doctor.price}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSlotsGrid(),
                        const SizedBox(height: 20),
                        _buildConfirmButton(authProvider, l10n),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySlotsState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No available slots for this date',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please select another date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.availableSlots.length,
      itemBuilder: (context, index) {
        final slot = widget.availableSlots[index];
        final slotStr = '${slot['start']} - ${slot['end']}';
        final isSelected = _selectedSlot == slotStr;
        final isBooked = slot['booked'] == true;

        return Material(
          color: isBooked
              ? Colors.grey.shade200
              : isSelected
                  ? Colors.blue.shade700
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isBooked
                ? null
                : () => setState(
                    () => _selectedSlot = isSelected ? null : slotStr),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isBooked
                      ? Colors.grey.shade300
                      : isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade400,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  slotStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isBooked
                        ? Colors.grey.shade500
                        : isSelected
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton(
      AuthProvider authProvider, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedSlot == null || _isBooking
            ? null
            : () => _bookAppointment(authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isBooking
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(l10n.confirmAppointment),
      ),
    );
  }

  Future<void> _bookAppointment(AuthProvider authProvider) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isBooking = true);

    try {
      final dateStr = widget.date.toIso8601String().split('T')[0];

      // إنشاء الموعد في Firestore
      final appointmentRef =
          await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'patientId': authProvider.user!.uid,
        'patientName': authProvider.userName ?? 'Patient',
        'date': dateStr,
        'timeSlot': _selectedSlot,
        'status': 'pending',
        'price': widget.doctor.price,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // إنشاء محادثة مرتبطة بالموعد
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(appointmentRef.id)
          .set({
        'doctorId': widget.doctor.id,
        'patientId': authProvider.user!.uid,
        'doctorName': widget.doctor.name,
        'patientName': authProvider.userName ?? 'Patient',
        'appointmentId': appointmentRef.id,
        'lastMessage': 'Appointment requested',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add system message to the chat
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(appointmentRef.id)
          .collection('messages')
          .add({
        'text': 'Appointment requested for $dateStr at $_selectedSlot',
        'senderId': 'system',
        'senderRole': 'system',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appointmentConfirmed),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'permission-denied':
          errorMessage =
              'Permission denied. Please check your Firebase security rules or contact support.';
          break;
        case 'unauthenticated':
          errorMessage = 'Please login again to book an appointment.';
          break;
        case 'unavailable':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}
