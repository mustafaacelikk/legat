import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class WhatsappHelper {
  /// Önce wa.me linkiyle WhatsApp'ı doğrudan o kişinin sohbet ekranında
  /// açmayı dener (kişi seçme adımını atlar). Başarısız olursa (WhatsApp
  /// kurulu değil, link açılamıyor vb.) genel ACTION_SEND seçiciye
  /// (kişi seçmeli, ama her mesajlaşma uygulamasıyla uyumlu) geri düşer.
  static Future<void> sendMessage({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    try {
      final waUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );
      final launched = await launchUrl(
        waUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (launched) return;
    } catch (_) {
      // wa.me başarısız oldu, aşağıdaki genel yönteme düş
    }

    final intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      type: 'text/plain',
      arguments: <String, dynamic>{
        'android.intent.extra.TEXT': message,
        'address': cleanPhone,
      },
    );
    await intent.launch();
  }
}
