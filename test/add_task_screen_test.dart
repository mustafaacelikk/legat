import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herseyim/screens/tasks/add_task_screen.dart';
import 'package:herseyim/models/profile_model.dart';
import 'test_helpers.dart';

void main() {
  testWidgets(
      'Görev ekle ekranı çok sayıda profille yatayda kaydırılabilir kalır (dikeyde büyümez)',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    late TestProviders providers;

    await tester.runAsync(() async {
      providers = await setupTestProviders();
      // Taşmayı tetiklemek için bolca sahte profil ekle
      for (int i = 1; i <= 10; i++) {
        await providers.profileProvider.add(Profile(
          id: '',
          name: 'Test Profil $i',
          type: 'custom',
          colorValue: 0xFF1F3864,
          createdAt: DateTime.now(),
        ));
      }
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: providers.taskProvider),
          ChangeNotifierProvider.value(value: providers.noteProvider),
          ChangeNotifierProvider.value(value: providers.reminderProvider),
          ChangeNotifierProvider.value(value: providers.profileProvider),
          ChangeNotifierProvider.value(value: providers.settingsProvider),
        ],
        child: const MaterialApp(home: AddTaskScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Hiçbir render/overflow hatası fırlatılmadıysa test geçer
    expect(tester.takeException(), isNull);

    final scrollView =
        tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first);
    expect(scrollView.scrollDirection, Axis.horizontal);

    await tester.runAsync(() async {
      await providers.dispose();
    });
  });
}
