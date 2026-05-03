import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // YENİ: Firebase Firestore importu eklendi
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isStudent = true;
  bool _obscureText = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _autoFill() {
    setState(() {
      if (_isStudent) {
        _emailController.text = "student@uni.edu.tr";
        _passwordController.text = "123456";
      } else {
        _emailController.text = "admin@uni.edu.tr";
        _passwordController.text = "admin123";
      }
      _errorMessage = null;
    });
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Email and password cannot be empty.");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      if (!_isStudent) {
        if (email == "admin@uni.edu.tr" && password == "admin123") {
          context.read<AuthProvider>().login("admin", data: {"name": "System Admin", "no": "Admin", "grade": "Staff"});
          context.go('/admin');
        } else {
          setState(() => _errorMessage = "Invalid admin email or password.");
        }
      } else {
        var querySnapshot = await FirebaseFirestore.instance.collection('students').where('email', isEqualTo: email).where('password', isEqualTo: password).get();

        if (querySnapshot.docs.isNotEmpty) {
          final studentData = querySnapshot.docs.first.data();
          context.read<AuthProvider>().login("student", data: studentData);
          context.go('/main');
        } else {
          setState(() => _errorMessage = "Student record not found or incorrect password.");
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "A database connection error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.school, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text("Login", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _isStudent ? AppTheme.primaryColor : Theme.of(context).cardColor,
                        foregroundColor: _isStudent ? Colors.white : textColor),
                    onPressed: () => setState(() { _isStudent = true; _errorMessage = null; }),
                    child: const Text("Student"),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: !_isStudent ? AppTheme.primaryColor : Theme.of(context).cardColor,
                        foregroundColor: !_isStudent ? Colors.white : textColor),
                    onPressed: () => setState(() { _isStudent = false; _errorMessage = null; }),
                    child: const Text("Admin"),
                  )),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppTheme.destructiveColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.destructiveColor.withOpacity(0.25))),
                  child: Row(children: [const Icon(Icons.report_problem, color: AppTheme.destructiveColor, size: 20), const SizedBox(width: 8), Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.destructiveColor)))]),
                ),

              TextField(
                controller: _emailController, keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController, obscureText: _obscureText,
                decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: mutedColor), onPressed: () => setState(() => _obscureText = !_obscureText)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 32),
              SizedBox(height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _login, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(children: [
                  Text("Demo Account Credentials", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(_isStudent ? "student@uni.edu.tr / 123456" : "admin@uni.edu.tr / admin123", style: TextStyle(color: mutedColor), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton.icon(onPressed: _autoFill, icon: const Icon(Icons.edit, size: 18), label: const Text("Auto Fill")),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}