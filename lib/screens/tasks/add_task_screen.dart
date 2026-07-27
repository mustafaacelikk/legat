import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/numpad_time_picker.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialDueDate;
  const AddTaskScreen({super.key, this.task, this.initialDueDate});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Orta';
  String _profileId = 'personal';
  DateTime? _dueDate;
  DateTime? _startDate;
  int _completion = 0;
  String _status = 'Planlı';
  Reminder? _existingReminder;

  bool _reminderEnabled = false;
  bool _isContinuous = false;
  DateTime _reminderDateTime = DateTime.now().add(const Duration(hours: 1));
  final _reminderTypes = ['Zamanlı', 'Tekrarlayan'];
  String _reminderType = 'Zamanlı';
  final _repeatPeriods = ['Günlük', 'Haftalık', 'Aylık', 'Yıllık'];
  String _repeatPeriod = 'Günlük';

  final _priorities = ['Kritik', 'Yüksek', 'Orta', 'Düşük'];
  final _statuses = ['Devam Ediyor', 'Planlı', 'Beklemede', 'Tamamlandı'];

  @override
  void initState() {
    super.initState();
    if (widget.initialDueDate != null) {
      _dueDate = widget.initialDueDate;
    }
    if (widget.task != null) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descController.text = t.description;
      _priority = t.priority;
      _profileId = t.profileId;
      _dueDate = t.dueDate;
      _completion = t.completionPercent;
      _status = t.status == 'Backlog' ? 'Yapılacak' : t.status;
      _isContinuous = t.dueDate == null;
      _startDate = t.startDate;

      final reminderProvider = context.read<ReminderProvider>();
      final linkedReminders =
          reminderProvider.all.where((r) => r.taskId == t.id).toList();
      if (linkedReminders.isNotEmpty) {
        _existingReminder = linkedReminders.first;
        _reminderEnabled = true;
        _reminderDateTime = _existingReminder!.scheduledAt;
        if (_existingReminder!.type.startsWith('Tekrarlayan:')) {
          _reminderType = 'Tekrarlayan';
          _repeatPeriod = _existingReminder!.type.split(':')[1];
        } else {
          _reminderType = _existingReminder!.type;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 10, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.zero,
            ),
            child: child!,
          ),
        );
      },
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _dueDate = picked);
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _pickStartDate() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: _dueDate ?? DateTime(now.year + 10, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.zero,
            ),
            child: child!,
          ),
        );
      },
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _startDate = picked);
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _pickReminderDateTime() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime,
      firstDate: now,
      lastDate: DateTime(now.year + 10, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await NumpadTimePicker.show(
      context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime),
    );
    if (pickedTime == null) return;
    setState(() {
      _reminderDateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute,
      );
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev başlığı boş olamaz')),
      );
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final reminderProvider = context.read<ReminderProvider>();

    final status = _status == 'Yapılacak' ? 'Backlog' : _status;

    if (widget.task != null) {
      final t = widget.task!;
      t.title = _titleController.text.trim();
      t.description = _descController.text.trim();
      t.priority = _priority;
      t.profileId = _profileId;
      t.dueDate = _dueDate;
      t.startDate = _startDate;
      t.completionPercent = _completion;
      t.status = status;
      taskProvider.update(t);

      if (_reminderEnabled) {
        final reminderType = _reminderType == 'Tekrarlayan'
            ? 'Tekrarlayan:$_repeatPeriod'
            : _reminderType;
        if (_existingReminder != null) {
          _existingReminder!.title = '"${t.title}" görevi için hatırlatıcı';
          _existingReminder!.type = reminderType;
          _existingReminder!.scheduledAt = _reminderDateTime;
          _existingReminder!.profileId = _profileId;
          reminderProvider.update(_existingReminder!);
        } else {
          reminderProvider.add(Reminder(
            id: '',
            title: '"${t.title}" görevi için hatırlatıcı',
            type: reminderType,
            scheduledAt: _reminderDateTime,
            profileId: _profileId,
            createdAt: DateTime.now(),
            snoozeMinutes: 30,
            taskId: t.id,
          ));
        }
      } else if (_existingReminder != null) {
        reminderProvider.delete(_existingReminder!.id);
      }
    } else {
      final newTask = Task(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        status: status,
        profileId: _profileId,
        dueDate: _dueDate,
        startDate: _startDate,
        createdAt: DateTime.now(),
        completionPercent: _completion,
      );
      await taskProvider.add(newTask);

      if (_reminderEnabled) {
        reminderProvider.add(Reminder(
          id: '',
          title: '"${_titleController.text.trim()}" görevi için hatırlatıcı',
          type: _reminderType == 'Tekrarlayan'
              ? 'Tekrarlayan:$_repeatPeriod'
              : _reminderType,
          scheduledAt: _reminderDateTime,
          profileId: _profileId,
          createdAt: DateTime.now(),
          snoozeMinutes: 30,
          taskId: newTask.id,
        ));
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileProvider>().all;
    final isEdit = widget.task != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Görevi Düzenle' : 'Yeni Görev'),
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
              _buildLabel('Görev Başlığı'),
              TextField(
                controller: _titleController,
                decoration:
                    const InputDecoration(hintText: 'Görev başlığı yazın...'),
                textCapitalization: TextCapitalization.sentences,
                autofocus: !isEdit,
              ),
              const SizedBox(height: 12),
              _buildLabel('Açıklama (opsiyonel)'),
              TextField(
                controller: _descController,
                decoration:
                    const InputDecoration(hintText: 'Açıklama ekleyin...'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Öncelik'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  final color = p == 'Kritik'
                      ? AppColors.dangerBg
                      : p == 'Yüksek'
                          ? AppColors.warnBg
                          : p == 'Orta'
                              ? AppColors.brandLight
                              : AppColors.successBg;
                  final textColor = p == 'Kritik'
                      ? AppColors.dangerText
                      : p == 'Yüksek'
                          ? AppColors.warnText
                          : p == 'Orta'
                              ? AppColors.brandMid
                              : AppColors.successText;
                  return GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? textColor : AppColors.divider,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(p,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? textColor
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Durum'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statuses.map((s) {
                  final isSelected = _status == s;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
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
                      child: Text(s,
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
              Row(
                children: profiles.map((p) {
                  final isSelected = _profileId == p.id;
                  return GestureDetector(
                    onTap: () => setState(() => _profileId = p.id),
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
                      child: Text(p.name,
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Sürekli Görev'),
                        const SizedBox(height: 2),
                        Text(
                          _isContinuous
                              ? 'Bitiş tarihi yok, sürekli takip edilecek'
                              : 'Belirli bir bitiş tarihi var',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isContinuous,
                    onChanged: (v) => setState(() {
                      _isContinuous = v;
                      if (v) _dueDate = null;
                    }),
                    activeThumbColor: AppColors.brand,
                  ),
                ],
              ),
              if (!_isContinuous) ...[
                const SizedBox(height: 12),
                _buildLabel('Başlangıç Tarihi (opsiyonel)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickStartDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _startDate != null
                          ? AppColors.brandLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _startDate != null
                            ? AppColors.brandBorder
                            : AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: _startDate != null
                                ? AppColors.brandMid
                                : AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _startDate != null
                              ? '${_startDate!.day.toString().padLeft(2, '0')}.${_startDate!.month.toString().padLeft(2, '0')}.${_startDate!.year}'
                              : 'Tarih seç',
                          style: TextStyle(
                            fontSize: 14,
                            color: _startDate != null
                                ? AppColors.brandMid
                                : AppColors.textSecondary,
                            fontWeight: _startDate != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (_startDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _startDate = null),
                            child: const Icon(Icons.close,
                                size: 16, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLabel('Bitiş Tarihi'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _dueDate != null
                          ? AppColors.brandLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _dueDate != null
                            ? AppColors.brandBorder
                            : AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: _dueDate != null
                                ? AppColors.brandMid
                                : AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate != null
                              ? '${_dueDate!.day.toString().padLeft(2, '0')}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.year}'
                              : 'Tarih seç',
                          style: TextStyle(
                            fontSize: 14,
                            color: _dueDate != null
                                ? AppColors.brandMid
                                : AppColors.textSecondary,
                            fontWeight: _dueDate != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: const Icon(Icons.close,
                                size: 16, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Hatırlatıcı Ekle'),
                        const SizedBox(height: 2),
                        Text(
                          _reminderEnabled
                              ? 'Seçilen tarih ve saatte hatırlatılacak'
                              : 'Hatırlatıcı yok',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                    activeThumbColor: AppColors.brand,
                  ),
                ],
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 12),
                _buildLabel('Hatırlatıcı Türü'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _reminderTypes.map((t) {
                    final isSel = _reminderType == t;
                    return GestureDetector(
                      onTap: () => setState(() => _reminderType = t),
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
                              fontWeight: isSel
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                if (_reminderType == 'Tekrarlayan') ...[
                  const SizedBox(height: 12),
                  _buildLabel('Tekrar Sıklığı'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _repeatPeriods.map((p) {
                      final isSel = _repeatPeriod == p;
                      return GestureDetector(
                        onTap: () => setState(() => _repeatPeriod = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.brandLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.brandMid
                                  : AppColors.divider,
                              width: isSel ? 1.5 : 0.5,
                            ),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSel
                                    ? AppColors.brandMid
                                    : AppColors.textSecondary,
                                fontWeight: isSel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                _buildLabel('Hatırlatma Tarihi & Saati'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickReminderDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.brandBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.brandMid),
                        const SizedBox(width: 10),
                        Text(
                          '${_reminderDateTime.day.toString().padLeft(2, '0')}.${_reminderDateTime.month.toString().padLeft(2, '0')}.${_reminderDateTime.year}  ${_reminderDateTime.hour.toString().padLeft(2, '0')}:${_reminderDateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.brandMid,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
            if (isEdit) ...[
              const SizedBox(height: 12),
              _buildCard(children: [
                _buildLabel('Tamamlanma: %$_completion'),
                Slider(
                  value: _completion.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  activeColor: AppColors.brandMid,
                  onChanged: (v) => setState(() => _completion = v.round()),
                ),
              ]),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Değişiklikleri Kaydet' : 'Görevi Ekle'),
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
