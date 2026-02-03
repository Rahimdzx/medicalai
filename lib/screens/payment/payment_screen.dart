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
    // التحقق من البيانات فقط في حالة اختيار البطاقة البنكية
    if (_selectedMethod == PaymentMethod.bankCard && !_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _status = PaymentStatus.processing;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // استخراج آخر 4 أرقام بأمان
      String? lastFour;
      if (_selectedMethod == PaymentMethod.bankCard && _cardNumberController.text.length >= 4) {
        lastFour = _cardNumberController.text.replaceAll(' ', '').substring(
          _cardNumberController.text.replaceAll(' ', '').length - 4
        );
      }

      final result = await _paymentService.processConsultationPayment(
        patientId: auth.user?.uid ?? '',
        doctorId: widget.doctorId,
        appointmentId: widget.appointmentId,
        consultationFee: widget.consultationFee,
        method: _selectedMethod,
        cardLastFour: lastFour,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = result.status;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = PaymentStatus.failed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام try-catch بسيط للتعامل مع ملفات l10n إذا كانت ناقصة
    String title = "Payment";
    try {
      title = AppLocalizations.of(context).payment;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_status == PaymentStatus.processing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == PaymentStatus.success) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Success!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Back to Home"),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMethodSelector(),
            const SizedBox(height: 24),
            if (_selectedMethod == PaymentMethod.bankCard) _buildCardForm(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  "Pay Now (\$${widget.consultationFee})",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Doctor:"),
                Text(widget.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Amount:"),
                Text("\$${widget.consultationFee}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(child: _buildMethodOption(Icons.credit_card, "Card", PaymentMethod.bankCard)),
        const SizedBox(width: 12),
        Expanded(child: _buildMethodOption(Icons.account_balance_wallet, "Wallet", PaymentMethod.wallet)),
      ],
    );
  }

  Widget _buildMethodOption(IconData icon, String label, PaymentMethod method) {
    final bool isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: "Card Number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.payment),
          ),
          keyboardType: TextInputType.number,
          validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: "MM/YY",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "CVV",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
