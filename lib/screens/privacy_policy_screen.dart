import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import 'privacy_policy_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Gizlilik Politikası",
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),

            _PolicySection(
              icon: Icons.info_outline,
              title: "1. Genel Bilgilendirme",
              content:
              "Benim Kültürüm uygulaması, kampüs yaşamını daha düzenli ve erişilebilir hale getirmek amacıyla geliştirilmiştir. "
                  "Bu politika; uygulama içinde hangi bilgilerin görüntülendiğini, nasıl işlendiğini ve kullanıcı deneyimini iyileştirmek için nasıl kullanıldığını açıklar.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.person_outline,
              title: "2. Toplanan Bilgiler",
              content:
              "Uygulama; kullanıcı adı, öğrenci numarası, favoriler, katılınan etkinlikler ve uygulama içi tercih bilgileri gibi bazı temel verileri gösterebilir veya geçici olarak tutabilir. "
                  "Bu bilgiler kullanıcı deneyimini kişiselleştirmek amacıyla kullanılır.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.settings_outlined,
              title: "3. Bilgilerin Kullanımı",
              content:
              "Toplanan veya görüntülenen bilgiler; kullanıcıya uygun ekranları sunmak, favori içerikleri göstermek, etkinlik katılımlarını listelemek ve uygulama akışını yönetmek için kullanılır. "
                  "Veriler, kullanıcı deneyimini geliştirmek dışında farklı bir amaçla kullanılmaz.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.share_outlined,
              title: "4. Üçüncü Taraflarla Paylaşım",
              content:
              "Kullanıcı bilgileri, açık bir yasal zorunluluk veya kullanıcı onayı bulunmadıkça üçüncü taraflarla paylaşılmaz. "
                  "Uygulama içerisinde gösterilen veriler yalnızca sistem işleyişi kapsamında değerlendirilir.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.lock_outline,
              title: "5. Veri Güvenliği",
              content:
              "Kullanıcı bilgilerinin korunması için makul teknik ve tasarımsal önlemler alınır. "
                  "Ancak hiçbir dijital sistem yüzde yüz risksiz değildir. Bu nedenle kullanıcıların da hesap bilgilerini dikkatli kullanması beklenir.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.visibility_outlined,
              title: "6. Kullanıcı Hakları",
              content:
              "Kullanıcılar, uygulama içinde görüntülenen bilgileri inceleyebilir; yanlış veya güncel olmayan bilgiler için destek kanalları üzerinden geri bildirim verebilir. "
                  "Gerektiğinde verilerin güncellenmesi veya düzeltilmesi talep edilebilir.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.update_outlined,
              title: "7. Politika Güncellemeleri",
              content:
              "Bu gizlilik politikası ihtiyaçlara göre güncellenebilir. Önemli değişiklikler olduğunda kullanıcıya uygulama içinde bilgilendirme yapılması hedeflenir.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.mail_outline,
              title: "8. İletişim",
              content:
              "Gizlilik politikası hakkında sorularınız veya geri bildirimleriniz için uygulama içindeki “Sorun Bildir” bölümü üzerinden iletişime geçebilirsiniz.",
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.20),
                ),
              ),
              child: const Text(
                "Bu ekran şu an uygulama içi bilgilendirme amaçlı hazırlanmıştır. "
                    "Gerçek bir yayına çıkılacaksa metin, hukukî ve kurumsal gerekliliklere göre yeniden gözden geçirilmelidir.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 12),
          const Text(
            "Kullanıcı Verilerinin Korunması",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Uygulamada görüntülenen ve işlenen temel kullanıcı verilerine ilişkin bilgilendirme metni.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              AppBadge(
                label: "Son Güncelleme: 2026",
                backgroundColor: Colors.white24,
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}