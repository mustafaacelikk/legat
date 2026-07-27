import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

class ConvertToTaskScreen extends StatefulWidget {
  final Note note;
  const ConvertToTaskScreen({super.key, required this.note});

  @override
  State<ConvertToTaskScreen> createState() => _ConvertToTaskScreenState();
}

class _ConvertToTaskScreenState extends State<ConvertToTaskScreen> {
  late String _title;
  String _priority = 'Orta';
  String _status = 'Planlı';
  late String _profileId;
  DateTime? _dueDate;
  bool _reminderEnabled = false;
  String _reminderPeriod = 'Günlük';

  final _priorities = ['Kritik', 'Yüksek', 'Orta', 'Düşük'];
  final _statuses = ['Yapılacak', 'Planlı', 'Devam Ediyor'];
  final _reminderPeriods = ['Günlük', 'Haftalık', 'Aylık'];

  @override
  void initState() {
    super.initState();
    _title = widget.note.title.isEmpty
        ? (widget.note.content.length > 50
            ? widget.note.content.substring(0, 50)
            : widget.note.content)
        : widget.note.title;
    _profileId = widget.note.profileId;
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 10, 12, 31),
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (!mounted) return;
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final taskProvider = context.read<TaskProvider>();
    final noteProvider = context.read<NoteProvider>();
    final reminderProvider = context.read<ReminderProvider>();

    final status = _status == 'Yapılacak' ? 'Backlog' : _status;

    taskProvider.add(Task(
      id: '',
      title: _title,
      description: widget.note.content,
      priority: _priority,
      status: status,
      profileId: _profileId,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
      completionPercent: 0,
    ));

    if (_reminderEnabled && _dueDate != null) {
      reminderProvider.add(Reminder(
        id: '',
        title: '"$_title" görevi için hatırlatıcı',
        type: _reminderPeriod,
        scheduledAt: DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          9,
          0,
        ),
        profileId: _profileId,
        createdAt: DateTime.now(),
        snoozeMinutes: 30,
      ));
    }

    widget.note.convertedToTask = true;
    noteProvider.update(widget.note);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Görev oluşturuldu!'),
        backgroundColor: AppColors.brand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileProvider>().all;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Göreve Dönüştür'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Oluştur',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandBorder, width: 0.5),
                ),
                child: Text(_title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.brandMid)),
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? textColor
                                : AppColors.textSecondary,
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
                children: _statuses.map((s) {
                  final isSelected = _status == s;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                            fontSize: 12,
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
              _buildLabel('Bitiş Tarihi'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Hatırlatıcı'),
                        const SizedBox(height: 2),
                        Text(
                          _reminderEnabled
                              ? 'Bitiş tarihi sabahı hatırlatılacak'
                              : 'Manuel takip yapacağım',
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
                _buildLabel('Hatırlatma Sıklığı'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _reminderPeriods.map((period) {
                    final isSelected = _reminderPeriod == period;
                    return GestureDetector(
                      onTap: () => setState(() => _reminderPeriod = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandLight
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandMid
                                : AppColors.divider,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(period,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.brandMid
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Görevi Oluştur'),
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
