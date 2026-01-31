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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (error != null && mounted) {
      final l10n = AppLocalizations.of(context);
      String message = error == 'user-not-found' ? l10n.userNotFound : 
                       error == 'wrong-password' ? l10n.wrongPassword : l10n.error;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primaryColor = const Color(0xFF007BFF); // اللون الأزرق الاحترافي

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
                  // شعار احترافي
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.health_and_safety, size: 80, color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.appTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 10),
                  Text("مرحباً بك مجدداً في نظامك الطبي", style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 40),

                  // حقل البريد
                  _buildInputDecoration(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        border: InputBorder.none,
                      ),
                      validator: (val) => val == null || !val.contains('@') ? l10n.invalidEmail : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // حقل كلمة المرور
                  _buildInputDecoration(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                        border: InputBorder.none,
                      ),
                      validator: (val) => val == null || val.length < 6 ? l10n.passwordTooShort : null,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // زر الدخول
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(l10n.login, style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
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

  Widget _buildInputDecoration({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }
}
