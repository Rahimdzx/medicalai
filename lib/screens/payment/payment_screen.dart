import 'package:flutter/material.dart';
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
  
  final PaymentService _paymentService = PaymentService();

  PaymentStatus _status = PaymentStatus.pending;
  PaymentMethod _selectedMethod = PaymentMethod.bankCard;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == PaymentMethod.bankCard && !_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _status = PaymentStatus.processing;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      final result = await _paymentService.processConsultationPayment(
        patientId: auth.user?.uid ?? 'guest',
        doctorId: widget.doctorId,
        appointmentId: widget.appointmentId,
        consultationFee: widget.consultationFee,
        method: _selectedMethod,
        cardLastFour: _selectedMethod == PaymentMethod.bankCard && _cardNumberController.text.length >= 4
            ? _cardNumberController.text.replaceAll(' ', '').substring(_cardNumberController.text.replaceAll(' ', '').length - 4)
            : null,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = result.status;
          _errorMessage = result.errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = PaymentStatus.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final totalAmount = _paymentService.calculateTotalAmount(widget.consultationFee);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payment),
        centerTitle: true,
      ),
      body: _buildBody(l10n, languageProvider.languageCode, totalAmount),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String locale, double totalAmount) {
    if (_status == PaymentStatus.processing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == PaymentStatus.success) {
      return _buildResultState(
        icon: Icons.check_circle,
        color: Colors.green,
        title: "Payment Successful",
        subtitle: "Your appointment has been confirmed.",
      );
    }

    if (_status == PaymentStatus.failed) {
      return _buildResultState(
        icon: Icons.error,
        color: Colors.red,
        title: "Payment Failed",
        subtitle: _errorMessage ?? "Something went wrong.",
        showRetry: true,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(l10n, locale, totalAmount),
            const SizedBox(height: 30),
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildMethodSelector(),
            const SizedBox(height: 25),
            if (_selectedMethod == PaymentMethod.bankCard) _buildCardFields(),
            const SizedBox(height: 40),
            _buildPayButton(totalAmount, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(AppLocalizations l10n, String locale, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Doctor"),
              Text(widget.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                _paymentService.formatPrice(total, locale),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(child: _methodCard(Icons.credit_card, "Card", PaymentMethod.bankCard)),
        const SizedBox(width: 12),
        Expanded(child: _methodCard(Icons.account_balance_wallet, "Wallet", PaymentMethod.wallet)),
      ],
    );
  }

  Widget _methodCard(IconData icon, String label, PaymentMethod method) {
    bool isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: "Card Number",
            prefixIcon: Icon(Icons.payment),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(labelText: "MM/YY", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "CVV", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayButton(double amount, String locale) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          "Confirm Payment (${_paymentService.formatPrice(amount, locale)})",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultState({required IconData icon, required Color color, required String title, required String subtitle, bool showRetry = false}) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (showRetry) {
                  setState(() => _status = PaymentStatus.pending);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(showRetry ? "Try Again" : "Done"),
            )
          ],
        ),
      ),
    );
  }
}
