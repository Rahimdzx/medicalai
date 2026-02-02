import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Payment status enumeration
enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
}

/// Payment method types supported
enum PaymentMethod {
  bankCard,
  sbp, // Russian Fast Payment System (СБП)
  yookassa, // YooKassa (formerly Yandex.Kassa)
  applePay,
  googlePay,
}

/// Payment result model
class PaymentResult {
  final bool isSuccess;
  final String? transactionId;
  final String? errorMessage;
  final PaymentStatus status;
  final DateTime timestamp;
  final double amount;
  final String currency;

  PaymentResult({
    required this.isSuccess,
    this.transactionId,
    this.errorMessage,
    required this.status,
    required this.timestamp,
    required this.amount,
    this.currency = 'RUB',
  });

  Map<String, dynamic> toMap() => {
        'isSuccess': isSuccess,
        'transactionId': transactionId,
        'errorMessage': errorMessage,
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'amount': amount,
        'currency': currency,
      };
}

/// Payment service for Russian market (Trial Mode)
/// Simulates YooKassa-like payment gateway behavior
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Moscow Time offset (UTC+3)
  static const int _moscowTimeOffset = 3;

  /// Get current Moscow time
  DateTime get _moscowTime {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: _moscowTimeOffset));
  }

  /// Format currency in Russian locale (e.g., 1 500,00 ₽)
  String formatRubPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format price based on locale
  String formatPrice(double amount, String locale) {
    switch (locale) {
      case 'ru':
        return NumberFormat.currency(
          locale: 'ru_RU',
          symbol: '₽',
          decimalDigits: 0,
        ).format(amount);
      case 'ar':
        return NumberFormat.currency(
          locale: 'ar_SA',
          symbol: 'ر.س',
          decimalDigits: 0,
        ).format(amount);
      default:
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);
    }
  }

  /// Generate a transaction ID similar to YooKassa format
  String _generateTransactionId() {
    final timestamp = _moscowTime.millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(999999).toString().padLeft(6, '0');
    return 'YK-$timestamp-$randomSuffix';
  }

  /// Calculate service fee (typically 2.5% for Russian payment gateways)
  double calculateServiceFee(double amount) {
    return amount * 0.025; // 2.5% service fee
  }

  /// Calculate total amount including service fee
  double calculateTotalAmount(double consultationFee) {
    final serviceFee = calculateServiceFee(consultationFee);
    return consultationFee + serviceFee;
  }

  /// Process consultation payment (Trial Mode)
  /// Simulates 2-3 second network delay to mimic real YooKassa response
  Future<PaymentResult> processConsultationPayment({
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required double consultationFee,
    required PaymentMethod method,
    String? cardLastFour,
  }) async {
    debugPrint('[PaymentService] Processing payment for appointment: $appointmentId');
    debugPrint('[PaymentService] Consultation fee: ${formatRubPrice(consultationFee)}');

    // Simulate network delay (2-3 seconds like real Russian gateway)
    final delayMs = 2000 + _random.nextInt(1000);
    await Future.delayed(Duration(milliseconds: delayMs));

    // Calculate total with service fee
    final serviceFee = calculateServiceFee(consultationFee);
    final totalAmount = consultationFee + serviceFee;

    // Simulate payment success/failure (90% success rate in trial mode)
    final isSuccess = _random.nextDouble() < 0.9;

    final transactionId = isSuccess ? _generateTransactionId() : null;
    final timestamp = _moscowTime;

    final result = PaymentResult(
      isSuccess: isSuccess,
      transactionId: transactionId,
      errorMessage: isSuccess ? null : _getRandomErrorMessage(),
      status: isSuccess ? PaymentStatus.success : PaymentStatus.failed,
      timestamp: timestamp,
      amount: totalAmount,
      currency: 'RUB',
    );

    // Save payment record to Firestore
    await _savePaymentRecord(
      patientId: patientId,
      doctorId: doctorId,
      appointmentId: appointmentId,
      consultationFee: consultationFee,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      method: method,
      result: result,
      cardLastFour: cardLastFour,
    );

    // Update appointment payment status
    if (isSuccess) {
      await _updateAppointmentPaymentStatus(appointmentId, transactionId!);
    }

    return result;
  }

  /// Get random error message for simulated failures
  String _getRandomErrorMessage() {
    final errors = [
      'Недостаточно средств на карте',
      'Карта заблокирована',
      'Превышен лимит операций',
      'Ошибка связи с банком',
      'Операция отклонена банком',
    ];
    return errors[_random.nextInt(errors.length)];
  }

  /// Save payment record to Firestore
  Future<void> _savePaymentRecord({
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required double consultationFee,
    required double serviceFee,
    required double totalAmount,
    required PaymentMethod method,
    required PaymentResult result,
    String? cardLastFour,
  }) async {
    await _firestore.collection('payments').add({
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'consultationFee': consultationFee,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'currency': 'RUB',
      'method': method.name,
      'cardLastFour': cardLastFour,
      'transactionId': result.transactionId,
      'status': result.status.name,
      'isSuccess': result.isSuccess,
      'errorMessage': result.errorMessage,
      'createdAt': FieldValue.serverTimestamp(),
      'moscowTime': result.timestamp.toIso8601String(),
    });
  }

  /// Update appointment payment status
  Future<void> _updateAppointmentPaymentStatus(
    String appointmentId,
    String transactionId,
  ) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'isPaid': true,
      'paymentId': transactionId,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get payment history for a patient
  Future<List<Map<String, dynamic>>> getPatientPaymentHistory(String patientId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
  }

  /// Get payment history for a doctor (earnings)
  Future<List<Map<String, dynamic>>> getDoctorPaymentHistory(String doctorId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .where('isSuccess', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
  }

  /// Calculate doctor's total earnings
  Future<double> calculateDoctorEarnings(String doctorId, {DateTime? fromDate}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .where('isSuccess', isEqualTo: true);

    if (fromDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }

    final snapshot = await query.get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Doctor receives consultation fee minus platform commission
      final consultationFee = (data['consultationFee'] as num?)?.toDouble() ?? 0;
      total += consultationFee * 0.85; // Doctor gets 85%, platform keeps 15%
    }

    return total;
  }

  /// Refund payment (Trial Mode)
  Future<PaymentResult> refundPayment({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    // Simulate refund processing delay
    await Future.delayed(const Duration(seconds: 2));

    final isSuccess = _random.nextDouble() < 0.95; // 95% refund success rate

    final timestamp = _moscowTime;
    final refundId = isSuccess ? 'RF-${_generateTransactionId()}' : null;

    // Update original payment record
    if (isSuccess) {
      final paymentQuery = await _firestore
          .collection('payments')
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (paymentQuery.docs.isNotEmpty) {
        await paymentQuery.docs.first.reference.update({
          'refunded': true,
          'refundId': refundId,
          'refundedAt': FieldValue.serverTimestamp(),
          'refundReason': reason,
        });
      }
    }

    return PaymentResult(
      isSuccess: isSuccess,
      transactionId: refundId,
      errorMessage: isSuccess ? null : 'Ошибка при возврате средств',
      status: isSuccess ? PaymentStatus.success : PaymentStatus.failed,
      timestamp: timestamp,
      amount: amount,
    );
  }

  /// Validate card number (basic Luhn algorithm check)
  bool validateCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Get card type from number
  String? getCardType(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return 'Mastercard';
    if (digits.startsWith('220')) return 'Мир'; // Russian Mir card
    if (RegExp(r'^3[47]').hasMatch(digits)) return 'American Express';
    if (digits.startsWith('62')) return 'UnionPay';

    return 'Unknown';
  }
}
