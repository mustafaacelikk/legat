import 'package:flutter_test/flutter_test.dart';
import 'package:herseyim/models/reminder_model.dart';

void main() {
  group('Görev bağlantılı hatırlatıcı — snoozeMinutes', () {
    test('kullanıcının seçtiği erteleme süresi kaybolmadan saklanmalı', () {
      final reminder = Reminder(
        id: 't1',
        title: 'Test görevi için hatırlatıcı',
        type: 'Zamanlı',
        scheduledAt: DateTime.now(),
        profileId: 'personal',
        createdAt: DateTime.now(),
        snoozeMinutes: 15,
        taskId: 'task-1',
      );

      expect(reminder.snoozeMinutes, 15,
          reason: 'Görev içinden oluşturulan hatırlatıcı, sabit 30 yerine kullanıcının seçtiği değeri korumalı');
    });

    test('varsayılan değer sadece hiç belirtilmediğinde 30 olmalı', () {
      final reminder = Reminder(
        id: 't2',
        title: 'Varsayılan test',
        type: 'Zamanlı',
        scheduledAt: DateTime.now(),
        profileId: 'personal',
        createdAt: DateTime.now(),
      );

      expect(reminder.snoozeMinutes, 30);
    });
  });
}
