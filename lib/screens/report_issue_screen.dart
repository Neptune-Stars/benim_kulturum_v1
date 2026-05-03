import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // YENİ: Firebase eklendi
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';


class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedCategory;
  String _selectedPriority = "Low";

  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> _categories = [
    "Infrastructure",
    "Cleaning",
    "Security",
    "Technical Issue",
    "Transportation",
    "Other",
  ];

  bool get _isFormValid =>
      _selectedCategory != null &&
          _subjectController.text.isNotEmpty &&
          _descController.text.isNotEmpty;

  // HATAYI DÜZELTEN METOT: Eksik olan tasarım fonksiyonu eklendi.
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    int docId = DateTime.now().millisecondsSinceEpoch;
    DateTime now = DateTime.now();
    String formattedDate =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    Map<String, dynamic> issueData = {
      "id": docId,
      "category": _selectedCategory ?? "Other",
      "priority": _selectedPriority,
      "subject": _subjectController.text.trim(),
      "location": _locationController.text.trim().isEmpty
          ? "Not Specified"
          : _locationController.text.trim(),
      "description": _descController.text.trim(),
      "date": formattedDate,
      "status": "Open",
      "createdAt": FieldValue.serverTimestamp(),
      "resolvedAt": null,
    };

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(docId.toString())
          .set(issueData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred while sending.")));
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 64),
            SizedBox(height: 16),
            Text("Success!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "Your report has been successfully submitted. We will take action as soon as possible.",
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
        Navigator.of(context).pop(); // Ekranı kapat
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: const CustomAppBar(title: "Report an Issue", showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      "You can report campus-related problems to the authorities from here.",
                      style: TextStyle(color: textColor))),
            ]),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: _inputDecoration(context, label: "Category"),
            value: _selectedCategory,
            dropdownColor: Theme.of(context).cardColor,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 20),
          Text("Priority",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 10),
          Row(children: [
            _buildPriorityButton(context, "Low", AppTheme.successColor),
            const SizedBox(width: 8),
            _buildPriorityButton(context, "Medium", AppTheme.warningColor),
            const SizedBox(width: 8),
            _buildPriorityButton(context, "High", AppTheme.destructiveColor),
          ]),
          const SizedBox(height: 20),
          TextField(
              controller: _subjectController,
              decoration: _inputDecoration(context, label: "Subject"),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 20),
          TextField(
              controller: _locationController,
              decoration: _inputDecoration(context, label: "Location (Optional)")),
          const SizedBox(height: 20),
          TextField(
              controller: _descController,
              maxLines: 5,
              decoration: _inputDecoration(context,
                  label: "Description", alignLabelWithHint: true),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 20),
          SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26))),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Demo: Photo upload feature is not active yet."))),
                icon: Icon(Icons.camera_alt, color: mutedColor),
                label: Text("Add Photo (Optional)",
                    style: TextStyle(color: mutedColor)),
              )),
          const SizedBox(height: 32),
          SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormValid ? _submit : null,
                child: const Text("Submit",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ))
        ]),
      ),
    );
  }

  Widget _buildPriorityButton(BuildContext context, String label, Color color) {
    final isSelected = _selectedPriority == label;
    return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedPriority = label),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: isSelected ? color : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? color : Theme.of(context).dividerColor)),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ),
        ));
  }
}