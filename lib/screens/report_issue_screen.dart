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

  final List<String> _categories = ["Altyapı Sorunu", "Temizlik", "Güvenlik", "Teknik Sorun", "Ulaşım", "Diğer"];

  bool get _isFormValid => _selectedCategory != null && _subjectController.text.isNotEmpty && _descController.text.isNotEmpty;

  void _submit() {
    FocusScope.of(context).unfocus();

    // Show success dialog
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
              const Icon(Icons.check_circle, color: AppTheme.successColor, size: 64),
              const SizedBox(height: 16),
              const Text("Başarılı!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Sorun bildiriminiz başarıyla iletildi. En kısa sürede ilgileneceğiz.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );

    // Auto close dialog and screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // close dialog
      Navigator.of(context).pop(); // close screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Sorun Bildir", showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Expanded(child: Text("Kampüste karşılaştığınız sorunları buradan yetkililere iletebilirsiniz.", style: TextStyle(color: AppTheme.primaryColor))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            const Text("Öncelik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityButton("Düşük", AppTheme.successColor),
                const SizedBox(width: 8),
                _buildPriorityButton("Orta", AppTheme.warningColor),
                const SizedBox(width: 8),
                _buildPriorityButton("Yüksek", AppTheme.destructiveColor),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: "Konu", border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Konum (İsteğe Bağlı)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Açıklama", border: OutlineInputBorder(), alignLabelWithHint: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              onPressed: () {}, // Optional photo add action
              icon: const Icon(Icons.camera_alt, color: AppTheme.textMuted),
              label: const Text("Fotoğraf Ekle (İsteğe Bağlı)", style: TextStyle(color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppTheme.borderColor,
                ),
                child: const Text("Gönder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, Color color) {
    final isSelected = _selectedPriority == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : AppTheme.borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}