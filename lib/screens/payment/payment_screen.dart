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
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final result = await _paymentService.processConsultationPayment(
      patientId: auth.user?.uid ?? '',
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
      consultationFee: widget.consultationFee,
      method: _selectedMethod,
      cardLastFour: _selectedMethod == PaymentMethod.bankCard && _cardNumberController.text.length >= 4
          ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)
          : null,
    );

    setState(() {
      _isProcessing = false;
      _status = result.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Provider.of<LanguageProvider>(context).languageCode;
    final totalAmount = _paymentService.calculateTotalAmount(widget.consultationFee);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payment)),
      body: _buildBody(l10n, locale, totalAmount),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String locale, double totalAmount) {
    if (_status == PaymentStatus.processing) return const Center(child: CircularProgressIndicator());
    if (_status == PaymentStatus.success) return _buildSuccessState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSummaryCard(l10n, locale, totalAmount),
            const SizedBox(height: 24),
            _buildMethodSelector(),
            const SizedBox(height: 24),
            if (_selectedMethod == PaymentMethod.bankCard) _buildCardForm(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: Text("Pay ${totalAmount.toStringAsFixed(2)}"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(l10n, locale, total) {
    return Card(
      child: ListTile(
        title: Text(widget.doctorName),
        subtitle: Text(l10n.consultationFee),
        trailing: Text(total.toStringAsFixed(2)),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(child: _buildMethodOption(Icons.credit_card, "Card", PaymentMethod.bankCard)),
        const SizedBox(width: 10),
        // تم التأكد من مطابقة PaymentMethod.wallet مع الـ enum
        Expanded(child: _buildMethodOption(Icons.account_balance_wallet, "Wallet", PaymentMethod.wallet)),
      ],
    );
  }

  Widget _buildMethodOption(IconData icon, String label, PaymentMethod method) {
    bool isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [Icon(icon), Text(label)]),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(labelText: "Card Number"),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.check_circle, size: 100, color: Colors.green), Text("Success!")],
      ),
    );
  }
}
