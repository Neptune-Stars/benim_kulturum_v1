import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../data/data_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedCategory;
  String _selectedPriority = "normal";
  bool _isSubmitting = false;

  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> _categories = [
    "Infrastructure Issue",
    "Cleaning",
    "Security",
    "Technical Issue",
    "Transportation",
    "Other",
  ];

  bool get _isFormValid {
    return _selectedCategory != null &&
        _subjectController.text.trim().isNotEmpty &&
        _descController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
      BuildContext context, {
        required String label,
        bool alignLabelWithHint = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = Theme.of(context).dividerColor;
    final fillColor = Theme.of(context).cardColor;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: mutedColor),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
    );
  }

  String _formatLocalDate(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/"
        "${dateTime.month.toString().padLeft(2, '0')}/"
        "${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in category, subject, and description."),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userData = authProvider.userData ?? {};

    final studentId = authProvider.currentUserDocId ?? '';
    final studentName = userData['name']?.toString() ?? 'Unknown Student';
    final studentEmail = userData['email']?.toString() ?? '';

    final title = _subjectController.text.trim();
    final description = _descController.text.trim();
    final category = _selectedCategory ?? "Other";
    final location = _locationController.text.trim().isEmpty
        ? "Not specified"
        : _locationController.text.trim();

    final docRef = FirebaseFirestore.instance.collection('issues').doc();
    final now = DateTime.now();

    final Map<String, dynamic> issueData = {
      // Required / standard fields
      "id": docRef.id,
      "title": title,
      "description": description,
      "category": category,
      "status": "open",
      "priority": _selectedPriority,
      "studentId": studentId,
      "studentName": studentName,
      "studentEmail": studentEmail,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),

      // Extra fields still useful for the current admin UI / old compatibility
      "subject": title,
      "location": location,
      "date": _formatLocalDate(now),
      "resolvedAt": null,
    };

    try {
      await docRef.set(issueData);

      // Prevent stale admin/dashboard cache in the same app session.
      DataService.clearCollectionCache('issues');

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      final textColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
      final mutedColor = Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkTextMuted
          : AppTheme.textMuted;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your issue report has been submitted successfully. The administration can now review it.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor),
                ),
              ],
            ),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Issue report could not be submitted: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: const CustomAppBar(title: "Report Issue", showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryColor.withOpacity(0.14)
                    : AppTheme.primaryLight.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppTheme.primaryColor.withOpacity(0.20)
                      : AppTheme.primaryLight.withOpacity(0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You can report campus, technical, cleaning, security, or transportation issues to the administration from here.",
                      style: TextStyle(
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              decoration: _inputDecoration(context, label: "Category"),
              value: _selectedCategory,
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(color: textColor),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                });
              },
            ),

            const SizedBox(height: 20),

            Text(
              "Priority",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPriorityButton(
                  context,
                  value: "normal",
                  label: "Normal",
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                _buildPriorityButton(
                  context,
                  value: "medium",
                  label: "Medium",
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                _buildPriorityButton(
                  context,
                  value: "high",
                  label: "High",
                  color: AppTheme.destructiveColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _subjectController,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(context, label: "Subject"),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _locationController,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                context,
                label: "Location (Optional)",
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 5,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                context,
                label: "Description",
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: borderColor,
                  disabledForegroundColor: mutedColor,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(
      BuildContext context, {
        required String value,
        required String label,
        required Color color,
      }) {
    final isSelected = _selectedPriority == value;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final borderColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}