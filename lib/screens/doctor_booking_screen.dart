import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart'; // تأكد من المسار
import '../../providers/auth_provider.dart'; // تأكد من المسار
import 'login_screen.dart'; // تأكد من المسار

class DoctorBookingScreen extends StatefulWidget {
  final String doctorId;

  const DoctorBookingScreen({super.key, required this.doctorId});

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  // متغيرات الاختيار
  String _selectedFormat = 'video';
  String _selectedTime = 'today';
  
  // دالة مساعدة لتحديد أيقونة بناءً على التخصص (اختياري)
  IconData _getSpecialtyIcon(String? specialty) {
    if (specialty == null) return Icons.medical_services;
    final s = specialty.toLowerCase();
    if (s.contains('dentist')) return Icons.favorite_border; // مثال
    if (s.contains('heart') || s.contains('cardio')) return Icons.favorite;
    if (s.contains('eye')) return Icons.remove_red_eye;
    return Icons.person; // أيقونة افتراضية
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Complete Booking", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // استخدام FutureBuilder لجلب بيانات الطبيب المحدد
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.doctorId).get(),
        builder: (context, snapshot) {
          // 1. حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. حالة الخطأ أو عدم وجود بيانات
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Doctor info unavailable"));
          }

          // 3. استخراج البيانات
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? 'Doctor';
          String specialization = data['specialization'] ?? 'Specialist';
          // تحويل السعر بأمان إلى double
          double basePrice = double.tryParse(data['price']?.toString() ?? '50') ?? 50.0;

          // حساب السعر النهائي بناءً على نوع الاستشارة (مثال: الشات أرخص)
          double finalPrice = basePrice;
          if (_selectedFormat == 'chat') finalPrice = basePrice * 0.7; // خصم 30% للشات
          if (_selectedFormat == 'audio') finalPrice = basePrice * 0.9; // خصم 10% للصوت

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === كارت معلومات الطبيب ===
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
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                      const SizedBox(width: 4),
                                      const Text("4.9 (120 reviews)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // === اختيار نوع الاستشارة ===
                      const Text("Consultation Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            _buildFormatOption("Video Call", Icons.videocam, "video"),
                            const Divider(height: 1, indent: 50),
                            _buildFormatOption("Audio Call", Icons.phone, "audio"),
                            const Divider(height: 1, indent: 50),
                            _buildFormatOption("Chat", Icons.chat_bubble, "chat"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // === اختيار الوقت ===
                      const Text("Preferred Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildTimeOption("Today", "Available", "today", Icons.today)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTimeOption("Tomorrow", "10 Slots", "tomorrow", Icons.calendar_month)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // === القائمة السفلية (الدفع) ===
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
                          const Text("Total Payment", style: TextStyle(color: Colors.grey)),
                          Text(
                            "\$${finalPrice.toStringAsFixed(0)}", 
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (authProvider.user == null) {
                              // إذا لم يكن مسجلاً، اطلب التسجيل
                              _showLoginDialog(context);
                            } else {
                              // إذا كان مسجلاً، تابع للدفع
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Processing Payment..."), backgroundColor: Colors.green),
                              );
                              // Navigator.pushNamed(context, '/payment_gateway');
                            }
                          },
                          child: const Text("Book Appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  // --- Widgets مساعدة للتصميم ---

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
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
            ),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
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
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
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
        title: const Text("Login Required"),
        content: const Text("You need to login to book an appointment."),
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
