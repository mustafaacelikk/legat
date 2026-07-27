import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/note_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  await Hive.initFlutter();
  await initializeDateFormatting('tr_TR', null);
  await NotificationService.instance.init();
  NotificationService.onReminderNotificationTap = (reminderId) {
    if (reminderId != null) {
      mainScreenKey.currentState?.goToReminder(reminderId);
    } else {
      mainScreenKey.currentState?.goToTab(4);
    }
  };

  final taskProvider = TaskProvider();
  final noteProvider = NoteProvider();
  final reminderProvider = ReminderProvider();
  final profileProvider = ProfileProvider();
  final settingsProvider = SettingsProvider();

  await Future.wait([
    taskProvider.init(),
    noteProvider.init(),
    reminderProvider.init(),
    profileProvider.init(),
  ]);
  await settingsProvider.init();

  final existingTaskIds = taskProvider.all.map((t) => t.id).toSet();
  await reminderProvider.cleanupOrphaned(existingTaskIds);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: taskProvider),
        ChangeNotifierProvider.value(value: noteProvider),
        ChangeNotifierProvider.value(value: reminderProvider),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const HerSeyimApp(),
    ),
  );
}

class HerSeyimApp extends StatelessWidget {
  const HerSeyimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: 'Her Şeyim',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('tr', 'TR'),
        home: MainScreen(key: mainScreenKey),
        builder: (context, child) {
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          );
        },
      ),
    );
  }
}