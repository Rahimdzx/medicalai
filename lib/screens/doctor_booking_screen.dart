import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart'; 
import '../../providers/auth_provider.dart'; 
import 'auth/login_screen.dart'; 

class DoctorBookingScreen extends StatefulWidget {
  final String doctorId;

  const DoctorBookingScreen({super.key, required this.doctorId});

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  String _selectedFormat = 'video';
  String _selectedTime = 'today';
  bool _isBooking = false;

  IconData _getSpecialtyIcon(String? specialty) {
    if (specialty == null) return Icons.medical_services;
    final s = specialty.toLowerCase();
    if (s.contains('dentist')) return Icons.favorite_border;
    if (s.contains('heart') || s.contains('cardio')) return Icons.favorite;
    if (s.contains('eye')) return Icons.remove_red_eye;
    return Icons.person;
  }

  // دالة تنفيذ الحجز الفعلي في Firebase
  Future<void> _handleBooking(Map<String, dynamic> doctorData, double finalPrice) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isBooking = true);

    try {
      final appointmentId = FirebaseFirestore.instance.collection('appointments').doc().id;
      
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).set({
        'appointmentId': appointmentId,
        'patientId': authProvider.user?.uid,
        'patientName': authProvider.userName,
        'doctorId': widget.doctorId,
        'doctorName': doctorData['name'],
        'status': 'pending',
        'format': _selectedFormat,
        'timeSlot': _selectedTime,
        'price': finalPrice,
        'currency': 'RUB',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Confirmed!"), backgroundColor: Colors.green),
      );
      
      // العودة للشاشة الرئيسية
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Complete Booking", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Doctor info unavailable"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? 'Doctor';
          String specialization = data['specialization'] ?? 'Specialist';
          double basePrice = double.tryParse(data['price']?.toString() ?? '3000') ?? 3000.0;

          // حساب السعر بالروبل بناءً على الخيار
          double finalPrice = basePrice;
          if (_selectedFormat == 'chat') finalPrice = basePrice * 0.7;
          if (_selectedFormat == 'audio') finalPrice = basePrice * 0.9;
          if (_selectedTime == 'tomorrow') finalPrice -= 500; // خصم بسيط للمواعيد الآجلة

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // كارت الطبيب
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(_getSpecialtyIcon(specialization), color: AppColors.primary, size: 40),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Dr. $name", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(specialization, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 5),
                                  const Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.orange, size: 16),
                                      SizedBox(width: 4),
                                      Text("4.9 (Moscow Clinic)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      const Text("Consultation Format", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            _buildFormatOption("Video Consultation", Icons.videocam, "video"),
                            const Divider(height: 1, indent: 50),
                            _buildFormatOption("Audio Call", Icons.phone, "audio"),
                            const Divider(height: 1, indent: 50),
                            _buildFormatOption("Chat & Messaging", Icons.chat_bubble, "chat"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      const Text("Availability", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildTimeOption("Today", "Urgent", "today", Icons.bolt)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTimeOption("Tomorrow", "Scheduled", "tomorrow", Icons.calendar_month)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // شريط الدفع السفلي بالروبل
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total (Moscow Time)", style: TextStyle(color: Colors.grey)),
                          Text(
                            "${finalPrice.toStringAsFixed(0)} ₽", 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50), // اللون الأخضر للتأكيد
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: _isBooking ? null : () {
                            if (authProvider.user == null) {
                              _showLoginDialog(context);
                            } else {
                              _handleBooking(data, finalPrice);
                            }
                          },
                          child: _isBooking 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Confirm and Pay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormatOption(String title, IconData icon, String value) {
    final isSelected = _selectedFormat == value;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 20),
            ),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOption(String title, String subtitle, String value, IconData icon) {
    final isSelected = _selectedTime == value;
    return InkWell(
      onTap: () => setState(() => _selectedTime = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Authentication"),
        content: const Text("Please login to proceed with the booking."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
}
