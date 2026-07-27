import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/reminder_model.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _filter = 'Tümü';
  final _filters = ['Tümü', 'İletişim', 'Özel Gün', 'Görev', 'Bekleyen', 'Geciken', 'Tamamlandı'];
  String _searchQuery = '';
  String _sortType = 'Öncelik'; // 'Tarih' | 'Öncelik' | 'Alfabetik'

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final activeId = profileProvider.activeProfileId;

    List<Reminder> reminders = reminderProvider.byProfile(activeId);

    if (_filter != 'Görev') {
      reminders = reminders.where((r) => r.taskId == null).toList();
    }

    if (_filter == 'Görev') {
      reminders = reminders.where((r) => r.taskId != null).toList();
    } else if (_filter == 'İletişim') {
      reminders = reminders
          .where((r) => r.type == 'Arama' || r.type == 'Sohbet')
          .toList();
    } else if (_filter == 'Özel Gün') {
      reminders = reminders.where((r) => r.type == 'Özel Gün').toList();
    } else if (_filter == 'Bekleyen') {
      reminders = reminders.where((r) => !r.isCompleted).toList();
    } else if (_filter == 'Geciken') {
      reminders = reminders
          .where((r) => !r.isCompleted && r.scheduledAt.isBefore(DateTime.now()))
          .toList();
    } else if (_filter == 'Tamamlandı') {
      reminders = reminders.where((r) => r.isCompleted).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      reminders = reminders.where((r) =>
          r.title.toLowerCase().contains(q) ||
          (r.contactName?.toLowerCase().contains(q) ?? false)).toList();
    }

    if (_sortType == 'Alfabetik') {
      reminders.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortType == 'Tarih') {
      reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } else {
      reminders.sort((a, b) {
        int priority(Reminder r) {
          if (r.isCompleted) return 3;
          final now = DateTime.now();
          final isToday = r.scheduledAt.year == now.year &&
              r.scheduledAt.month == now.month &&
              r.scheduledAt.day == now.day &&
              !r.scheduledAt.isBefore(now);
          final isOverdue = r.scheduledAt.isBefore(now);
          if (isToday) return 0;
          if (isOverdue) return 1;
          return 2;
        }
        final pa = priority(a);
        final pb = priority(b);
        if (pa != pb) return pa.compareTo(pb);
        return a.scheduledAt.compareTo(b.scheduledAt);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, profileProvider, activeId),
            _buildFilters(),
            if (_searchQuery.isNotEmpty)
              Container(
                width: double.infinity,
                color: AppColors.brandLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 14, color: AppColors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('"$_searchQuery" için sonuçlar',
                          style: const TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _searchQuery = ''),
                      child: const Icon(Icons.close, size: 16, color: AppColors.brand),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: reminders.isEmpty ? _buildEmpty() : _buildList(reminders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ProfileProvider pp, String activeId) {
    // Sabit profiller önce, sonra özel profiller ekleme sırasına göre
    final fixedProfiles =
        pp.all.where((p) => p.id == 'personal' || p.id == 'work').toList();
    final customProfiles =
        pp.all.where((p) => p.id != 'personal' && p.id != 'work').toList();
    final orderedProfiles = [...fixedProfiles, ...customProfiles];
    return Container(
      color: AppColors.brand,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icon/icon_white.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text('Hatırlatıcılar',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showSearchSort(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.manage_search, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelp(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('i',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _profileTab('Tümü', 'all', activeId, pp),
                ...orderedProfiles.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _profileTab(p.name, p.id, activeId, pp),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTab(
      String label, String id, String activeId, ProfileProvider pp) {
    final isActive = activeId == id;
    return GestureDetector(
      onTap: () => pp.setActive(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: isActive ? AppColors.brand : Colors.white,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _filters.map((f) {
          final isActive = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.brand : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.brand : AppColors.divider,
                  width: 0.5,
                ),
              ),
              child: Text(f,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(List<Reminder> reminders) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: reminders.map((r) => _buildCard(r)).toList(),
    );
  }

  Widget _buildCard(Reminder reminder) {
    final isCall = reminder.type == 'Arama';
    final isOverdue =
        !reminder.isCompleted && reminder.scheduledAt.isBefore(DateTime.now());

    final now = DateTime.now();
    final isToday = !reminder.isCompleted &&
        reminder.scheduledAt.year == now.year &&
        reminder.scheduledAt.month == now.month &&
        reminder.scheduledAt.day == now.day &&
        !reminder.scheduledAt.isBefore(now);

    final bg = reminder.isCompleted
        ? const Color(0xFFE0F2F1)
        : isToday
            ? const Color(0xFFFFF3E0)
            : isOverdue
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFE8F5E9);

    final borderColor = reminder.isCompleted
        ? const Color(0xFF00695C).withValues(alpha: 0.3)
        : isToday
            ? const Color(0xFFE65100).withValues(alpha: 0.4)
            : isOverdue
                ? const Color(0xFFB71C1C).withValues(alpha: 0.3)
                : const Color(0xFF1B5E20).withValues(alpha: 0.2);

    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.dangerText,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddReminderScreen(reminder: reminder)));
          return false;
        } else {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hatırlatıcıyı Sil'),
                  content: Text('"${reminder.title}" silinsin mi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sil',
                          style: TextStyle(color: AppColors.dangerText)),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<ReminderProvider>().delete(reminder.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${reminder.title}" silindi'),
              backgroundColor: AppColors.brand,
            ),
          );
        }
      },
      child: GestureDetector(
        onLongPress: () => _showReminderMenu(context, reminder),
        onDoubleTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddReminderScreen(reminder: reminder)));
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
            Icon(
              reminder.isCompleted
                  ? Icons.check_circle
                  : reminder.type == 'Arama'
                      ? Icons.phone_outlined
                      : reminder.type == 'Sohbet'
                          ? Icons.forum_outlined
                          : reminder.type == 'Özel Gün' &&
                                  reminder.specialDayType == 'Doğum Günü'
                              ? Icons.cake_outlined
                              : reminder.type == 'Özel Gün' &&
                                      reminder.specialDayType == 'Yıldönümü'
                                  ? Icons.favorite_outline
                                  : Icons.notifications_outlined,
              color: reminder.isCompleted
                  ? AppColors.successText
                  : AppColors.warnText,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: reminder.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (isCall && reminder.contactPhone != null)
                    Text(reminder.contactPhone!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM y, HH:mm', 'tr_TR')
                            .format(reminder.scheduledAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOverdue && !reminder.isCompleted
                              ? AppColors.dangerText
                              : AppColors.textSecondary,
                          fontWeight: isOverdue && !reminder.isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue && !reminder.isCompleted) ...[
                        const SizedBox(width: 4),
                        const Text('· Gecikti',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.dangerText,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      String countdownText;
                      Color countdownColor;

                      final diffInHours =
                          reminder.scheduledAt.difference(now).inHours;
                      final diffInDays =
                          reminder.scheduledAt.difference(now).inDays;

                      if (diffInHours >= 0 && diffInDays == 0) {
                        countdownText = 'Bugün!';
                        countdownColor = const Color(0xFFE65100);
                      } else if (diffInHours < 0 && diffInHours >= -24) {
                        countdownText = 'Dün';
                        countdownColor = const Color(0xFFB71C1C);
                      } else if (diffInDays < 0) {
                        countdownText = '${diffInDays.abs()} gün geçti';
                        countdownColor = const Color(0xFFB71C1C);
                      } else if (diffInDays == 1) {
                        countdownText = 'Yarın';
                        countdownColor = const Color(0xFFE65100);
                      } else {
                        countdownText = '$diffInDays gün sonra';
                        countdownColor = AppColors.textSecondary;
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: countdownColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: countdownColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '⏱ $countdownText',
                          style: TextStyle(
                            fontSize: 10,
                            color: countdownColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (!reminder.isCompleted &&
                reminder.contactPhone != null &&
                reminder.contactPhone!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reminder.communicationTypes.contains('Ara') ||
                      reminder.type == 'Arama')
                    _iconActionButton(
                      icon: Icons.phone,
                      onTap: () async {
                        final uri =
                            Uri(scheme: 'tel', path: reminder.contactPhone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  if (reminder.communicationTypes.contains('Sohbet') ||
                      reminder.type == 'Sohbet') ...[
                    const SizedBox(width: 6),
                    _iconActionButton(
                      icon: Icons.forum_outlined,
                      onTap: () async {
                        final phone = reminder.contactPhone!
                            .replaceAll(RegExp(r'[^0-9+]'), '');
                        final intent = AndroidIntent(
                          action: 'android.intent.action.SEND',
                          type: 'text/plain',
                          arguments: <String, dynamic>{
                            'android.intent.extra.TEXT': '',
                            'address': phone,
                          },
                        );
                        await intent.launch();
                      },
                    ),
                  ],
                ],
              ),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  void _showReminderMenu(BuildContext context, Reminder reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(reminder.title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.brand),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => AddReminderScreen(reminder: reminder)));
              },
            ),
            ListTile(
              leading: Icon(
                reminder.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
                color: reminder.isCompleted
                    ? AppColors.textSecondary
                    : AppColors.successText,
              ),
              title: Text(reminder.isCompleted
                  ? 'Tamamlandı İşaretini Kaldır'
                  : 'Tamamlandı Olarak İşaretle'),
              onTap: () {
                Navigator.pop(ctx);
                final rp = context.read<ReminderProvider>();
                reminder.isCompleted = !reminder.isCompleted;
                rp.update(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.dangerText),
              title: const Text('Sil', style: TextStyle(color: AppColors.dangerText)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Hatırlatıcıyı Sil'),
                    content: const Text('Bu hatırlatıcıyı silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sil',
                              style: TextStyle(color: AppColors.dangerText))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<ReminderProvider>().delete(reminder.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.grayBorder),
              const SizedBox(height: 16),
              Text('"$_searchQuery" için sonuç bulunamadı',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('Farklı bir kelime ile aramayı dene',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.grayBorder),
          SizedBox(height: 16),
          Text('Hatırlatıcı yok',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text('Sağ üstteki + ile hatırlatıcı ekleyin',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showSearchSort(BuildContext context) {
    final controller = TextEditingController(text: _searchQuery);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.grayBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Ara & Sırala',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Hatırlatıcılarda ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 20),
              const Text('Sıralama',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Öncelik', 'Tarih', 'Alfabetik'].map((s) {
                  final isSel = _sortType == s;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _sortType = s);
                      setSheetState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? AppColors.brand : AppColors.divider,
                            width: 0.5),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 13,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight:
                                  isSel ? FontWeight.w500 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grayBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Hatırlatıcılar — Nasıl Kullanılır?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
                '• Sağa kaydır: düzenle · Sola kaydır: sil\n• Basılı tut: hızlı menü (düzenle/tamamla/sil)\n• Çift dokun: düzenleme ekranını aç\n• Arama ikonu: başlıkta ve kişi adında ara, sıralama seç\n• Alttaki + butonu: hızlı görev/not/hatırlatıcı ekle',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
