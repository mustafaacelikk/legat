import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/calendar_intent_service.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  final String? initialFilter;
  const TasksScreen({super.key, this.initialFilter});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late String _filter = widget.initialFilter ?? 'Tümü';
  final _filters = [
    'Tümü',
    'Devam Ediyor',
    'Planlı',
    'Beklemede',
    'Geciken',
    'Tamamlandı'
  ];
  String _searchQuery = '';
  String _sortType = 'Öncelik'; // 'Tarih' | 'Öncelik' | 'Alfabetik'

  List<Task> _applyFilter(List<Task> tasks) {
    if (_filter == 'Tümü') return tasks;
    if (_filter == 'Geciken') {
      return tasks
          .where((t) =>
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()) &&
              t.status != 'Tamamlandı')
          .toList();
    }
    return tasks.where((t) => t.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final activeId = profileProvider.activeProfileId;

    List<Task> tasks = _applyFilter(taskProvider.byProfile(activeId));

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q))
          .toList();
    }

    if (_sortType == 'Alfabetik') {
      tasks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortType == 'Tarih') {
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      const order = ['Kritik', 'Yüksek', 'Orta', 'Düşük'];
      tasks.sort((a, b) =>
          order.indexOf(a.priority).compareTo(order.indexOf(b.priority)));
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 14, color: AppColors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('"$_searchQuery" için sonuçlar',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.brand,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _searchQuery = ''),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.brand),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmpty()
                  : _buildList(tasks, reminderProvider),
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
              const Text('Görevler',
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
                  child: const Icon(Icons.manage_search,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelp(context),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child:
                      Icon(Icons.info_outline, color: Colors.white, size: 28),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _filters.map((f) {
          final isSelected = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brand : AppColors.divider,
                  width: 0.5,
                ),
              ),
              child: Text(f,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(List<Task> tasks, ReminderProvider reminderProvider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, task, reminderProvider);
      },
    );
  }

  Widget _buildTaskItem(
      BuildContext context, Task task, ReminderProvider reminderProvider) {
    Color priorityBg;
    Color priorityText;
    switch (task.priority) {
      case 'Kritik':
        priorityBg = AppColors.dangerBg;
        priorityText = AppColors.dangerText;
        break;
      case 'Yüksek':
        priorityBg = AppColors.warnBg;
        priorityText = AppColors.warnText;
        break;
      case 'Orta':
        priorityBg = AppColors.brandLight;
        priorityText = AppColors.brandMid;
        break;
      default:
        priorityBg = AppColors.successBg;
        priorityText = AppColors.successText;
    }

    final isDone = task.status == 'Tamamlandı';
    final hasReminder = reminderProvider.all.any((r) => r.taskId == task.id);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.dangerText,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)));
          return false;
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Görevi Sil'),
              content:
                  const Text('Bu görevi silmek istediğinize emin misiniz?'),
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
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final reminderProvider = context.read<ReminderProvider>();
          await reminderProvider.deleteByTaskId(task.id);
          if (!context.mounted) return;
          context.read<TaskProvider>().delete(task.id);
        }
      },
      child: GestureDetector(
        onLongPress: () => _showTaskMenu(context, task),
        onDoubleTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFE0F2F1) : const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF00695C).withValues(alpha: 0.3)
                  : const Color(0xFF1F3864).withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: GestureDetector(
              onTap: () async {
                final tp = context.read<TaskProvider>();
                final reminderProvider = context.read<ReminderProvider>();
                final newStatus = isDone ? 'Planlı' : 'Tamamlandı';
                task.status = newStatus;
                tp.update(task);
                await reminderProvider.setCompletedForTask(
                    task.id, newStatus == 'Tamamlandı');
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.successBg : priorityBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDone ? Icons.check_circle : Icons.check_circle_outline,
                  color: isDone ? AppColors.successText : priorityText,
                  size: 18,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (hasReminder) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.notifications_active,
                      size: 14, color: AppColors.warnText),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                task.dueDate != null
                    ? Text(
                        'Bitiş: ${task.dueDate!.day.toString().padLeft(2, '0')}.${task.dueDate!.month.toString().padLeft(2, '0')}.${task.dueDate!.year}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      )
                    : const Text('Sürekli Görev',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.brand,
                            fontWeight: FontWeight.w500)),
                if (task.dueDate != null && !isDone) ...[
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final now = DateTime.now();
                    final diff = task.dueDate!.difference(now).inDays;
                    String countdownText;
                    Color countdownColor;
                    if (diff < 0) {
                      countdownText = '${diff.abs()} gün geçti';
                      countdownColor = const Color(0xFFB71C1C);
                    } else if (diff == 0) {
                      countdownText = 'Bugün!';
                      countdownColor = const Color(0xFFE65100);
                    } else if (diff == 1) {
                      countdownText = 'Yarın';
                      countdownColor = const Color(0xFFE65100);
                    } else {
                      countdownText = '$diff gün sonra';
                      countdownColor = AppColors.textSecondary;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: countdownColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: countdownColor.withValues(alpha: 0.3)),
                      ),
                      child: Text('⏱ $countdownText',
                          style: TextStyle(
                              fontSize: 9,
                              color: countdownColor,
                              fontWeight: FontWeight.w500)),
                    );
                  }),
                ],
                if (task.completionPercent > 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.completionPercent / 100,
                    backgroundColor: const Color(0xFFBBCEFA),
                    color: const Color(0xFF1F3864),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(task.priority,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: priorityText)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.successBg : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Text(
                    isDone ? 'Tamamlandı' : task.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? AppColors.successText
                            : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskMenu(BuildContext context, Task task) {
    final isDone = task.status == 'Tamamlandı';
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(task.title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.brand),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddTaskScreen(task: task)));
              },
            ),
            if (task.dueDate != null)
              ListTile(
                leading:
                    const Icon(Icons.event_outlined, color: AppColors.brand),
                title: const Text('Takvime Ekle'),
                onTap: () {
                  Navigator.pop(ctx);
                  CalendarIntentService.addEvent(
                    title: task.title,
                    description: task.description,
                    start: task.dueDate!,
                    allDay: true,
                  );
                },
              ),
            ListTile(
              leading: Icon(
                isDone
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
                color: isDone ? AppColors.textSecondary : AppColors.successText,
              ),
              title: Text(isDone
                  ? 'Tamamlandı İşaretini Kaldır'
                  : 'Tamamlandı Olarak İşaretle'),
              onTap: () async {
                Navigator.pop(ctx);
                final tp = context.read<TaskProvider>();
                final reminderProvider = context.read<ReminderProvider>();
                final newStatus = isDone ? 'Planlı' : 'Tamamlandı';
                task.status = newStatus;
                tp.update(task);
                await reminderProvider.setCompletedForTask(
                    task.id, newStatus == 'Tamamlandı');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.dangerText),
              title: const Text('Sil',
                  style: TextStyle(color: AppColors.dangerText)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Görevi Sil'),
                    content: const Text(
                        'Bu görevi silmek istediğinize emin misiniz?'),
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
                  final reminderProvider = context.read<ReminderProvider>();
                  await reminderProvider.deleteByTaskId(task.id);
                  if (!context.mounted) return;
                  context.read<TaskProvider>().delete(task.id);
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
              const Icon(Icons.search_off,
                  size: 64, color: AppColors.grayBorder),
              const SizedBox(height: 16),
              Text('"$_searchQuery" için sonuç bulunamadı',
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('Farklı bir kelime ile aramayı dene',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: AppColors.grayBorder),
          SizedBox(height: 16),
          Text('Görev yok',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text('Sağ üstteki + ile görev ekleyin',
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
                  hintText: 'Görevlerde ara...',
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
            const Text('Görevler — Nasıl Kullanılır?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
                '• Sağa kaydır: düzenle · Sola kaydır: sil\n• Basılı tut: hızlı menü (düzenle/tamamla/sil/Takvime Ekle)\n• Çift dokun: düzenleme ekranını aç\n• Arama ikonu: başlık ve açıklamada ara, sıralama seç\n• Alttaki + butonu: hızlı görev/not/hatırlatıcı ekle',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
