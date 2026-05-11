import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // YENİ: Firebase Firestore importu eklendi
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/joined_events_provider.dart';

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!_isStudent) {
        if (email == "admin@uni.edu.tr" && password == "admin123") {
          context.read<AuthProvider>().login("admin", data: {
            "name": "System Administrator",
            "no": "Admin",
            "grade": "Staff"
          });
          context.go('/admin');
        } else {
          setState(() => _errorMessage = "Invalid admin email or password.");
        }
      }
      else {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final studentDoc = querySnapshot.docs.first;

          final studentData = {
            ...studentDoc.data(),
            'firestoreDocId': studentDoc.id,
          };

          context.read<AuthProvider>().login("student", data: studentData);
          context.read<ProfileProvider>().initializeFromUserData(studentData);

          await context.read<FavoritesProvider>().loadForStudent(
            studentDocId: studentDoc.id,
            userData: studentData,
          );
          await context.read<JoinedEventsProvider>().loadForStudent(
            studentDocId: studentDoc.id,
            userData: studentData,
          );

          if (!mounted) return;
          context.go('/main');
        }
        else {
          setState(() => _errorMessage = "Registered student not found or invalid password.");
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "A database connection error occurred.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration(BuildContext context, {required String label, required IconData icon, Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = Theme.of(context).dividerColor;
    final fillColor = Theme.of(context).cardColor;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: mutedColor),
      prefixIcon: Icon(icon, color: mutedColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final inactiveBg = isDark ? cardColor : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text("Log In", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStudent ? AppTheme.primaryColor : inactiveBg,
                        foregroundColor: _isStudent ? Colors.white : textColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _isStudent ? AppTheme.primaryColor : borderColor)),
                      ),
                      onPressed: () => setState(() { _isStudent = true; _errorMessage = null; }),
                      child: const Text("Student"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isStudent ? AppTheme.primaryColor : inactiveBg,
                        foregroundColor: !_isStudent ? Colors.white : textColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: !_isStudent ? AppTheme.primaryColor : borderColor)),
                      ),
                      onPressed: () => setState(() { _isStudent = false; _errorMessage = null; }),
                      child: const Text("Admin"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppTheme.destructiveColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.destructiveColor.withOpacity(0.25))),
                  child: Row(
                    children: [
                      const Icon(Icons.report_problem, color: AppTheme.destructiveColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.destructiveColor))),
                    ],
                  ),
                ),

              TextField(
                controller: _emailController, keyboardType: TextInputType.emailAddress, style: TextStyle(color: textColor),
                decoration: _inputDecoration(context, label: "Email", icon: Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController, obscureText: _obscureText, style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  context, label: "Password", icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: mutedColor),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Log In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 36),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryLight.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                child: Column(
                  children: [
                    Text("Demo Account Details", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Text(_isStudent ? "student@uni.edu.tr / 123456" : "admin@uni.edu.tr / admin123", style: TextStyle(color: mutedColor), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton.icon(onPressed: _autoFill, icon: const Icon(Icons.edit, size: 18), label: const Text("Auto Fill")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}