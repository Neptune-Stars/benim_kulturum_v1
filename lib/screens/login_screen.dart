import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _autoFill() {
    setState(() {
      if (_isStudent) {
        _emailController.text = "ogrenci@uni.edu.tr";
        _passwordController.text = "123456";
      } else {
        _emailController.text = "admin@uni.edu.tr";
        _passwordController.text = "admin123";
      }
      _errorMessage = null;
    });
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isStudent && email == "ogrenci@uni.edu.tr" && password == "123456") {
      context.read<AuthProvider>().login("student");
      context.go('/main');
    } else if (!_isStudent && email == "admin@uni.edu.tr" && password == "admin123") {
      context.read<AuthProvider>().login("admin");
      context.go('/admin');
    } else {
      setState(() {
        _errorMessage = "E-posta veya şifre hatalı. Lütfen tekrar deneyin.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                "Giriş Yap",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 32),

              // Role Selector
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStudent ? AppTheme.primaryColor : Colors.white,
                        foregroundColor: _isStudent ? Colors.white : AppTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: _isStudent ? AppTheme.primaryColor : AppTheme.borderColor),
                        ),
                      ),
                      onPressed: () => setState(() {
                        _isStudent = true;
                        _errorMessage = null;
                      }),
                      child: const Text("Öğrenci"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isStudent ? AppTheme.primaryColor : Colors.white,
                        foregroundColor: !_isStudent ? Colors.white : AppTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: !_isStudent ? AppTheme.primaryColor : AppTheme.borderColor),
                        ),
                      ),
                      onPressed: () => setState(() {
                        _isStudent = false;
                        _errorMessage = null;
                      }),
                      child: const Text("Yönetici"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error Banner
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.destructiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.report_problem, color: AppTheme.destructiveColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.destructiveColor)),
                      ),
                    ],
                  ),
                ),

              // Form Fields
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 48),

              // Demo Credentials Hint Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    const Text("Demo Hesap Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      _isStudent ? "ogrenci@uni.edu.tr / 123456" : "admin@uni.edu.tr / admin123",
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _autoFill,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Otomatik Doldur"),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}