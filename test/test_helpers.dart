import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herseyim/providers/task_provider.dart';
import 'package:herseyim/providers/note_provider.dart';
import 'package:herseyim/providers/reminder_provider.dart';
import 'package:herseyim/providers/profile_provider.dart';
import 'package:herseyim/providers/settings_provider.dart';

class TestProviders {
  final TaskProvider taskProvider;
  final NoteProvider noteProvider;
  final ReminderProvider reminderProvider;
  final ProfileProvider profileProvider;
  final SettingsProvider settingsProvider;
  final Directory _tempDir;

  TestProviders({
    required this.taskProvider,
    required this.noteProvider,
    required this.reminderProvider,
    required this.profileProvider,
    required this.settingsProvider,
    required Directory tempDir,
  }) : _tempDir = tempDir;

  Future<void> dispose() async {
    await Hive.close();
    if (await _tempDir.exists()) {
      await _tempDir.delete(recursive: true);
    }
  }
}

/// Widget testleri için gerçek telefon/dosya sistemine ihtiyaç duymadan
/// tüm provider'ları ve Hive kutularını geçici bir klasörde hazırlar.
Future<TestProviders> setupTestProviders() async {
  final tempDir = await Directory.systemTemp.createTemp('legat_test_');

  Hive.init(tempDir.path);

  SharedPreferences.setMockInitialValues({});

  final taskProvider = TaskProvider();
  final noteProvider = NoteProvider();
  final reminderProvider = ReminderProvider();
  final profileProvider = ProfileProvider();
  final settingsProvider = SettingsProvider();

  await taskProvider.init();
  await noteProvider.init();
  await reminderProvider.init();
  await profileProvider.init();
  await settingsProvider.init();

  return TestProviders(
    taskProvider: taskProvider,
    noteProvider: noteProvider,
    reminderProvider: reminderProvider,
    profileProvider: profileProvider,
    settingsProvider: settingsProvider,
    tempDir: tempDir,
  );
}
