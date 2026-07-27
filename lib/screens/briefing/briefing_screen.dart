import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/task_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart'; // MainScreenState için

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  Future<void> _checkNotificationPermission() async {
    final settings = context.read<SettingsProvider>();
    if (settings.notificationPermissionAsked) return;
    if (!mounted) return;

    bool dontAskAgain = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Bildirim İzni'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legat size hatırlatıcı bildirimleri gönderebilmek için izin istiyor.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: dontAskAgain,
                    activeColor: AppColors.brand,
                    onChanged: (v) =>
                        setDialogState(() => dontAskAgain = v ?? false),
                  ),
                  const Expanded(
                    child: Text('Bir daha gösterme',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'later'),
              child: const Text('Daha Sonra'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'allow'),
              child: const Text('İzin Ver'),
            ),
          ],
        ),
      ),
    );

    if (result == 'allow') {
      await NotificationService.instance.requestPermission();
      await settings.setNotificationPermissionAsked(true);
    } else if (result == 'later' && dontAskAgain) {
      await settings.setNotificationPermissionAsked(true);
    }
    // 'later' ve dontAskAgain false ise: hiçbir şey kaydedilmez, bir sonraki açılışta tekrar sorulur.
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final upcomingDays = context.watch<SettingsProvider>().upcomingDays;

    const activeId = 'all';

    final allTasks = taskProvider.byProfile(activeId);
    final allNotes = noteProvider.byProfile(activeId);
    final allReminders = reminderProvider.byProfile(activeId);

    final now = DateTime.now();

    final activeTasks = allTasks
        .where((t) =>
            t.status != 'Tamamlandı' &&
            (t.dueDate == null ||
                t.dueDate!.difference(now).inDays <= upcomingDays))
        .toList()
      ..sort((a, b) {
        final priorityOrder = {'Kritik': 0, 'Yüksek': 1, 'Orta': 2, 'Düşük': 3};
        return (priorityOrder[a.priority] ?? 2)
            .compareTo(priorityOrder[b.priority] ?? 2);
      });
    final activeNotes = allNotes.where((n) => !n.convertedToTask).toList();
    final activeReminders = allReminders.where((r) => !r.isCompleted).toList();

    final completedCount =
        allTasks.where((t) => t.status == 'Tamamlandı').length;

    final upcomingCount = allTasks.where((t) {
          if (t.dueDate == null || t.status == 'Tamamlandı') return false;
          final diff = t.dueDate!.difference(now).inDays;
          return diff >= 0 && diff <= upcomingDays;
        }).length +
        allReminders.where((r) {
          if (r.isCompleted) return false;
          final diff = r.scheduledAt.difference(now).inDays;
          return diff >= 0 && diff <= upcomingDays;
        }).length;

    final overdueCount = allTasks
        .where((t) =>
            t.dueDate != null &&
            t.dueDate!.isBefore(now) &&
            t.status != 'Tamamlandı')
        .length;

    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayAllReminders = allReminders
        .where((r) =>
            !r.isCompleted &&
            r.scheduledAt.isAfter(todayStart) &&
            r.scheduledAt.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final hour = now.hour;
    final greeting = hour < 12
        ? 'Günaydın'
        : hour < 18
            ? 'İyi günler'
            : 'İyi akşamlar';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, greeting),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatCards(
                      context,
                      taskCount: activeTasks.length,
                      noteCount: activeNotes.length,
                      reminderCount: activeReminders.length,
                      completedCount: completedCount,
                      upcomingCount: upcomingCount,
                      overdueCount: overdueCount,
                    ),
                    _buildSectionTitle(),
                    if (todayAllReminders.isNotEmpty)
                      _buildTodayAllReminders(context, todayAllReminders),
                    if (activeTasks.isNotEmpty)
                      _buildTaskSection(context, activeTasks),
                    if (activeTasks.isEmpty && todayAllReminders.isEmpty)
                      _buildEmpty(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String greeting) {
    final profileProvider = context.watch<ProfileProvider>();
    final profiles = profileProvider.all;
    final personalProfile =
        profiles.where((p) => p.type == 'personal').firstOrNull;
    final detail = personalProfile != null
        ? profileProvider.getProfileDetail(personalProfile.id)
        : <String, String>{};
    final firstName = detail['firstName'] ?? '';
    final displayName = firstName.isNotEmpty ? firstName : '';
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return Container(
      color: AppColors.brand,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icon/icon_white.png', width: 24, height: 24),
              const SizedBox(width: 8),
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
              const Text('Her Şey Tamam, Legat Var',
                  style: TextStyle(
                      color: Colors.white60, fontSize: 10, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isNotEmpty
                          ? '$greeting, $displayName'
                          : greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMMM yyyy, EEEE', 'tr_TR')
                          .format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final mainState =
                      context.findAncestorStateOfType<MainScreenState>();
                  mainState?.goToProfile();
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelp(context),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Text('i',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat kartları — tıklanabilir, ilgili sekmeye yönlendiriyor ───────────
  Widget _buildStatCards(
    BuildContext context, {
    required int taskCount,
    required int noteCount,
    required int reminderCount,
    required int completedCount,
    required int upcomingCount,
    required int overdueCount,
  }) {
    // index: 1=Görevler, 2=Takvim, 3=Notlar, 4=Hatırlatıcı
    void goTo(int index) {
      final mainState = context.findAncestorStateOfType<MainScreenState>();
      mainState?.goToTab(index);
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _statCard(
                  'Görevler',
                  taskCount.toString(),
                  const Color(0xFFE8F0FE),
                  const Color(0xFF1F3864),
                  () => goTo(1)),
              const SizedBox(width: 8),
              _statCard('Notlar', noteCount.toString(), const Color(0xFFF3E8FF),
                  const Color(0xFF6B21A8), () => goTo(3)),
              const SizedBox(width: 8),
              _statCard(
                  'Hatırlatıcı',
                  reminderCount.toString(),
                  const Color(0xFFE8F5E9),
                  const Color(0xFF1B5E20),
                  () => goTo(4)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard(
                  'Yaklaşan\nKayıtlar',
                  upcomingCount.toString(),
                  const Color(0xFFFFF8E1),
                  const Color(0xFFE65100),
                  () => goTo(2)),
              const SizedBox(width: 8),
              _statCard(
                  'Tamamlanan\nGörevler',
                  completedCount.toString(),
                  const Color(0xFFE0F2F1),
                  const Color(0xFF00695C),
                  completedCount > 0
                      ? () {
                          final mainState = context
                              .findAncestorStateOfType<MainScreenState>();
                          mainState?.goToTab(1, filter: 'Tamamlandı');
                        }
                      : null),
              const SizedBox(width: 8),
              _statCard(
                  'Geciken\nGörevler',
                  overdueCount.toString(),
                  const Color(0xFFFFEBEE),
                  const Color(0xFFB71C1C),
                  overdueCount > 0
                      ? () {
                          final mainState = context
                              .findAncestorStateOfType<MainScreenState>();
                          mainState?.goToTab(1, filter: 'Geciken');
                        }
                      : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, Color bg, Color fg, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // null ise tıklanamaz
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: fg)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: fg.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Text('Bugünün Özeti',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );
  }

  Widget _buildTodayAllReminders(BuildContext context, List reminders) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_outlined,
                  size: 15, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Hatırlatıcılar',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ...reminders.map((r) {
            final isCall = r.type == 'Arama';
            final isSMS = r.type == 'SMS';
            final isWA = r.type == 'Sohbet';
            final isContact = isCall || isSMS || isWA;

            return GestureDetector(
              onTap: () {
                final mainState =
                    context.findAncestorStateOfType<MainScreenState>();
                mainState?.goToTab(4);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCall
                          ? Icons.phone_outlined
                          : isSMS
                              ? Icons.sms_outlined
                              : isWA
                                  ? Icons.forum_outlined
                                  : r.type == 'Özel Gün' &&
                                          r.specialDayType == 'Doğum Günü'
                                      ? Icons.cake_outlined
                                      : r.type == 'Özel Gün' &&
                                              r.specialDayType == 'Yıldönümü'
                                          ? Icons.favorite_outline
                                          : Icons.notifications_outlined,
                      size: 16,
                      color: const Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1B5E20),
                                  fontSize: 13)),
                          Text(
                            DateFormat('HH:mm', 'tr_TR').format(r.scheduledAt),
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                    ),
                    if (isContact &&
                        r.contactPhone != null &&
                        r.contactPhone!.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final phone = r.contactPhone!;
                          if (isCall) {
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          } else if (isSMS) {
                            final uri = Uri(scheme: 'sms', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          } else {
                            final cleanPhone =
                                phone.replaceAll(RegExp(r'[^0-9+]'), '');
                            final intent = AndroidIntent(
                              action: 'android.intent.action.SEND',
                              type: 'text/plain',
                              arguments: <String, dynamic>{
                                'android.intent.extra.TEXT': 'Merhaba',
                                'address': cleanPhone,
                              },
                            );
                            await intent.launch();
                          }
                        },
                        icon: Icon(
                          isCall
                              ? Icons.phone
                              : isSMS
                                  ? Icons.sms
                                  : Icons.chat,
                          size: 14,
                        ),
                        label: Text(
                          isCall
                              ? 'Ara'
                              : isSMS
                                  ? 'SMS'
                                  : 'Sohbet',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskSection(BuildContext context, List activeTasks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 15, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Görevler',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ...activeTasks.take(5).map((t) {
            final priorityColor = t.priority == 'Kritik'
                ? const Color(0xFFB71C1C)
                : t.priority == 'Yüksek'
                    ? const Color(0xFFE65100)
                    : t.priority == 'Orta'
                        ? const Color(0xFF1F3864)
                        : const Color(0xFF00695C);
            final priorityBg = t.priority == 'Kritik'
                ? const Color(0xFFFFEBEE)
                : t.priority == 'Yüksek'
                    ? const Color(0xFFFFF8E1)
                    : t.priority == 'Orta'
                        ? const Color(0xFFE8F0FE)
                        : const Color(0xFFE0F2F1);

            return GestureDetector(
              onTap: () {
                final mainState =
                    context.findAncestorStateOfType<MainScreenState>();
                mainState?.goToTab(1);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1F3864).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF1F3864))),
                          if (t.dueDate != null)
                            Text(
                              'Bitiş: ${DateFormat('d MMM', 'tr_TR').format(t.dueDate!)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF1F3864)),
                            ),
                          if (t.completionPercent > 0) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: t.completionPercent / 100,
                              backgroundColor: const Color(0xFFBBCEFA),
                              color: const Color(0xFF1F3864),
                              minHeight: 3,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(t.priority,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: priorityColor)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.wb_sunny_outlined,
                size: 64, color: AppColors.grayBorder),
            SizedBox(height: 16),
            Text('Bugün için görev yok',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Harika bir gün geçir!',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
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
            const Text('Her Şeyim — Nasıl Kullanılır?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _helpSection('📋 Görevler', [
              'Görev eklemek için Görevler sekmesindeki + butonuna bas',
              'Görevi sola kaydır → Sil',
              'Görevi sağa kaydır → Düzenle',
              'Göreve tıkla → Detay ve düzenleme',
              'Tamamlanma yüzdesi düzenleme ekranından ayarlanır',
            ]),
            _helpSection('📝 Notlar', [
              'Not eklemek için Notlar sekmesindeki + butonuna bas',
              'Notu sola kaydır → Sil',
              'Notu sağa kaydır → Düzenle',
              '"→ Göreve Dönüştür" butonu notu göreve çevirir',
              'Göreve dönüşen notlar üstü çizili olarak görünür',
            ]),
            _helpSection('🔔 Hatırlatıcılar', [
              'Hatırlatıcılar sekmesinden yönet',
              'Arama türü seçilirse rehberden kişi bilgisi girilir',
              'Hatırlatıcıyı sola kaydır → Sil',
              'Hatırlatıcıyı sağa kaydır → Tamamlandı olarak işaretle',
              'Erteleme süresi ekleme ekranından ayarlanır',
            ]),
            _helpSection('📅 Takvim', [
              'Google, Outlook ve Apple takvimleri bağlanabilir',
              'Ay / Hafta / Gün görünümleri arasında geç',
              'Toplantı detayına tıkla → Not ve aksiyonlar ekle',
            ]),
            _helpSection('⚡ Hızlı Ekle', [
              'Herhangi bir sekme ikonuna uzun bas → Hızlı Ekle menüsü açılır',
              'Görev, Not veya Hatırlatıcı hızlıca eklenebilir',
            ]),
            _helpSection('👤 Profil Sistemi', [
              'Kişisel ve İş profilleri ayrı takip edilir',
              'Üstteki profil barından anlık geçiş yapılır',
              '"Tümü" seçilince tüm profiller birlikte görünür',
              'Her görev/not/hatırlatıcı bir profile atanır',
            ]),
            _helpSection('☀️ Bugün Ekranı', [
              'Tüm profillerden özet her zaman burada görünür',
              'Yaklaşan: 7 gün içindeki işlemler',
              'Geciken: Tarihi geçmiş tamamlanmamış işlemler',
              'Arama hatırlatıcıları için "Ara" butonu doğrudan çalışır',
              'İstatistik kartlarına tıklayarak ilgili sekmeye geç',
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
}
