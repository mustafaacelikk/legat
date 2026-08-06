import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
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
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();
  String _profileId = 'personal';
  bool _dirty = false;

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _audioPath;
  int _audioDurationSeconds = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordElapsedSeconds = 0;
  Duration _playbackPosition = Duration.zero;
  Timer? _recordTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  static const _maxRecordSeconds = 300;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      final n = widget.note!;
      _titleController.text = n.title;
      _contentController.text = n.content;
      _profileId = n.profileId;
      _audioPath = n.audioPath;
      _audioDurationSeconds = n.audioDurationSeconds;
    }

    _titleController.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    _contentController.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _playbackPosition = pos);
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _recordTimer?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni gerekli')),
        );
      }
      return;
    }

    if (_audioPath != null) {
      final oldFile = File(_audioPath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final newPath =
        '${dir.path}/note_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        numChannels: 1,
      ),
      path: newPath,
    );

    setState(() {
      _isRecording = true;
      _recordElapsedSeconds = 0;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordElapsedSeconds++);
      if (_recordElapsedSeconds >= _maxRecordSeconds) {
        _stopRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('5 dakikalık süre doldu, kayıt otomatik durduruldu')),
          );
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
      _audioDurationSeconds = _recordElapsedSeconds;
      _dirty = true;
    });
  }

  Future<void> _deleteAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _audioPath = null;
      _audioDurationSeconds = 0;
      _isPlaying = false;
      _playbackPosition = Duration.zero;
      _dirty = true;
    });
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;
    await _audioPlayer.play(DeviceFileSource(_audioPath!));
    setState(() => _isPlaying = true);
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not başlığı boş olamaz')),
      );
      return;
    }

    final provider = context.read<NoteProvider>();

    if (widget.note != null) {
      final n = widget.note!;
      n.title = _titleController.text.trim();
      n.content = _contentController.text.trim();
      n.profileId = _profileId;
      n.audioPath = _audioPath;
      n.audioDurationSeconds = _audioDurationSeconds;
      n.isVoice = _audioPath != null;
      provider.update(n);
    } else {
      provider.add(Note(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        isVoice: _audioPath != null,
        profileId: _profileId,
        createdAt: DateTime.now(),
        audioPath: _audioPath,
        audioDurationSeconds: _audioDurationSeconds,
      ));
    }

    _dirty = false;
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
            onPressed: () async {
              Navigator.pop(ctx);
              final note = widget.note!;
              if (note.audioPath != null) {
                final file = File(note.audioPath!);
                if (await file.exists()) {
                  await file.delete();
                }
              }
              if (!mounted) return;
              context.read<NoteProvider>().delete(note.id);
              _dirty = false;
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (!_dirty) {
          Navigator.of(context).pop();
          return;
        }
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
                isEdit ? 'Kaydedilmemiş Değişiklikler' : 'Kaydedilmemiş Kayıt'),
            content: Text(isEdit
                ? 'Bu kayıtta değişiklik yaptınız. Değişiklikleri kaydetmek istiyor musunuz?'
                : 'Girdiğiniz bilgiler henüz kaydedilmedi. Kaydetmek istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: Text(isEdit ? 'İptal Et' : 'Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
        if (action == 'save') {
          _save();
        } else if (action == 'discard') {
          _dirty = false;
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                _buildLabel('Başlık'),
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  decoration: const InputDecoration(hintText: 'Başlık'),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: !isEdit,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_contentFocus),
                ),
                const SizedBox(height: 12),
                _buildLabel('Not İçeriği'),
                TextField(
                  controller: _contentController,
                  focusNode: _contentFocus,
                  decoration:
                      const InputDecoration(hintText: 'Notunuzu yazın...'),
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ]),
              const SizedBox(height: 12),
              _buildCard(children: [
                _buildLabel('Sesli Not'),
                const SizedBox(height: 12),
                _buildAudioSection(),
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
                        onTap: () => setState(() {
                          _dirty = true;
                          _profileId = p.id;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.surface,
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
      ),
    );
  }

  Widget _buildAudioSection() {
    if (_isRecording) {
      return Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.dangerText,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatDuration(_recordElapsedSeconds)} / ${_formatDuration(_maxRecordSeconds)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('Durdur'),
          ),
        ],
      );
    }

    if (_audioPath != null) {
      final total = _audioDurationSeconds;
      final elapsed = _playbackPosition.inSeconds.clamp(0, total);
      final progress = total > 0 ? elapsed / total : 0.0;
      return Row(
        children: [
          IconButton(
            onPressed: _isPlaying ? _pauseAudio : _playAudio,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: AppColors.brand,
              size: 36,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    minHeight: 6,
                    backgroundColor: AppColors.brandLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.brand),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(elapsed)} / ${_formatDuration(total)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _deleteAudio,
            icon: const Icon(Icons.delete_outline,
                color: AppColors.dangerText, size: 22),
          ),
        ],
      );
    }

    return Center(
      child: OutlinedButton.icon(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic),
        label: const Text('Sesli Not Kaydet'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.brandMid),
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
