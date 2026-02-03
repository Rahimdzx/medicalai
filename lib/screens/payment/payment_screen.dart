import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/constants/colors.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final double consultationFee;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.consultationFee,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  final PaymentService _paymentService = PaymentService();

  PaymentStatus _status = PaymentStatus.pending;
  PaymentMethod _selectedMethod = PaymentMethod.bankCard;
  PaymentResult? _paymentResult;
  bool _isProcessing = false;
  String? _cardType;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String value) {
    setState(() {
      _cardType = _paymentService.getCardType(value);
    });
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == PaymentMethod.bankCard && !_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _status = PaymentStatus.processing;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final result = await _paymentService.processConsultationPayment(
      patientId: auth.user?.uid ?? '',
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
      consultationFee: widget.consultationFee,
      method: _selectedMethod,
      cardLastFour: _selectedMethod == PaymentMethod.bankCard && _cardNumberController.text.length >= 4
          ? _cardNumberController.text.replaceAll(' ', '').substring(
              _cardNumberController.text.replaceAll(' ', '').length - 4,
            )
          : null,
    );

    setState(() {
      _isProcessing = false;
      _paymentResult = result;
      _status = result.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final locale = languageProvider.languageCode;

    final serviceFee = _paymentService.calculateServiceFee(widget.consultationFee);
    final totalAmount = _paymentService.calculateTotalAmount(widget.consultationFee);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.payment),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(l10n, locale, serviceFee, totalAmount),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String locale, double serviceFee, double totalAmount) {
    switch (_status) {
      case PaymentStatus.pending:
        return _buildPaymentForm(l10n, locale, serviceFee, totalAmount);
      case PaymentStatus.processing:
        return _buildProcessingState(l10n);
      case PaymentStatus.success:
        return _buildSuccessState(l10n);
      case PaymentStatus.failed:
        return _buildFailedState(l10n);
      case PaymentStatus.cancelled:
        return _buildCancelledState(l10n);
    }
  }

  Widget _buildPaymentForm(AppLocalizations l10n, String locale, double serviceFee, double totalAmount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(l10n, locale, serviceFee, totalAmount),
            const SizedBox(height: 24),
            Text(l10n.paymentMethod, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentMethodSelector(l10n),
            const SizedBox(height: 24),
            if (_selectedMethod == PaymentMethod.bankCard) _buildCardForm(l10n),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('${l10n.payNow} ${_paymentService.formatPrice(totalAmount, locale)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n, String locale, double serviceFee, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildPriceRow(l10n.consultationFee, _paymentService.formatPrice(widget.consultationFee, locale)),
          const SizedBox(height: 8),
          _buildPriceRow(l10n.serviceFee, _paymentService.formatPrice(serviceFee, locale), isSecondary: true),
          const Divider(height: 24),
          _buildPriceRow(l10n.totalAmount, _paymentService.formatPrice(totalAmount, locale), isBold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isSecondary = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isSecondary ? Colors.grey : Colors.black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: _buildMethodOption(icon: Icons.credit_card, label: l10n.bankCard, method: PaymentMethod.bankCard)),
        const SizedBox(width: 12),
        // تم تصحيح الخطأ هنا باستخدام نص يدوي في حال غياب الترجمة
        Expanded(child: _buildMethodOption(icon: Icons.account_balance_wallet, label: "Wallet", method: PaymentMethod.wallet)),
      ],
    );
  }

  Widget _buildMethodOption({required IconData icon, required String label, required PaymentMethod method}) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [Icon(icon), Text(label)]),
      ),
    );
  }

  Widget _buildCardForm(AppLocalizations l10n) {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(labelText: "Card Number", prefixIcon: Icon(Icons.payment)), // نص يدوي لتجنب الخطأ
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildProcessingState(AppLocalizations l10n) => const Center(child: CircularProgressIndicator());

  Widget _buildSuccessState(AppLocalizations l10n) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text("Payment Successful", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // نص يدوي
      ],
    ),
  );

  Widget _buildFailedState(AppLocalizations l10n) => const Center(child: Text("Payment Failed"));
  Widget _buildCancelledState(AppLocalizations l10n) => const Center(child: Text("Payment Cancelled"));
}
