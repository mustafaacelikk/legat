// lib/screens/notes/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/note_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/note_model.dart';
import 'add_note_screen.dart';
import 'convert_to_task_screen.dart';
import 'convert_to_reminder_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _filter = 'Tümü';
  final _filters = ['Tümü', 'Metin', 'Sesli'];
  String _searchQuery = '';
  String _sortType = 'Tarih'; // 'Tarih' | 'Alfabetik'

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final activeId = profileProvider.activeProfileId;

    List<Note> notes = noteProvider.byProfile(activeId);

    if (_filter == 'Metin') {
      notes = notes.where((n) => !n.isVoice).toList();
    } else if (_filter == 'Sesli') {
      notes = notes.where((n) => n.isVoice).toList();
    } else if (_filter == 'Göreve Dönüştür') {
      notes = notes.where((n) => !n.convertedToTask).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      notes = notes.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q)).toList();
    }

    if (_sortType == 'Alfabetik') {
      notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, profileProvider, activeId),
            _buildFilters(),
            if (_searchQuery.isNotEmpty)
              Container(
                width: double.infinity,
                color: AppColors.brandLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 14, color: AppColors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('"$_searchQuery" için sonuçlar',
                          style: const TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _searchQuery = ''),
                      child: const Icon(Icons.close, size: 16, color: AppColors.brand),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: notes.isEmpty ? _buildEmpty() : _buildList(notes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ProfileProvider pp, String activeId) {
    // Sabit profiller önce, sonra özel profiller ekleme sırasına göre
    final fixedProfiles =
        pp.all.where((p) => p.id == 'personal' || p.id == 'work').toList();
    final customProfiles =
        pp.all.where((p) => p.id != 'personal' && p.id != 'work').toList();
    final orderedProfiles = [...fixedProfiles, ...customProfiles];
    return Container(
      color: AppColors.brand,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icon/icon_white.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text('Notlar',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showSearchSort(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.manage_search, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelp(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('i',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dinamik profil sekmeleri — yeni profil eklenince otomatik görünür
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _profileTab('Tümü', 'all', activeId, pp),
                ...orderedProfiles.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _profileTab(p.name, p.id, activeId, pp),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTab(
      String label, String id, String activeId, ProfileProvider pp) {
    final isActive = activeId == id;
    return GestureDetector(
      onTap: () => pp.setActive(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: isActive ? AppColors.brand : Colors.white,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final isActive = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.brand : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.brand : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Text(f,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            isActive ? FontWeight.w500 : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      itemCount: notes.length,
      itemBuilder: (context, index) => _buildNoteCard(notes[index]),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Dismissible(
      key: Key(note.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.dangerText,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editNote(note);
          return false;
        } else {
          return await _confirmDelete(note);
        }
      },
      child: GestureDetector(
        onLongPress: () => _showNoteMenu(context, note),
        onDoubleTap: () => _editNote(note),
        child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: note.convertedToTask
              ? const Color(0xFFE0F2F1)
              : const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: note.convertedToTask
                ? const Color(0xFF00695C).withValues(alpha: 0.3)
                : const Color(0xFF6B21A8).withValues(alpha: 0.2),
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: note.convertedToTask
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: note.convertedToTask
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: note.isVoice ? AppColors.brand : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            note.isVoice ? AppColors.brand : AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      note.isVoice ? 'Sesli' : 'Metin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: note.isVoice
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat('d MMM y, HH:mm', 'tr_TR')
                        .format(note.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (!note.convertedToTask)
                    GestureDetector(
                      onTap: () => _showConvertMenu(context, note),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.brandBorder, width: 0.5),
                        ),
                        child: const Text('→ Dönüştür',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.brand,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _showNoteMenu(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(note.title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.brand),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddNoteScreen(note: note)));
              },
            ),
            if (!note.convertedToTask) ...[
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppColors.brandMid),
                title: const Text('Dönüştür'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showConvertMenu(context, note);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.dangerText),
              title: const Text('Sil', style: TextStyle(color: AppColors.dangerText)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Note note) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notu Sil'),
        content: Text('"${note.title}" silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.dangerText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      context.read<NoteProvider>().delete(note.id);
    }
    return result ?? false;
  }

  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddNoteScreen(note: note)),
    );
  }

  void _convertToTask(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConvertToTaskScreen(note: note)),
    );
  }

  void _showConvertMenu(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Noya Dönüştür',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.successText, size: 20),
              ),
              title: const Text('Göreve Dönüştür',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Görevler listesine ekle',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _convertToTask(note);
              },
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warnBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.warnText, size: 20),
              ),
              title: const Text('Hatırlatıcıya Dönüştür',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Hatırlatıcılar listesine ekle',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConvertToReminderScreen(note: note),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.grayBorder),
              const SizedBox(height: 16),
              Text('"$_searchQuery" için sonuç bulunamadı',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('Farklı bir kelime ile aramayı dene',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(Icons.notes_outlined,
                size: 64, color: AppColors.grayBorder),
            const SizedBox(height: 16),
            Text(
              _filter == 'Sesli' ? 'Sesli not yok' : 'Henüz not eklenmedi',
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text('+ butonuyla not ekleyebilirsiniz',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showSearchSort(BuildContext context) {
    final controller = TextEditingController(text: _searchQuery);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.grayBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Ara & Sırala',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Notlarda ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 20),
              const Text('Sıralama',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Tarih', 'Alfabetik'].map((s) {
                  final isSel = _sortType == s;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _sortType = s);
                      setSheetState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? AppColors.brand : AppColors.divider,
                            width: 0.5),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 13,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight:
                                  isSel ? FontWeight.w500 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grayBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Notlar — Nasıl Kullanılır?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
                '• Sağa kaydır: düzenle · Sola kaydır: sil\n• Basılı tut: hızlı menü (düzenle/dönüştür/sil)\n• Çift dokun: düzenleme ekranını aç\n• "→ Dönüştür": notu göreve veya hatırlatıcıya çevir\n• Arama ikonu: başlık ve içerikte ara, sıralama seç\n• Alttaki + butonu: hızlı görev/not/hatırlatıcı ekle',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
