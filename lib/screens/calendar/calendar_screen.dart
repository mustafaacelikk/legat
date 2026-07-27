import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/task_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _profileFilter = 'all';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks
        .where((task) {
          if (task.dueDate == null) return false;
          final due = task.dueDate!;
          return due.year == day.year &&
              due.month == day.month &&
              due.day == day.day;
        })
        .where((t) => t.status != 'Tamamlandı')
        .toList();
  }

  List<Reminder> _getRemindersForDay(
      DateTime day, List<Reminder> allReminders) {
    return allReminders
        .where((r) {
          final s = r.scheduledAt;
          return s.year == day.year && s.month == day.month && s.day == day.day;
        })
        .where((r) => !r.isCompleted)
        .toList();
  }

  List<Task> _filterTasks(List<Task> tasks, String filter) {
    if (filter == 'all') return tasks;
    return tasks.where((t) => t.profileId == filter).toList();
  }

  List<Reminder> _filterReminders(List<Reminder> reminders, String filter) {
    if (filter == 'all') return reminders;
    return reminders.where((r) => r.profileId == filter).toList();
  }

  List<Object> _getEventsForDay(
      DateTime day, List<Task> tasks, List<Reminder> reminders) {
    final List<Object> events = [];
    events.addAll(_getTasksForDay(day, _filterTasks(tasks, _profileFilter)));
    events.addAll(
        _getRemindersForDay(day, _filterReminders(reminders, _profileFilter)));
    return events;
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
            const Text('Takvim — Nasıl Kullanılır?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
                '• Bir güne dokunarak o günün detaylarını gör\n• Ay/Hafta/2 Hafta görünümleri arasında geçiş yapabilirsin\n• Etkinlik işaretçileri o günde görev veya hatırlatıcı olduğunu gösterir\n• Yeni görev/hatırlatıcı eklemek için alttaki + (hızlı ekle) butonunu kullan\n• Profil sekmeleri ile takvimi belirli bir profile göre filtreleyebilirsin',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final allTasks = taskProvider.all;
    final allReminders = reminderProvider.all;

    final filteredTasks = _filterTasks(allTasks, _profileFilter);
    final filteredReminders = _filterReminders(allReminders, _profileFilter);

    final selectedTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!, filteredTasks)
        : <Task>[];
    final selectedReminders = _selectedDay != null
        ? _getRemindersForDay(_selectedDay!, filteredReminders)
        : <Reminder>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, profileProvider),
            _buildCalendar(allTasks, allReminders),
            _buildSelectedDayHeader(),
            Expanded(
              child: _buildDayItems(
                  selectedTasks, selectedReminders, profileProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileProvider pp) {
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
              const Text('Takvim',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
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
                _profileTabCalendar('Tümü', 'all'),
                ...orderedProfiles.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _profileTabCalendar(p.name, p.id),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTabCalendar(String label, String id) {
    final isActive = _profileFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _profileFilter = id),
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

  Widget _buildCalendar(List<Task> allTasks, List<Reminder> allReminders) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _getEventsForDay(day, allTasks, allReminders),
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'tr_TR',
        availableCalendarFormats: const {
          CalendarFormat.month: 'Ay',
          CalendarFormat.twoWeeks: '2 Hafta',
          CalendarFormat.week: 'Hafta',
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 5,
          markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
          weekendTextStyle: const TextStyle(color: AppColors.dangerText),
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          disabledTextStyle:
              TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
          cellMargin: const EdgeInsets.all(4),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.brandBorder),
          ),
          formatButtonTextStyle: const TextStyle(
            color: AppColors.brand,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon:
              const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          headerPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            color: AppColors.dangerText.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayHeader() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final dateStr =
        DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(_selectedDay!);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 14, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isToday ? 'Bugün · $dateStr' : dateStr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItems(List<Task> tasks, List<Reminder> reminders,
      ProfileProvider profileProvider) {
    if (tasks.isEmpty && reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined,
                size: 48, color: AppColors.grayBorder.withValues(alpha: 0.8)),
            const SizedBox(height: 12),
            const Text('Bu gün için etkinlik yok',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Sağ üstteki + ile görev veya hatırlatıcı ekleyin',
                style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 12)),
          ],
        ),
      );
    }

    final List<_CalendarItem> items = [
      ...tasks
          .map((t) => _CalendarItem(type: 'task', task: t, time: t.dueDate)),
      ...reminders.map((r) =>
          _CalendarItem(type: 'reminder', reminder: r, time: r.scheduledAt)),
    ]..sort((a, b) {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        return a.time!.compareTo(b.time!);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.type == 'task') {
          return _buildTaskCard(item.task!, profileProvider);
        } else {
          return _buildReminderCard(item.reminder!, profileProvider);
        }
      },
    );
  }

  Widget _buildTaskCard(Task task, ProfileProvider profileProvider) {
    final profile =
        profileProvider.all.where((p) => p.id == task.profileId).firstOrNull;

    Color priorityBg;
    Color priorityText;
    Color priorityBorder;
    IconData priorityIcon;

    switch (task.priority) {
      case 'Kritik':
      case 'high':
        priorityBg = AppColors.dangerBg;
        priorityText = AppColors.dangerText;
        priorityBorder = AppColors.dangerBorder;
        priorityIcon = Icons.keyboard_double_arrow_up;
        break;
      case 'Yüksek':
      case 'medium':
        priorityBg = AppColors.warnBg;
        priorityText = AppColors.warnText;
        priorityBorder = AppColors.warnBorder;
        priorityIcon = Icons.drag_handle;
        break;
      default:
        priorityBg = AppColors.successBg;
        priorityText = AppColors.successText;
        priorityBorder = AppColors.successBorder;
        priorityIcon = Icons.keyboard_double_arrow_down;
    }

    final isDone = task.status == 'Tamamlandı' || task.status == 'completed';
    final timeStr =
        task.dueDate != null ? DateFormat('HH:mm').format(task.dueDate!) : null;

    return GestureDetector(
      onTap: () {
        final mainState = context.findAncestorStateOfType<MainScreenState>();
        mainState?.goToTab(1); // Görevler sekmesi
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? AppColors.grayBorder : priorityBorder,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDone ? AppColors.grayBg : priorityBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: isDone ? AppColors.grayText : priorityText,
              size: 18,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Row(
            children: [
              if (timeStr != null) ...[
                const Icon(Icons.access_time,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(timeStr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
              ],
              Icon(priorityIcon, size: 11, color: priorityText),
              const SizedBox(width: 3),
              Text(task.priority,
                  style: TextStyle(fontSize: 11, color: priorityText)),
            ],
          ),
          trailing: profile != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.brandBorder),
                  ),
                  child: Text(profile.name,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w500)),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildReminderCard(
      Reminder reminder, ProfileProvider profileProvider) {
    final profile = profileProvider.all
        .where((p) => p.id == reminder.profileId)
        .firstOrNull;
    final timeStr = DateFormat('HH:mm').format(reminder.scheduledAt);
    final isCompleted = reminder.isCompleted;

    return GestureDetector(
      onTap: () {
        final mainState = context.findAncestorStateOfType<MainScreenState>();
        mainState?.goToTab(4);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? AppColors.grayBorder : AppColors.warnBorder,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.grayBg : AppColors.warnBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  reminder.type == 'Arama'
                      ? Icons.phone_outlined
                      : reminder.type == 'SMS'
                          ? Icons.sms_outlined
                          : reminder.type == 'Sohbet'
                              ? Icons.forum_outlined
                              : Icons.notifications_outlined,
                  color: isCompleted ? AppColors.grayText : AppColors.warnText,
                  size: 18,
                ),
              ),
              title: Text(
                reminder.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  if (reminder.contactName != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.person_outline,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(reminder.contactName!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ],
              ),
              trailing: profile != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warnBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warnBorder),
                      ),
                      child: Text(profile.name,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.warnText,
                              fontWeight: FontWeight.w500)),
                    )
                  : null,
            ),
            if (!reminder.isCompleted &&
                reminder.contactPhone != null &&
                reminder.contactPhone!.isNotEmpty) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (reminder.type == 'Arama' ||
                        reminder.communicationTypes.contains('Ara'))
                      _calendarActionButton(
                        icon: Icons.phone,
                        label: 'Ara',
                        onTap: () async {
                          final uri =
                              Uri(scheme: 'tel', path: reminder.contactPhone);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    if (reminder.type == 'SMS' ||
                        reminder.communicationTypes.contains('SMS')) ...[
                      const SizedBox(width: 8),
                      _calendarActionButton(
                        icon: Icons.sms,
                        label: 'SMS',
                        onTap: () async {
                          final uri =
                              Uri(scheme: 'sms', path: reminder.contactPhone);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                    if (reminder.type == 'Sohbet' ||
                        reminder.communicationTypes.contains('WhatsApp')) ...[
                      const SizedBox(width: 8),
                      _calendarActionButton(
                        icon: Icons.chat,
                        label: 'Sohbet',
                        onTap: () async {
                          final phone = reminder.contactPhone!
                              .replaceAll(RegExp(r'[^0-9+]'), '');
                          final intent = AndroidIntent(
                            action: 'android.intent.action.SEND',
                            type: 'text/plain',
                            arguments: <String, dynamic>{
                              'android.intent.extra.TEXT': 'Merhaba',
                              'address': phone,
                            },
                          );
                          await intent.launch();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _calendarActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CalendarItem {
  final String type;
  final Task? task;
  final Reminder? reminder;
  final DateTime? time;

  _CalendarItem({required this.type, this.task, this.reminder, this.time});
}
