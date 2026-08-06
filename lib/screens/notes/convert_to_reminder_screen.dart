import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

class ConvertToReminderScreen extends StatefulWidget {
  final Note note;
  const ConvertToReminderScreen({super.key, required this.note});

  @override
  State<ConvertToReminderScreen> createState() =>
      _ConvertToReminderScreenState();
}

class _ConvertToReminderScreenState extends State<ConvertToReminderScreen> {
  late final TextEditingController _titleController;
  final _titleFocus = FocusNode();
  late String _profileId;
  String _type = 'Zamanlı';
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  int _snoozeMinutes = 30;

  final _types = ['Zamanlı', 'Tekrarlayan'];
  final _snoozeMins = [15, 30, 60];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.note.title.isEmpty
          ? (widget.note.content.length > 50
              ? widget.note.content.substring(0, 50)
              : widget.note.content)
          : widget.note.title,
    );
    _profileId = widget.note.profileId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
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
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;
    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute,
      );
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık boş olamaz')),
      );
      return;
    }

    final reminderProvider = context.read<ReminderProvider>();
    final noteProvider = context.read<NoteProvider>();

    final trimmedTitle = _titleController.text.trim();

    reminderProvider.add(Reminder(
      id: '',
      title: trimmedTitle,
      type: _type,
      scheduledAt: _scheduledAt,
      profileId: _profileId,
      createdAt: DateTime.now(),
      snoozeMinutes: _snoozeMinutes,
    ));

    widget.note.convertedToTask = true;
    noteProvider.update(widget.note);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hatırlatıcı oluşturuldu!'),
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
        title: const Text('Hatırlatıcıya Dönüştür'),
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
              _buildLabel('Hatırlatıcı Başlığı'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandMid),
                decoration: InputDecoration(
                  hintText: 'Başlık girin',
                  filled: true,
                  fillColor: AppColors.brandLight,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.brandBorder, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.brandBorder, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.brandMid, width: 1.5),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Tür'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final isSelected = _type == t;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.brand : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(t,
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
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Tarih & Saat'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateTime,
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
                          color: isSelected ? AppColors.brand : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text('$m dk',
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
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Profil'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: profiles.map((p) {
                  final isSelected = _profileId == p.id;
                  return GestureDetector(
                    onTap: () => setState(() => _profileId = p.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.brand : AppColors.divider,
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
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Hatırlatıcı Oluştur'),
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
