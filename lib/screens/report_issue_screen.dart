import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedCategory;
  String _selectedPriority = "Düşük";

  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> _categories = [
    "Altyapı Sorunu",
    "Temizlik",
    "Güvenlik",
    "Teknik Sorun",
    "Ulaşım",
    "Diğer",
  ];

  bool get _isFormValid =>
      _selectedCategory != null &&
          _subjectController.text.isNotEmpty &&
          _descController.text.isNotEmpty;

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

  void _submit() {
    FocusScope.of(context).unfocus();

    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextMuted
        : AppTheme.textMuted;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                "Başarılı!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sorun bildiriminiz başarıyla iletildi. En kısa sürede ilgileneceğiz.",
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
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
      appBar: const CustomAppBar(title: "Sorun Bildir", showBack: true),
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
                      "Kampüste karşılaştığınız sorunları buradan yetkililere iletebilirsiniz.",
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
              decoration: _inputDecoration(context, label: "Kategori"),
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
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            Text(
              "Öncelik",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPriorityButton(context, "Düşük", AppTheme.successColor),
                const SizedBox(width: 8),
                _buildPriorityButton(context, "Orta", AppTheme.warningColor),
                const SizedBox(width: 8),
                _buildPriorityButton(
                  context,
                  "Yüksek",
                  AppTheme.destructiveColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _subjectController,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(context, label: "Konu"),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _locationController,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                context,
                label: "Konum (İsteğe Bağlı)",
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 5,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                context,
                label: "Açıklama",
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: () {},
                icon: Icon(Icons.camera_alt, color: mutedColor),
                label: Text(
                  "Fotoğraf Ekle (İsteğe Bağlı)",
                  style: TextStyle(color: mutedColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: borderColor,
                  disabledForegroundColor: mutedColor,
                ),
                child: const Text(
                  "Gönder",
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
      BuildContext context,
      String label,
      Color color,
      ) {
    final isSelected = _selectedPriority == label;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final borderColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = label),
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