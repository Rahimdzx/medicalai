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
/// تم إضافة wallet هنا لحل مشكلة Member not found
enum PaymentMethod {
  bankCard,
  wallet, // المحفظة الإلكترونية
  sbp, // Russian Fast Payment System (СБП)
  yookassa, // YooKassa
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

/// Payment service (Updated to support Wallet and Global Locales)
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

  /// Format price based on locale and currency
  String formatPrice(double amount, String locale) {
    try {
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
            decimalDigits: 2,
          ).format(amount);
        default:
          return NumberFormat.currency(
            locale: 'en_US',
            symbol: '\$',
            decimalDigits: 2,
          ).format(amount);
      }
    } catch (e) {
      return '\$${amount.toStringAsFixed(2)}'; // Fallback
    }
  }

  /// Generate a transaction ID
  String _generateTransactionId() {
    final timestamp = _moscowTime.millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(999999).toString().padLeft(6, '0');
    return 'TX-$timestamp-$randomSuffix';
  }

  /// Calculate service fee (2.5%)
  double calculateServiceFee(double amount) {
    return amount * 0.025;
  }

  /// Calculate total amount
  double calculateTotalAmount(double consultationFee) {
    return consultationFee + calculateServiceFee(consultationFee);
  }

  /// Process consultation payment (Trial Mode)
  Future<PaymentResult> processConsultationPayment({
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required double consultationFee,
    required PaymentMethod method,
    String? cardLastFour,
  }) async {
    debugPrint('[PaymentService] Processing via ${method.name}');

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 1500 + _random.nextInt(1000)));

    final totalAmount = calculateTotalAmount(consultationFee);
    
    // 95% success rate for simulation
    final isSuccess = _random.nextDouble() < 0.95;

    final result = PaymentResult(
      isSuccess: isSuccess,
      transactionId: isSuccess ? _generateTransactionId() : null,
      errorMessage: isSuccess ? null : _getRandomErrorMessage(),
      status: isSuccess ? PaymentStatus.success : PaymentStatus.failed,
      timestamp: _moscowTime,
      amount: totalAmount,
      currency: 'RUB', // Default currency
    );

    // Save to Firestore
    await _savePaymentRecord(
      patientId: patientId,
      doctorId: doctorId,
      appointmentId: appointmentId,
      consultationFee: consultationFee,
      serviceFee: calculateServiceFee(consultationFee),
      totalAmount: totalAmount,
      method: method,
      result: result,
      cardLastFour: cardLastFour,
    );

    if (isSuccess) {
      await _updateAppointmentPaymentStatus(appointmentId, result.transactionId!);
    }

    return result;
  }

  String _getRandomErrorMessage() {
    final errors = [
      'Insufficient funds',
      'Card declined by bank',
      'Transaction limit exceeded',
      'Connection timeout',
    ];
    return errors[_random.nextInt(errors.length)];
  }

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
      'method': method.name,
      'cardLastFour': cardLastFour,
      'transactionId': result.transactionId,
      'status': result.status.name,
      'isSuccess': result.isSuccess,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateAppointmentPaymentStatus(String id, String txId) async {
    await _firestore.collection('appointments').doc(id).update({
      'isPaid': true,
      'paymentId': txId,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get card type
  String? getCardType(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return 'Mastercard';
    if (digits.startsWith('220')) return 'Mir';
    return 'Unknown';
  }
}
