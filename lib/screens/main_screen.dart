import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'briefing/briefing_screen.dart';
import 'tasks/tasks_screen.dart';
import 'tasks/add_task_screen.dart';
import 'calendar/calendar_screen.dart';
import 'notes/notes_screen.dart';
import 'notes/add_note_screen.dart';
import 'reminders/reminders_screen.dart';
import 'reminders/add_reminder_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Offset? _fabDragOffset;

  /// Profil sekmesine git (briefing header'daki avatar butonu)
  void goToProfile() {
    setState(() => _currentIndex = 5);
  }

  /// Herhangi bir sekmeye git (0=Bugün,1=Görevler,2=Takvim,3=Notlar,4=Hatırlatıcı,5=Profil)
  void goToTab(int index, {String? filter}) {
    if (filter != null && index == 1) {
      setState(() {
        _currentIndex = index;
        _screens[1] = TasksScreen(initialFilter: filter);
      });
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void goToReminder(String reminderId) {
    setState(() => _currentIndex = 4);
  }

  Future<void> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Uygulamadan çıkmak istiyor musunuz?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış'),
          ),
        ],
      ),
    );
    if (shouldExit == true) SystemNavigator.pop();
  }

  final List<Widget> _screens = [
    const BriefingScreen(),
    const TasksScreen(),
    const CalendarScreen(),
    const NotesScreen(),
    const RemindersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            _buildDraggableFab(context),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _navItem(0, Icons.wb_sunny_outlined, Icons.wb_sunny, 'Bugün'),
            _navItem(
                1, Icons.check_circle_outline, Icons.check_circle, 'Görevler'),
            _navItem(2, Icons.calendar_month_outlined, Icons.calendar_month,
                'Takvim'),
            _navItem(3, Icons.notes_outlined, Icons.notes, 'Notlar'),
            _navItem(4, Icons.notifications_outlined, Icons.notifications,
                'Hatırlatıcı'),
            _navItem(5, Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableFab(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    const fabSize = 48.0;
    const margin = 16.0;

    final minY = safeTop + margin;
    final maxY = screenSize.height - fabSize - margin - 80;
    const minX = margin;
    final maxX = screenSize.width - fabSize - margin;
    final centerX = (screenSize.width - fabSize) / 2;

    // Ortadaki "orijinal tasarım" bölgesi: ekranın yatay ortasına yakın bir şerit
    final centerZoneMin = screenSize.width / 2 - 70;
    final centerZoneMax = screenSize.width / 2 + 70;

    double currentLeft;
    double currentTop;

    if (_fabDragOffset != null) {
      currentLeft = _fabDragOffset!.dx.clamp(minX, maxX);
      currentTop = _fabDragOffset!.dy.clamp(minY, maxY);
    } else if (settings.fabHPosition == 'center') {
      currentLeft = centerX;
      currentTop = maxY; // Orijinal tasarımdaki gibi alt barın hemen üzerinde, sabit
    } else {
      currentTop = (settings.fabDyFraction * screenSize.height).clamp(minY, maxY);
      currentLeft = settings.fabHPosition == 'left' ? minX : maxX;
    }

    final isDragging = _fabDragOffset != null;

    return AnimatedPositioned(
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      top: currentTop,
      left: currentLeft,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _fabDragOffset = Offset(currentLeft, currentTop);
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _fabDragOffset = Offset(
              (_fabDragOffset!.dx + details.delta.dx).clamp(minX, maxX),
              (_fabDragOffset!.dy + details.delta.dy).clamp(minY, maxY),
            );
          });
        },
        onPanEnd: (details) {
          final droppedCenterX = _fabDragOffset!.dx + fabSize / 2;
          final droppedTop = _fabDragOffset!.dy;
          setState(() {
            _fabDragOffset = null;
          });

          if (droppedCenterX >= centerZoneMin && droppedCenterX <= centerZoneMax) {
            settings.setFabPosition(settings.fabDyFraction, 'center');
          } else {
            final hPos = droppedCenterX < screenSize.width / 2 ? 'left' : 'right';
            settings.setFabPosition(droppedTop / screenSize.height, hPos);
          }
        },
        child: FloatingActionButton.small(
          onPressed: () => _showQuickAdd(context),
          backgroundColor: AppColors.brandMid,
          elevation: 2,
          child: const Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onLongPress: () => _showQuickAdd(context),
        child: Icon(icon),
      ),
      activeIcon: GestureDetector(
        onLongPress: () => _showQuickAdd(context),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            const Text('Hızlı Ekle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                _quickAddItem(
                  context,
                  Icons.check_circle_outline,
                  'Görev',
                  AppColors.brandLight,
                  AppColors.brandMid,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddTaskScreen()));
                  },
                ),
                const SizedBox(width: 12),
                _quickAddItem(
                  context,
                  Icons.notifications_outlined,
                  'Hatırlatıcı',
                  AppColors.warnBg,
                  AppColors.warnText,
                  () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddReminderScreen()));
                  },
                ),
                const SizedBox(width: 12),
                _quickAddItem(
                  context,
                  Icons.notes,
                  'Not',
                  AppColors.successBg,
                  AppColors.successText,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddNoteScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _quickAddItem(BuildContext context, IconData icon, String label,
      Color bg, Color fg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
