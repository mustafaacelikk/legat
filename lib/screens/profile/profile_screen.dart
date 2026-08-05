// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/profile_model.dart';
import '../../theme/app_theme.dart';
import '../../services/cleanup_logic.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profiles = profileProvider.all;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSectionHeader('Profiller'),
                  ),
                  const SizedBox(height: 8),
                  _buildProfileAvatarRow(context, profiles, profileProvider),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSectionHeader('Ayarlar'),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSettingsCard(context),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSectionHeader('Hakkında'),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildAboutCard(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.brand,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/icon/icon_white.png',
                        width: 20, height: 20),
                    const SizedBox(width: 8),
                    const Text('Profil & Ayarlar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('LEGAT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                    const SizedBox(width: 8),
                    const Text('·',
                        style: TextStyle(color: Colors.white38, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text('Her Şey Tamam, Legat Var',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showHelp(context),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.info_outline, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grayBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('LEGAT — Nasıl Kullanılır?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _helpSection('📋 Görevler', [
              'Alttaki + butonuna dokunarak görev ekle',
              'Sağa kaydır → Düzenle · Sola kaydır → Sil',
              'Çift dokun → Düzenleme ekranını aç',
              'Görev tamamlanınca bağlı hatırlatıcı da otomatik tamamlanır',
            ]),
            _helpSection('📝 Notlar', [
              'Alttaki + butonuna dokunarak not ekle',
              '"→ Dönüştür" ile notu Göreve veya Hatırlatıcıya çevir',
              'Arama ikonuyla başlık ve içerikte ara, sıralama seç',
            ]),
            _helpSection('🔔 Hatırlatıcılar', [
              'Arama türünde rehberden kişi seçilir; Ara veya Sohbet ile iletişime geç',
              'Bildirim üzerindeki Tamamlandı/Ertele butonlarıyla uygulamayı açmadan işlem yap',
              '"Görev" filtresiyle görevlere bağlı hatırlatıcılar ayrıca görülebilir',
            ]),
            _helpSection('📅 Takvim', [
              '2 Haftalık/Aylık görünümler arasında geçiş yap',
              'Bir güne dokunarak o günün görev ve hatırlatıcılarını gör',
              'Profil sekmeleriyle takvimi filtrele',
            ]),
            _helpSection('🗓️ Takvime Ekle', [
              'Görev, Not veya Hatırlatıcıyı uzun basılı menüden telefonunun kendi takvim uygulamasına (Google/Samsung/Outlook) tek dokunuşla ekleyebilirsin',
            ]),
            _helpSection('👤 Profil Sistemi', [
              'Sınırsız sayıda özel profil oluşturabilirsin',
              'Profil dairesine dokun → Kartvizit bilgileri; köşedeki kalem ikonuna dokun → Düzenle',
              'Kartvizit ekranındaki "⋮" menüsünden profili düzenleyebilir veya silebilirsin',
            ]),
            _helpSection('⚡ Hızlı Ekle', [
              'Ekranın altındaki mavi (+) butonuna dokunarak Görev/Not/Hatırlatıcı seçebilirsin',
              'Bu buton sürüklenebilir; istediğin kenara veya orta konumuna bırakabilirsin',
            ]),
            _helpSection('🔕 Bildirimler', [
              'İlk açılışta bildirim izni istenir, istersen "bir daha gösterme" seçebilirsin',
              'Profil > Bildirimler\'den bildirim sesini sistem ayarlarından değiştirebilirsin',
            ]),
            _helpSection('☀️ Bugün Ekranı', [
              'Tüm profillerin özeti burada; istatistik kartlarına dokununca ilgili sekmeye geçersin',
              'Bugüne ait hatırlatıcılar ve yaklaşan görevler burada listelenir',
            ]),
            _helpSection('⚙️ Ayarlar', [
              'Profil sekmesinden tamamlanmış görev ve hatırlatıcıları toplu temizleyebilirsin',
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _helpSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.brandMid)),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5)),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildProfileAvatarRow(
      BuildContext context, List<Profile> profiles, ProfileProvider provider) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          ...profiles.map((p) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildProfileAvatar(context, p, provider),
              )),
          _buildAddProfileAvatar(context),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
      BuildContext context, Profile profile, ProfileProvider provider) {
    final color = Color(profile.colorValue);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileDetailScreen(profile: profile),
          ),
        );
      },
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Icon(
                    profile.type == 'personal'
                        ? Icons.person
                        : profile.type == 'work'
                            ? Icons.work
                            : Icons.star_outline,
                    color: color,
                    size: 26,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: () =>
                        showEditProfileDialog(context, profile, provider),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child:
                          const Icon(Icons.edit, size: 11, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddProfileDialog(context),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandBorder, width: 1.5),
              ),
              child: const Icon(Icons.add, color: AppColors.brand, size: 26),
            ),
            const SizedBox(height: 6),
            const Text(
              'Yeni Ekle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final upcomingDays = context.watch<SettingsProvider>().upcomingDays;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.palette_outlined,
            iconColor: AppColors.brandMid,
            iconBg: AppColors.brandLight,
            title: 'Tema',
            subtitle: 'Açık tema',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('Yakında',
                  style: TextStyle(fontSize: 10, color: AppColors.grayText)),
            ),
            onTap: null,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.warnText,
            iconBg: AppColors.warnBg,
            title: 'Bildirimler',
            subtitle: 'Hatırlatıcı bildirimleri',
            onTap: () async {
              const intent = AndroidIntent(
                action: 'android.settings.CHANNEL_NOTIFICATION_SETTINGS',
                arguments: <String, dynamic>{
                  'android.provider.extra.APP_PACKAGE': 'com.example.herseyim',
                  'android.provider.extra.CHANNEL_ID': 'reminders_channel_v2',
                },
              );
              await intent.launch();
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 18, color: Color(0xFFE65100)),
            ),
            title: const Text('Yaklaşan Kayıtlar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(
              upcomingDays == 7
                  ? '1 Hafta'
                  : upcomingDays == 14
                      ? '2 Hafta'
                      : upcomingDays == 21
                          ? '3 Hafta'
                          : '1 Ay',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => _showUpcomingDaysPicker(context),
          ),
          const Divider(height: 1, color: AppColors.divider, indent: 16),
          _buildSettingsItem(
            icon: Icons.delete_sweep_outlined,
            iconColor: AppColors.dangerText,
            iconBg: AppColors.dangerBg,
            title: 'Tamamlananları Temizle',
            subtitle: 'Tamamlanmış görev ve hatırlatıcıları sil',
            onTap: () => _confirmClearCompleted(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.info_outline,
            iconColor: AppColors.brandMid,
            iconBg: AppColors.brandLight,
            title: 'Her Şeyim',
            subtitle: 'Versiyon 1.0.0',
            onTap: null,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.grayText,
            iconBg: AppColors.grayBg,
            title: 'Gizlilik',
            subtitle: 'Tüm veriler cihazınızda saklanır',
            onTap: null,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.badge_outlined,
            iconColor: AppColors.brand,
            iconBg: AppColors.brandLight,
            title: 'Test Kodun',
            subtitle: context.watch<SettingsProvider>().testCode,
            onTap: () {
              Clipboard.setData(ClipboardData(
                  text: context.read<SettingsProvider>().testCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test kodu kopyalandı')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, thickness: 0.5, indent: 68, color: AppColors.divider);
  }

  void _showUpcomingDaysPicker(BuildContext context) {
    final currentDays = context.read<SettingsProvider>().upcomingDays;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Yaklaşan Kayıtlar Aralığı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Bugün ekranında kaç günlük yaklaşan kayıtlar gösterilsin?',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ...[
              (7, '1 Hafta', '7 gün'),
              (14, '2 Hafta', '14 gün'),
              (21, '3 Hafta', '21 gün'),
              (30, '1 Ay', '30 gün'),
            ].map((item) {
              final (days, label, sublabel) = item;
              final isSelected = currentDays == days;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.brand : AppColors.textSecondary,
                ),
                title: Text(label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? AppColors.brand : AppColors.textPrimary,
                    )),
                subtitle: Text(sublabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                onTap: () {
                  context.read<SettingsProvider>().setUpcomingDays(days);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'personal';
    int selectedColor = 0xFF1F3864;

    final colors = [
      0xFF1F3864,
      0xFF185FA5,
      0xFF27500A,
      0xFF633806,
      0xFF791F1F,
      0xFF444441,
      0xFF6B21A8,
      0xFF0F766E,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.grayBorder,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Yeni Profil',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('Profil Adı',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Örn: Freelance, Aile...',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.brand, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tür',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _typeChip('personal', 'Kişisel', selectedType,
                          (v) => setS(() => selectedType = v)),
                      const SizedBox(width: 8),
                      _typeChip('work', 'İş', selectedType,
                          (v) => setS(() => selectedType = v)),
                      const SizedBox(width: 8),
                      _typeChip('custom', 'Özel', selectedType,
                          (v) => setS(() => selectedType = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Renk',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colors.map((c) {
                      final isSel = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setS(() => selectedColor = c),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel
                                  ? AppColors.textPrimary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSel
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('İptal',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          context.read<ProfileProvider>().add(Profile(
                                id: '',
                                name: nameController.text.trim(),
                                type: selectedType,
                                colorValue: selectedColor,
                                createdAt: DateTime.now(),
                              ));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Ekle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmClearCompleted(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tamamlananları Temizle',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        content: const Text(
          'Tamamlanmış tüm görevler ve hatırlatıcılar silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.dangerText),
            onPressed: () {
              final taskProvider = context.read<TaskProvider>();
              final reminderProvider = context.read<ReminderProvider>();

              final result = computeCompletedCleanup(
                  taskProvider.all, reminderProvider.all);

              for (final id in result.taskIdsToDelete) {
                taskProvider.delete(id);
              }
              for (final id in result.reminderIdsToDelete) {
                reminderProvider.delete(id);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tamamlananlar temizlendi')),
              );
            },
            child: const Text('Temizle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

void showEditProfileDialog(
    BuildContext context, Profile profile, ProfileProvider provider) {
  final nameController = TextEditingController(text: profile.name);
  int selectedColor = profile.colorValue;
  String selectedType = profile.type;

  final colors = [
    0xFF1F3864,
    0xFF185FA5,
    0xFF27500A,
    0xFF633806,
    0xFF791F1F,
    0xFF444441,
    0xFF6B21A8,
    0xFF0F766E,
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.grayBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Profili Düzenle',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                const Text('Profil Adı',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.brand, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tür',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _typeChip('personal', 'Kişisel', selectedType,
                        (v) => setS(() => selectedType = v)),
                    const SizedBox(width: 8),
                    _typeChip('work', 'İş', selectedType,
                        (v) => setS(() => selectedType = v)),
                    const SizedBox(width: 8),
                    _typeChip('custom', 'Özel', selectedType,
                        (v) => setS(() => selectedType = v)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Renk',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setS(() => selectedColor = c),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel
                                ? AppColors.textPrimary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                if (profile.id != 'personal' && profile.id != 'work') ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      confirmDeleteProfile(context, profile, provider);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: AppColors.dangerText),
                          SizedBox(width: 8),
                          Text('Profili Sil',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dangerText,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        profile.name = nameController.text.trim();
                        profile.colorValue = selectedColor;
                        profile.type = selectedType;
                        provider.update(profile);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _typeChip(String value, String label, String selected,
    ValueChanged<String> onChanged) {
  final isSelected = selected == value;
  return GestureDetector(
    onTap: () => onChanged(value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brand : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isSelected ? AppColors.brand : AppColors.divider),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          )),
    ),
  );
}

void confirmDeleteProfile(
    BuildContext context, Profile profile, ProfileProvider provider,
    {VoidCallback? onDeleted}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Profili Sil',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      content: Text(
        '"${profile.name}" profilini silmek istediğinize emin misiniz? Bu profile ait veriler etkilenmez.',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.dangerText),
          onPressed: () {
            provider.delete(profile.id);
            Navigator.pop(context);
            onDeleted?.call();
          },
          child: const Text('Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// KARTVİZİT & İLETİŞİM BİLGİLERİ EKRANI
// ═══════════════════════════════════════════════════════════════════════════

class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;
  const ProfileDetailScreen({super.key, required this.profile});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late Map<String, FocusNode> _focusNodes;
  bool _saving = false;
  bool _dirty = false;

  final _fields = [
    {
      'key': 'firstName',
      'label': 'Ad',
      'icon': Icons.person_outline,
      'hint': 'Adınız'
    },
    {
      'key': 'lastName',
      'label': 'Soyad',
      'icon': Icons.person_outline,
      'hint': 'Soyadınız'
    },
    {
      'key': 'email',
      'label': 'E-posta',
      'icon': Icons.email_outlined,
      'hint': 'ornek@email.com'
    },
    {
      'key': 'phone',
      'label': 'Telefon',
      'icon': Icons.phone_outlined,
      'hint': '+90 5xx xxx xx xx'
    },
    {
      'key': 'company',
      'label': 'Şirket',
      'icon': Icons.business_outlined,
      'hint': 'Şirket adı'
    },
    {
      'key': 'title',
      'label': 'Unvan',
      'icon': Icons.work_outline,
      'hint': 'Yazılım Geliştirici'
    },
    {
      'key': 'website',
      'label': 'Website',
      'icon': Icons.language_outlined,
      'hint': 'www.ornek.com'
    },
    {
      'key': 'address',
      'label': 'Adres',
      'icon': Icons.location_on_outlined,
      'hint': 'İstanbul, Türkiye'
    },
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProfileProvider>();
    final detail = provider.getProfileDetail(widget.profile.id);
    _controllers = {
      for (final f in _fields)
        f['key'] as String: TextEditingController(text: detail[f['key']] ?? '')
    };
    _focusNodes = {for (final f in _fields) f['key'] as String: FocusNode()};
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      for (final f in _fields)
        f['key'] as String: _controllers[f['key']]!.text.trim()
    };
    await context
        .read<ProfileProvider>()
        .saveProfileDetail(widget.profile.id, data);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bilgiler kaydedildi')),
      );
      _dirty = false;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.profile.colorValue);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (!_dirty) {
          Navigator.of(context).pop();
          return;
        }
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kaydedilmemiş Değişiklikler'),
            content: const Text(
                'Bu kayıtta değişiklik yaptınız. Değişiklikleri kaydetmek istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('İptal Et'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
        if (action == 'save') {
          await _save();
        } else if (action == 'discard') {
          _dirty = false;
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          titleSpacing: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                size: 18, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  widget.profile.type == 'personal' ? Icons.person : Icons.work,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const Text('Kartvizit & İletişim',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onSelected: (value) {
                final provider = context.read<ProfileProvider>();
                if (value == 'edit') {
                  showEditProfileDialog(context, widget.profile, provider);
                } else if (value == 'delete') {
                  confirmDeleteProfile(context, widget.profile, provider,
                      onDeleted: () => Navigator.pop(context));
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.brand),
                      SizedBox(width: 10),
                      Text('Profili Düzenle'),
                    ],
                  ),
                ),
                if (widget.profile.id != 'personal' &&
                    widget.profile.id != 'work')
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.dangerText),
                        SizedBox(width: 10),
                        Text('Profili Sil',
                            style: TextStyle(color: AppColors.dangerText)),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Kaydet',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Kartvizit önizleme
              _buildCardPreview(color),
              const SizedBox(height: 20),

              // Form alanları
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Column(
                  children: _fields.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final f = entry.value;
                    final isLast = idx == _fields.length - 1;
                    return Column(
                      children: [
                        _buildField(f, color),
                        if (!isLast)
                          const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 56,
                              color: AppColors.divider),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview(Color color) {
    final firstName = _controllers['firstName']!.text;
    final lastName = _controllers['lastName']!.text;
    final fullName =
        '${firstName.isNotEmpty ? firstName : 'Ad'} ${lastName.isNotEmpty ? lastName : 'Soyad'}';
    final title = _controllers['title']!.text;
    final company = _controllers['company']!.text;
    final email = _controllers['email']!.text;
    final phone = _controllers['phone']!.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                radius: 24,
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    if (title.isNotEmpty || company.isNotEmpty)
                      Text(
                        [
                          if (title.isNotEmpty) title,
                          if (company.isNotEmpty) company
                        ].join(' · '),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            if (email.isNotEmpty)
              Row(children: [
                const Icon(Icons.email_outlined,
                    color: Colors.white70, size: 13),
                const SizedBox(width: 6),
                Text(email,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.phone_outlined,
                    color: Colors.white70, size: 13),
                const SizedBox(width: 6),
                Text(phone,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildField(Map<String, Object> f, Color color) {
    final key = f['key'] as String;
    final isAddress = key == 'address';
    final index = _fields.indexWhere((e) => e['key'] == key);
    final isLast = index == _fields.length - 1;
    final nextFocus =
        isLast ? null : _focusNodes[_fields[index + 1]['key'] as String];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment:
            isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isAddress ? 14 : 0),
            child: Icon(f['icon'] as IconData,
                size: 18, color: color.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _controllers[key],
              focusNode: _focusNodes[key],
              maxLines: isAddress ? 2 : 1,
              keyboardType: key == 'email'
                  ? TextInputType.emailAddress
                  : key == 'phone'
                      ? TextInputType.phone
                      : key == 'website'
                          ? TextInputType.url
                          : TextInputType.text,
              textCapitalization:
                  key == 'email' || key == 'phone' || key == 'website'
                      ? TextCapitalization.none
                      : TextCapitalization.words,
              textInputAction:
                  isLast ? TextInputAction.done : TextInputAction.next,
              onFieldSubmitted: (_) {
                if (isLast) {
                  FocusManager.instance.primaryFocus?.unfocus();
                } else if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
              // Canlı önizleme için rebuild
              onChanged: (_) => setState(() {
                _dirty = true;
              }),
              decoration: InputDecoration(
                labelText: f['label'] as String,
                hintText: f['hint'] as String,
                labelStyle: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.grayBorder),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
