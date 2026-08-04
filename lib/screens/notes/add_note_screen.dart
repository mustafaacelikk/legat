import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? note;
  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _profileId = 'personal';
  bool _isVoice = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      final n = widget.note!;
      _titleController.text = n.title;
      _contentController.text = n.content;
      _profileId = n.profileId;
      _isVoice = n.isVoice;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_contentController.text.trim().isEmpty &&
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not içeriği boş olamaz')),
      );
      return;
    }

    final provider = context.read<NoteProvider>();

    if (widget.note != null) {
      final n = widget.note!;
      n.title = _titleController.text.trim();
      n.content = _contentController.text.trim();
      n.profileId = _profileId;
      provider.update(n);
    } else {
      provider.add(Note(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        isVoice: _isVoice,
        profileId: _profileId,
        createdAt: DateTime.now(),
      ));
    }

    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NoteProvider>().delete(widget.note!.id);
              Navigator.pop(context);
            },
            child: const Text('Sil',
                style: TextStyle(color: AppColors.dangerText)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileProvider>().all;
    final isEdit = widget.note != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Notu Düzenle' : 'Yeni Not'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
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
              _buildLabel('Başlık (opsiyonel)'),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Not başlığı...'),
                textCapitalization: TextCapitalization.sentences,
                autofocus: !isEdit,
              ),
              const SizedBox(height: 12),
              _buildLabel('Not İçeriği'),
              TextField(
                controller: _contentController,
                decoration:
                    const InputDecoration(hintText: 'Notunuzu yazın...'),
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
              ),
            ]),
            const SizedBox(height: 12),
            _buildCard(children: [
              _buildLabel('Not Türü'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeChip('Metin', false),
                  const SizedBox(width: 8),
                  _typeChip('Sesli', true),
                  const SizedBox(width: 8),
                  if (_isVoice)
                    const Text(
                      '(Yakında)',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                ],
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
                child: Text(isEdit ? 'Değişiklikleri Kaydet' : 'Notu Kaydet'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, bool isVoiceType) {
    final isSelected = _isVoice == isVoiceType;
    return GestureDetector(
      onTap: () => setState(() => _isVoice = isVoiceType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandMid : AppColors.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVoiceType ? Icons.mic : Icons.notes,
              size: 14,
              color: isSelected ? AppColors.brandMid : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isSelected ? AppColors.brandMid : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
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
