import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/numpad_time_picker.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  final DateTime? initialDate;
  const AddReminderScreen({super.key, this.reminder, this.initialDate});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late TextEditingController _titleController;
  final _phoneController = TextEditingController();
  final _contactController = TextEditingController();
  final _quickMessageController = TextEditingController();
  String _type = 'Zamanlı';
  String _profileId = 'personal';
  DateTime _scheduledAt = DateTime.now();
  int _snoozeMinutes = 30;

  bool get _isContactType => _type == 'Mobil İletişim' || _type == 'Özel Gün';

  String _autoTitle() {
    final name = _contactController.text.trim();
    if (name.isEmpty) return '';
    switch (_type) {
      case 'Mobil İletişim':
        return '$name - İletişim';
      case 'Özel Gün':
        return '$name - $_specialDayType';
      default:
        return name;
    }
  }

  final _types = ['Zamanlı', 'Tekrarlayan', 'Mobil İletişim', 'Özel Gün'];
  final _snoozeMins = [15, 30, 60];
  final _repeatPeriods = ['Günlük', 'Haftalık', 'Aylık', 'Yıllık'];
  String _repeatPeriod = 'Günlük';
  String _specialDayType = 'Doğum Günü';
  bool _isRecurringYearly = false;
  final _specialDayTypes = ['Doğum Günü', 'Yıldönümü'];
  final _reminderOffsets = ['Aynı Gün', 'Bir Gün Önce', 'Bir Hafta Önce'];
  final Set<String> _selectedOffsets = {'Aynı Gün'};
  final Set<String> _selectedCommunicationTypes = {'Ara'};
  final _communicationOptions = ['Ara', 'Sohbet'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.reminder?.title ?? '',
    );
    if (widget.initialDate != null) {
      _scheduledAt = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        DateTime.now().add(const Duration(hours: 1)).hour,
        0,
      );
    }
    if (widget.reminder != null) {
      final r = widget.reminder!;
      _profileId = r.profileId;
      _scheduledAt = r.scheduledAt;
      _snoozeMinutes = r.snoozeMinutes;
      if (r.type.startsWith('Tekrarlayan')) {
        _type = 'Tekrarlayan';
        _repeatPeriod = r.type.contains(':') ? r.type.split(':')[1] : 'Günlük';
      } else {
        _type = r.type;
      }
      if (r.contactName != null) _contactController.text = r.contactName!;
      if (r.contactPhone != null) _phoneController.text = r.contactPhone!;
      if (r.quickMessage != null) _quickMessageController.text = r.quickMessage!;
      if (r.specialDayType != null) _specialDayType = r.specialDayType!;
      _isRecurringYearly = r.isRecurringYearly;

      if (r.type == 'Özel Gün') {
        // Parantez içindeki offset bilgisini temizle
        final cleanTitle = r.title
            .replaceAll(RegExp(r'\s*\(\d+ (Gün|Hafta) Sonra\)'), '')
            .trim();
        _titleController.text = cleanTitle;
      } else {
        _titleController.text = r.title;
      }

      if (r.communicationTypes.isNotEmpty) {
        _selectedCommunicationTypes.clear();
        for (final c in r.communicationTypes) {
          // Eski kayıtlarda "WhatsApp" veya "SMS" olabilir; yeni sisteme uyarla
          if (c == 'WhatsApp') {
            _selectedCommunicationTypes.add('Sohbet');
          } else if (c == 'SMS') {
            // SMS kaldırıldı, atla
            continue;
          } else {
            _selectedCommunicationTypes.add(c);
          }
        }
        if (_selectedCommunicationTypes.isEmpty) {
          _selectedCommunicationTypes.add('Ara');
        }
      }

      if (r.type == 'Özel Gün' && r.groupId != null) {
        // Aynı gruptaki tüm kayıtları bul ve seçili offsetleri yükle
        _selectedOffsets.clear();
        // Bu reminder'ın başlığından kendi offset'ini tespit et
        final allReminders = Hive.box<Reminder>('reminders')
            .values
            .where((rem) => rem.groupId == r.groupId)
            .toList();
        for (final rem in allReminders) {
          if (rem.title.contains('1 Hafta Sonra')) {
            _selectedOffsets.add('Bir Hafta Önce');
          } else if (rem.title.contains('1 Gün Sonra')) {
            _selectedOffsets.add('Bir Gün Önce');
          } else {
            _selectedOffsets.add('Aynı Gün');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    _quickMessageController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: now,
      lastDate: DateTime(now.year + 10, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: child!,
        ),
      ),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await NumpadTimePicker.show(
      context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (pickedTime == null) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _pickContact() async {
    try {
      final bool granted =
          await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Rehber izni verilmedi. Lütfen ayarlardan izin verin.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final full = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
      );
      if (mounted) {
        setState(() {
          _contactController.text = full?.displayName ?? contact.displayName;
          if (full != null && full.phones.isNotEmpty) {
            _phoneController.text = full.phones.first.number;
          }
          _titleController.text = _autoTitle();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rehber açılamadı: $e')),
        );
      }
    }
  }

  Future<void> _callNumber() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama başlatılamadı')),
      );
    }
  }

  void _save() {
    if (_type == 'Özel Gün') {
      if (widget.reminder != null) {
        // Düzenleme modunda: önce aynı gruptaki tüm kayıtları sil, sonra yenile
        final groupId = widget.reminder!.groupId;
        if (groupId != null) {
          final rp = context.read<ReminderProvider>();
          final groupReminders =
              rp.all.where((r) => r.groupId == groupId).toList();
          for (final r in groupReminders) {
            rp.delete(r.id);
          }
        }
      }
      _saveSpecialDay();
      return;
    }

    if (_titleController.text.trim().isEmpty && !_isContactType) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı başlığı boş olamaz')),
      );
      return;
    }

    final provider = context.read<ReminderProvider>();
    final title = _isContactType
        ? (_titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : _autoTitle().isNotEmpty
                ? _autoTitle()
                : 'İletişim hatırlatıcısı')
        : _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : _titleController.text.trim();
    final typeToSave = _type == 'Tekrarlayan' ? '$_type:$_repeatPeriod' : _type;
    final isYearly = _type == 'Tekrarlayan' && _repeatPeriod == 'Yıllık';

    if (widget.reminder != null) {
      final r = widget.reminder!;
      // Eğer tamamlandı işaretliyse ve yeni zaman ileriye alındıysa
      // tamamlandı işaretini kaldır
      if (r.isCompleted && _scheduledAt.isAfter(DateTime.now())) {
        r.isCompleted = false;
      }
      r.title = title;
      r.type = typeToSave;
      r.profileId = _profileId;
      r.scheduledAt = _scheduledAt;
      r.snoozeMinutes = _snoozeMinutes;
      r.contactName = _isContactType ? _contactController.text.trim() : null;
      r.contactPhone = _isContactType ? _phoneController.text.trim() : null;
      r.isRecurringYearly = isYearly;
      r.communicationTypes = _type == 'Mobil İletişim' || _type == 'Özel Gün'
          ? _selectedCommunicationTypes.toList()
          : [];
      r.quickMessage = _selectedCommunicationTypes.contains('Sohbet')
          ? _quickMessageController.text.trim()
          : null;
      provider.update(r);
    } else {
      provider.add(Reminder(
        id: '',
        title: title,
        type: typeToSave,
        scheduledAt: _scheduledAt,
        profileId: _profileId,
        createdAt: DateTime.now(),
        snoozeMinutes: _snoozeMinutes,
        contactName: _isContactType ? _contactController.text.trim() : null,
        contactPhone: _isContactType ? _phoneController.text.trim() : null,
        isRecurringYearly: isYearly,
        communicationTypes: _type == 'Mobil İletişim' || _type == 'Özel Gün'
            ? _selectedCommunicationTypes.toList()
            : [],
        quickMessage: _selectedCommunicationTypes.contains('Sohbet')
            ? _quickMessageController.text.trim()
            : null,
      ));
    }

    Navigator.pop(context);
  }

  void _saveSpecialDay() {
    if (_contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kişi seçin')),
      );
      return;
    }

    final provider = context.read<ReminderProvider>();
    final baseDate = _scheduledAt;
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _autoTitle();

    final groupId = '${DateTime.now().millisecondsSinceEpoch}';

    for (final offset in _selectedOffsets) {
      DateTime reminderDate;
      String offsetLabel;
      switch (offset) {
        case 'Bir Gün Önce':
          reminderDate =
              DateTime(baseDate.year, baseDate.month, baseDate.day - 1, 9, 0);
          offsetLabel = '1 Gün Sonra';
          break;
        case 'Bir Hafta Önce':
          reminderDate =
              DateTime(baseDate.year, baseDate.month, baseDate.day - 7, 9, 0);
          offsetLabel = '1 Hafta Sonra';
          break;
        default:
          reminderDate =
              DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
          offsetLabel = '';
      }

      provider.add(Reminder(
        id: '',
        title: offsetLabel.isEmpty ? title : '$title ($offsetLabel)',
        type: 'Özel Gün',
        scheduledAt: reminderDate,
        profileId: _profileId,
        createdAt: DateTime.now(),
        snoozeMinutes: _snoozeMinutes,
        contactName: _contactController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        isRecurringYearly: _isRecurringYearly,
        specialDayType: _specialDayType,
        groupId: groupId,
        communicationTypes: _selectedCommunicationTypes.toList(),
        quickMessage: _selectedCommunicationTypes.contains('Sohbet')
            ? _quickMessageController.text.trim()
            : null,
      ));
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedOffsets.length} hatırlatıcı oluşturuldu!'),
        backgroundColor: AppColors.brand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileProvider>().all;
    final isEdit = widget.reminder != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Hatırlatıcı Düzenle' : 'Yeni Hatırlatıcı'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Kaydet',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(children: [
              _buildLabel('Tür'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final isSelected = _type == t;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _type = t;
                      if (_isContactType &&
                          _contactController.text.isNotEmpty) {
                        _titleController.text = _autoTitle();
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.brand : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(t,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList(),
              ),
              if (_type == 'Tekrarlayan') ...[
                const SizedBox(height: 12),
                _buildLabel('Tekrar Sıklığı'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _repeatPeriods.map((p) {
                    final isSelected = _repeatPeriod == p;
                    return GestureDetector(
                      onTap: () => setState(() => _repeatPeriod = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.brand : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.divider,
                            width: 0.5,
                          ),
                        ),
                        child: Text(p,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            if (_isContactType) ...[
              _buildCard(children: [
                GestureDetector(
                  onTap: _pickContact,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brandBorder),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts_outlined,
                            size: 18, color: AppColors.brand),
                        SizedBox(width: 8),
                        Text('Rehberden Seç',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.brand,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                if (_type == 'Mobil İletişim') ...[
                  const SizedBox(height: 12),
                  _buildLabel('İletişim Türleri (birden fazla seçilebilir)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _communicationOptions.map((o) {
                      final isSel = _selectedCommunicationTypes.contains(o);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSel && _selectedCommunicationTypes.length > 1) {
                            _selectedCommunicationTypes.remove(o);
                          } else {
                            _selectedCommunicationTypes.add(o);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.brand : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSel ? AppColors.brand : AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Text(o,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight:
                                    isSel ? FontWeight.w500 : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedCommunicationTypes.contains('Sohbet')) ...[
                    const SizedBox(height: 12),
                    _buildLabel('Hazır Mesaj (opsiyonel)'),
                    const SizedBox(height: 4),
                    const Text(
                      'Bildirim geldiğinde Gönder butonuna basınca bu mesaj kullanılır. Sık tekrarlayan hatırlatıcılarda güncellemeyi unutma.',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _quickMessageController,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Örn: İyi ki doğdun, nice mutlu yıllara!',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ],
                ],
                if (_type == 'Özel Gün') ...[
                  const SizedBox(height: 12),
                  _buildLabel('İletişim Türleri (birden fazla seçilebilir)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _communicationOptions.map((o) {
                      final isSel = _selectedCommunicationTypes.contains(o);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSel && _selectedCommunicationTypes.length > 1) {
                            _selectedCommunicationTypes.remove(o);
                          } else {
                            _selectedCommunicationTypes.add(o);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.brand : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSel ? AppColors.brand : AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Text(o,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight:
                                    isSel ? FontWeight.w500 : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedCommunicationTypes.contains('Sohbet')) ...[
                    const SizedBox(height: 12),
                    _buildLabel('Hazır Mesaj (opsiyonel)'),
                    const SizedBox(height: 4),
                    const Text(
                      'Bildirim geldiğinde Gönder butonuna basınca bu mesaj kullanılır. Sık tekrarlayan hatırlatıcılarda güncellemeyi unutma.',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _quickMessageController,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Örn: İyi ki doğdun, nice mutlu yıllara!',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildLabel('Özel Gün Türü'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _specialDayTypes.map((t) {
                      final isSel = _specialDayType == t;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _specialDayType = t;
                          if (_contactController.text.isNotEmpty) {
                            _titleController.text = _autoTitle();
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.brand : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSel ? AppColors.brand : AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight:
                                    isSel ? FontWeight.w500 : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _buildLabel('Hatırlatma Zamanı (birden fazla seçilebilir)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reminderOffsets.map((o) {
                      final isSel = _selectedOffsets.contains(o);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSel && _selectedOffsets.length > 1) {
                            _selectedOffsets.remove(o);
                          } else {
                            _selectedOffsets.add(o);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.warnBg : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.warnText
                                  : AppColors.divider,
                              width: isSel ? 1.5 : 0.5,
                            ),
                          ),
                          child: Text(o,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSel
                                    ? AppColors.warnText
                                    : AppColors.textSecondary,
                                fontWeight:
                                    isSel ? FontWeight.w500 : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Her Yıl Tekrarlasın mı?'),
                            const SizedBox(height: 2),
                            Text(
                              _isRecurringYearly
                                  ? 'Her yıl otomatik hatırlatılacak'
                                  : 'Sadece bu yıl hatırlatılacak',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRecurringYearly,
                        onChanged: (v) =>
                            setState(() => _isRecurringYearly = v),
                        activeThumbColor: AppColors.brand,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildLabel('Hatırlatıcı Başlığı'),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Otomatik oluşturulur, değiştirebilirsiniz',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLabel('Kişi Adı'),
                TextField(
                  controller: _contactController,
                  decoration: const InputDecoration(hintText: 'Ad Soyad'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildLabel('Telefon Numarası'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                            hintText: '+90 5xx xxx xx xx'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _callNumber,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.brandBorder),
                        ),
                        child: const Icon(Icons.call,
                            size: 20, color: AppColors.brand),
                      ),
                    ),
                  ],
                ),
              ]),
            ] else ...[
              _buildCard(children: [
                _buildLabel('Başlık'),
                TextField(
                  controller: _titleController,
                  decoration:
                      const InputDecoration(hintText: 'Hatırlatıcı başlığı...'),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: !isEdit,
                ),
              ]),
            ],
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Tarih & Saat'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.brandBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.brandMid),
                      const SizedBox(width: 10),
                      Text(
                        '${_scheduledAt.day.toString().padLeft(2, '0')}.${_scheduledAt.month.toString().padLeft(2, '0')}.${_scheduledAt.year}  ${_scheduledAt.hour.toString().padLeft(2, '0')}:${_scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.brandMid,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Erteleme Süresi'),
              const SizedBox(height: 8),
              Row(
                children: _snoozeMins.map((m) {
                  final isSelected = _snoozeMinutes == m;
                  return GestureDetector(
                    onTap: () => setState(() => _snoozeMinutes = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.brand : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text('$m dk',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Profil'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: profiles.map((p) {
                    final isSelected = _profileId == p.id;
                    return GestureDetector(
                      onTap: () => setState(() => _profileId = p.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.brand : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.divider,
                            width: 0.5,
                          ),
                        ),
                        child: Text(p.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child:
                    Text(isEdit ? 'Değişiklikleri Kaydet' : 'Hatırlatıcı Ekle'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: .05,
        ));
  }
}
