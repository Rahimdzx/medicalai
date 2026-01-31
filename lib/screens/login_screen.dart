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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (error == null && mounted) {
      // الحل الجذري: الانتقال لصفحة الـ main ليتولى الـ Consumer التوجيه
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                Icon(Icons.health_and_safety, size: 80, color: Colors.blue[700]),
                const SizedBox(height: 20),
                Text(l10n.appTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                _buildField(child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.email, border: InputBorder.none),
                  validator: (val) => val!.isEmpty ? l10n.pleaseEnterEmail : null,
                )),
                const SizedBox(height: 20),
                _buildField(child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.password, border: InputBorder.none),
                  validator: (val) => val!.length < 6 ? l10n.passwordTooShort : null,
                )),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: authLoading ? null : _login,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: authLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.login, style: const TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                  child: Text(l10n.noAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: child,
    );
  }
}
