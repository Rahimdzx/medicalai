import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (error == null && mounted) {
      // الانتقال الفوري وحذف شاشة الدخول من الذاكرة
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (error != null && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primaryColor = const Color(0xFF007BFF);
    final authLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(primaryColor, l10n),
                  const SizedBox(height: 40),
                  _buildInput(child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: l10n.email, prefixIcon: Icon(Icons.email, color: primaryColor), border: InputBorder.none),
                    validator: (val) => val == null || !val.contains('@') ? l10n.invalidEmail : null,
                  )),
                  const SizedBox(height: 20),
                  _buildInput(child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.password, prefixIcon: Icon(Icons.lock, color: primaryColor), border: InputBorder.none),
                    validator: (val) => val == null || val.length < 6 ? l10n.passwordTooShort : null,
                  )),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: authLoading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: authLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.login, style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                    child: Text(l10n.noAccount, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color, AppLocalizations l10n) {
    return Column(
      children: [
        Icon(Icons.health_and_safety, size: 80, color: color),
        const SizedBox(height: 10),
        Text(l10n.appTitle, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInput({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: child,
    );
  }
}
