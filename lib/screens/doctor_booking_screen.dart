import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/colors.dart'; 
import '../../providers/auth_provider.dart'; 
import '../../providers/locale_provider.dart';
import '../auth/login_screen.dart';
import 'legal_document_screen.dart';

class DoctorBookingScreen extends StatefulWidget {
  final String doctorId;
  final String? doctorNumber; // For QR/manual entry flow

  const DoctorBookingScreen({
    super.key, 
    required this.doctorId,
    this.doctorNumber,
  });

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  String _selectedFormat = 'video';
  String _selectedTime = 'today';
  bool _isBooking = false;
  bool _legalConsentChecked = false; // CRITICAL: Consent checkbox state
  
  // Legal document URLs/content from Firestore
  Map<String, dynamic>? _legalDocuments;

  @override
  void initState() {
    super.initState();
    _loadLegalDocuments();
  }

  Future<void> _loadLegalDocuments() async {
    final docs = await FirebaseFirestore.instance
        .collection('legalDocuments')
        .get();
    if (docs.docs.isNotEmpty) {
      setState(() {
        _legalDocuments = {
          for (var doc in docs.docs) doc.id: doc.data()
        };
      });
    }
  }

  IconData _getSpecialtyIcon(String? specialty) {
    if (specialty == null) return Icons.medical_services;
    final s = specialty.toLowerCase();
    if (s.contains('dentist')) return Icons.favorite_border;
    if (s.contains('heart') || s.contains('cardio')) return Icons.favorite;
    if (s.contains('eye')) return Icons.remove_red_eye;
    if (s.contains('radio') || s.contains('أشعة') || s.contains('рентген')) 
      return Icons.image_search; // Radiology icon
    return Icons.person;
  }

  Future<void> _handleBooking(Map<String, dynamic> doctorData, double finalPrice, String currency) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    if (!_legalConsentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final appointmentId = FirebaseFirestore.instance.collection('appointments').doc().id;
      final chatId = FirebaseFirestore.instance.collection('chats').doc().id;
      
      // Create appointment
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).set({
        'appointmentId': appointmentId,
        'patientId': authProvider.user?.uid,
        'patientName': authProvider.userName,
        'doctorId': widget.doctorId,
        'doctorName': doctorData['name'],
        'status': 'confirmed',
        'format': _selectedFormat,
        'timeSlot': _selectedTime,
        'price': finalPrice,
        'currency': currency,
        'paymentStatus': 'paid', // Assuming payment succeeds
        'chatId': chatId,
        'consentGiven': true,
        'consentTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create chat room
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'patientId': authProvider.user?.uid,
        'doctorId': widget.doctorId,
        'appointmentId': appointmentId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      // Add system message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderRole': 'system',
        'text': l10n.consultationSystemMessage, // Add to ARB files
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookingConfirmed), 
          backgroundColor: Colors.green
        ),
      );
      
      // Navigate to chat
      Navigator.pushReplacementNamed(
        context, 
        '/chat',
        arguments: {
          'chatId': chatId,
          'receiverName': doctorData['name'],
          'appointmentId': appointmentId,
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${l10n.error}: $e"), 
          backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showLegalDocument(String docType, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(
          documentType: docType,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isRTL = localeProvider.isRTL;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.completeBooking, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.doctorNotFound));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? 'Doctor';
          String specialization = data['specialization'] ?? 'Specialist';
          String currency = data['currency'] ?? 'USD';
          double basePrice = (data['price'] ?? 0).toDouble();

          // Localized price calculation
          double finalPrice = basePrice;
          if (_selectedFormat == 'chat') finalPrice = basePrice * 0.7;
          if (_selectedFormat == 'audio') finalPrice = basePrice * 0.9;
          if (_selectedTime == 'tomorrow') finalPrice -= (currency == 'RUB' ? 500 : 10);

          // Format price based on locale
          String priceText = currency == 'RUB' 
              ? '${finalPrice.toStringAsFixed(0)} ₽'
              : '\$${finalPrice.toStringAsFixed(0)}';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Card
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
                                      Text("${data['rating'] ?? '4.9'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      Text(l10n.consultationFormat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            _buildFormatOption(l10n.videoConsultation, Icons.videocam, "video"),
                            const Divider(height: 1, indent: 50),
                            _buildFormatOption(l10n.audioConsultation, Icons.phone, "audio"),
                            const Divider(height: 1, indent: 50),
                            _buildFormatOption(l10n.chatConsultation, Icons.chat_bubble, "chat"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      Text(l10n.availability, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildTimeOption(l10n.today, l10n.urgent, "today", Icons.bolt)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTimeOption(l10n.tomorrow, l10n.scheduled, "tomorrow", Icons.calendar_month)),
                        ],
                      ),

                      const SizedBox(height: 25),
                      
                      // LEGAL CONSENT SECTION (REQUIREMENT)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _legalConsentChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      _legalConsentChecked = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: l10n.paymentConsentPrefix,
                                      style: const TextStyle(fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text: l10n.serviceAgreement,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showLegalDocument('offer', l10n.serviceAgreement),
                                        ),
                                        const TextSpan(text: ", "),
                                        TextSpan(
                                          text: l10n.privacyPolicy,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showLegalDocument('privacy', l10n.privacyPolicy),
                                        ),
                                        const TextSpan(text: " ${l10n.and} "),
                                        TextSpan(
                                          text: l10n.dataConsent,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showLegalDocument('dataConsent', l10n.dataConsent),
                                        ),
                                      ],
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

              // Payment Bar
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
                          Text(l10n.totalAmount, style: const TextStyle(color: Colors.grey)),
                          Text(
                            priceText, 
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.blue
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _legalConsentChecked ? const Color(0xFF4CAF50) : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: (_isBooking || !_legalConsentChecked) 
                              ? null 
                              : () {
                                  if (authProvider.user == null) {
                                    _showLoginDialog(context, l10n);
                                  } else {
                                    _handleBooking(data, finalPrice, currency);
                                  }
                                },
                          child: _isBooking 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                l10n.confirmAndPay, 
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white
                                )
                              ),
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
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white : Colors.black
              )
            ),
            Text(
              subtitle, 
              style: TextStyle(
                fontSize: 11, 
                color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey
              )
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.registrationRequired),
        content: Text(l10n.loginRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(l10n.cancel)
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              );
            },
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }
}
