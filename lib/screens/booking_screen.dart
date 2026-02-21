import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/doctor_model.dart';
import '../providers/auth_provider.dart';
import '../services/payment_service.dart';
import 'chat_screen.dart';

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
  bool _isProcessing = false;
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dateStr = widget.date.toIso8601String().split('T')[0];
    final serviceFee = PaymentService().calculateServiceFee(widget.doctor.price);
    final totalAmount = widget.doctor.price + serviceFee;

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Text(
            l10n.completeBooking,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.doctor}: Dr. ${widget.doctor.name}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          Text(
            '${l10n.selectDate}: $dateStr',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const Divider(height: 32),

          // Price Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.consultationFee),
                    Text('${widget.doctor.price.toStringAsFixed(0)} ${widget.doctor.currency}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.serviceFee),
                    Text('${serviceFee.toStringAsFixed(0)} ${widget.doctor.currency}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalAmount,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(0)} ${widget.doctor.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Time Slots
          Text(
            l10n.chooseTime,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (widget.availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No available slots for this date',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
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
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          // Terms Checkbox
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
            title: Text(
              l10n.paymentConsent,
              style: const TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          const Spacer(),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedSlot == null || !_agreedToTerms || _isProcessing
                  ? null
                  : () => _processBooking(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.confirmAndPay),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processBooking(AuthProvider authProvider) async {
    if (_selectedSlot == null) return;

    setState(() => _isProcessing = true);

    try {
      final dateStr = widget.date.toIso8601String().split('T')[0];
      final userId = authProvider.user!.uid;

      // 1. Create appointment
      final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'patientId': userId,
        'patientName': authProvider.userName ?? 'Patient',
        'date': dateStr,
        'timeSlot': _selectedSlot,
        'status': 'pending_payment',
        'consultationFee': widget.doctor.price,
        'serviceFee': PaymentService().calculateServiceFee(widget.doctor.price),
        'totalAmount': widget.doctor.price + PaymentService().calculateServiceFee(widget.doctor.price),
        'currency': widget.doctor.currency,
        'isPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Process payment
      final paymentResult = await PaymentService().processConsultationPayment(
        patientId: userId,
        doctorId: widget.doctor.id,
        appointmentId: appointmentRef.id,
        consultationFee: widget.doctor.price,
        method: PaymentMethod.bankCard,
      );

      if (paymentResult.isSuccess) {
        // 3. Mark slot as booked
        await _markSlotAsBooked(dateStr, _selectedSlot!);

        // 4. Create chat room
        final chatId = '${userId}_${widget.doctor.id}';
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'patientId': userId,
          'doctorId': widget.doctor.id,
          'patientName': authProvider.userName ?? 'Patient',
          'doctorName': 'Dr. ${widget.doctor.name}',
          'appointmentId': appointmentRef.id,
          'lastMessage': 'Booking confirmed',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 5. Add system message
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'text': AppLocalizations.of(context).consultationSystemMessage,
          'senderId': 'system',
          'senderRole': 'system',
          'type': 'text',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        if (mounted) {
          Navigator.pop(context); // Close booking sheet

          // Show success and navigate to chat
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Booking Confirmed!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text('Payment successful: ${paymentResult.transactionId}'),
                  const SizedBox(height: 8),
                  const Text('You can now chat with your doctor.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId,
                          receiverName: 'Dr. ${widget.doctor.name}',
                          appointmentId: appointmentRef.id,
                          isRadiology: widget.doctor.specialty.toLowerCase().contains('radiology'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Chat'),
                ),
              ],
            ),
          );
        }
      } else {
        // Payment failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${paymentResult.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markSlotAsBooked(String date, String slotStr) async {
    final scheduleDoc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctor.id)
        .collection('schedule')
        .doc(date)
        .get();

    if (scheduleDoc.exists) {
      final data = scheduleDoc.data() as Map<String, dynamic>;
      final slots = data['slots'] as List<dynamic>;

      // Find and mark the slot as booked
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i] as Map<String, dynamic>;
        final currentSlotStr = '${slot['start']} - ${slot['end']}';
        if (currentSlotStr == slotStr) {
          slots[i]['booked'] = true;
          break;
        }
      }

      await scheduleDoc.reference.update({'slots': slots});
    }
  }
}
